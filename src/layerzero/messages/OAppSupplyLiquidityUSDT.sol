// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OAppOptionsType3} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {ILPRouter} from "../../interfaces/ILPRouter.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title OAppSupplyLiquidityUSDT
 * @author Senja Protocol
 * @notice Omnichain Application for cross-chain liquidity supply using USDT
 * @dev Coordinates cross-chain token transfer and liquidity supply operations
 * Users send tokens from source chain to supply liquidity on destination chain
 */
contract OAppSupplyLiquidityUSDT is OApp, OAppOptionsType3 {
    using OptionsBuilder for bytes;
    using SafeERC20 for IERC20;

    /// @notice Error thrown when user has insufficient balance
    error InsufficientBalance();
    /// @notice Error thrown when insufficient native fee is provided
    error InsufficientNativeFee();
    /// @notice Error thrown when caller is not an authorized OApp
    error OnlyOApp();

    /// @notice Last message received from cross-chain
    bytes public lastMessage;
    /// @notice Factory contract address
    address public factory;
    /// @notice OFT adapter contract address
    address public oftaddress;

    /// @notice Message type constant for sending
    uint16 public constant SEND = 1;

    /// @notice Emitted when liquidity message is received on destination
    /// @param lendingPool The lending pool address
    /// @param user The user address
    /// @param token The token address
    /// @param amount The liquidity amount
    event SendLiquidityFromDst(address lendingPool, address user, address token, uint256 amount);
    
    /// @notice Emitted when liquidity supply is initiated from source
    /// @param lendingPool The lending pool address
    /// @param user The user address
    /// @param token The token address
    /// @param amount The liquidity amount
    event SendLiquidityFromSrc(address lendingPool, address user, address token, uint256 amount);
    
    /// @notice Emitted when liquidity supply is executed
    /// @param lendingPool The lending pool address
    /// @param token The token address
    /// @param user The user address
    /// @param amount The amount supplied
    event ExecuteLiquidity(address lendingPool, address token, address user, uint256 amount);

    /// @notice Mapping of user to their received token amount
    mapping(address => uint256) public userAmount;

    /**
     * @notice Constructor to initialize the OApp
     * @param _endpoint The LayerZero endpoint address
     * @param _owner The owner of the contract
     */
    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) Ownable(_owner) {}

    /**
     * @notice Quotes the fee for sending liquidity supply message
     * @param _dstEid The destination endpoint ID
     * @param _lendingPool The lending pool address
     * @param _user The user address
     * @param _token The token address
     * @param _amount The amount to supply
     * @param _options Execution options
     * @param _payInLzToken Whether to pay in LZ token
     * @return fee The messaging fee
     */
    function quoteSendString(
        uint32 _dstEid,
        address _lendingPool,
        address _user,
        address _token,
        uint256 _amount,
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(_lendingPool, _user, _token, _amount);
        fee = _quote(_dstEid, _message, combineOptions(_dstEid, SEND, _options), _payInLzToken);
    }

    /**
     * @notice Sends cross-chain message to supply liquidity
     * @param _dstEid The destination endpoint ID
     * @param _lendingPoolDst The destination lending pool address
     * @param _user The user address
     * @param _tokendst The destination token address
     * @param _amount The amount to supply
     * @param _oappFee The OApp messaging fee
     * @param _options Execution options
     * @dev Sends OApp message with liquidity supply instructions
     */
    function sendString(
        uint32 _dstEid,
        address _lendingPoolDst,
        address _user,
        address _tokendst,
        uint256 _amount,
        uint256 _oappFee,
        bytes calldata _options
    ) external payable {
        bytes memory lzOptions = combineOptions(_dstEid, SEND, _options);
        bytes memory message = abi.encode(_lendingPoolDst, _user, _tokendst, _amount);
        _lzSend(_dstEid, message, lzOptions, MessagingFee(_oappFee, 0), payable(_user));
        emit SendLiquidityFromSrc(_lendingPoolDst, _user, _tokendst, _amount);
    }

    function _lzReceive(Origin calldata, bytes32, bytes calldata _message, address, bytes calldata) internal override {
        (address _lendingPool, address _user, address _token, uint256 _amount) =
            abi.decode(_message, (address, address, address, uint256));

        userAmount[_user] += _amount;
        lastMessage = _message;
        emit SendLiquidityFromDst(_lendingPool, _user, _token, _amount);
    }

    /**
     * @notice Executes the liquidity supply on the destination chain
     * @param _lendingPool The lending pool address
     * @param _user The user address
     * @param _amount The amount to supply as liquidity
     * @dev Can only execute if user has sufficient received tokens
     */
    function execute(address _lendingPool, address _user, uint256 _amount) public {
        if (_amount > userAmount[_user]) revert InsufficientBalance(); // TODO: passing byte code
        userAmount[_user] -= _amount;
        address borrowToken = _borrowToken(_lendingPool);
        IERC20(borrowToken).approve(_lendingPool, _amount);
        ILendingPool(_lendingPool).supplyLiquidity(_user, _amount);
        emit ExecuteLiquidity(_lendingPool, borrowToken, _user, _amount);
    }

    /**
     * @notice Sets the factory address
     * @param _factory The factory address
     * @dev Only callable by owner
     */
    function setFactory(address _factory) public onlyOwner {
        factory = _factory;
    }

    /**
     * @notice Sets the OFT adapter address
     * @param _oftaddress The OFT adapter address
     * @dev Only callable by owner. Used on both source and destination chains
     */
    function setOFTaddress(address _oftaddress) public onlyOwner {
        oftaddress = _oftaddress;
    }

    /**
     * @notice Gets the borrow token address from lending pool
     * @param _lendingPool The lending pool address
     * @return The borrow token address
     */
    function _borrowToken(address _lendingPool) internal view returns (address) {
        return ILPRouter(ILendingPool(_lendingPool).router()).borrowToken();
    }

    /**
     * @notice Converts address to bytes32
     * @param _address The address to convert
     * @return The bytes32 representation
     */
    function addressToBytes32(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }
}
