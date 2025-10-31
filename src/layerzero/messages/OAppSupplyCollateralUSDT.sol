// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OAppOptionsType3} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OFTadapter} from "../OFTAdapter.sol";
import {SendParam} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {ILPRouter} from "../../interfaces/ILPRouter.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title OAppSupplyCollateralUSDT
 * @author Senja Protocol
 * @notice Omnichain Application for cross-chain collateral supply using USDT
 * @dev Coordinates cross-chain token transfer and collateral supply operations
 * Users send tokens from source chain to supply as collateral on destination chain
 */
contract OAppSupplyCollateralUSDT is OApp, OAppOptionsType3 {
    using OptionsBuilder for bytes;
    using SafeERC20 for IERC20;

    /// @notice Error thrown when user has insufficient balance
    error InsufficientBalance();
    /// @notice Error thrown when insufficient native fee is provided
    error InsufficientNativeFee();

    /// @notice Last message received from cross-chain
    bytes public lastMessage;
    /// @notice Factory contract address
    address public factory;
    /// @notice OFT adapter contract address
    address public oftaddress;

    /// @notice Message type constant for sending
    uint16 public constant SEND = 1;

    /// @notice Emitted when collateral message is received on destination
    /// @param lendingPool The lending pool address
    /// @param user The user address
    /// @param token The token address
    /// @param amount The collateral amount
    event SendCollateralFromDst(address lendingPool, address user, address token, uint256 amount);
    
    /// @notice Emitted when collateral supply is initiated from source
    /// @param lendingPool The lending pool address
    /// @param user The user address
    /// @param token The token address
    /// @param amount The collateral amount
    event SendCollateralFromSrc(address lendingPool, address user, address token, uint256 amount);
    
    /// @notice Emitted when collateral supply is executed
    /// @param lendingPool The lending pool address
    /// @param token The token address
    /// @param user The user address
    /// @param amount The amount supplied
    event ExecuteCollateral(address lendingPool, address token, address user, uint256 amount);

    /// @notice Mapping of user to their received token amount
    mapping(address => uint256) public userAmount;

    /**
     * @notice Constructor to initialize the OApp
     * @param _endpoint The LayerZero endpoint address
     * @param _owner The owner of the contract
     */
    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) Ownable(_owner) {}

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

    function sendString(
        uint32 _dstEid,
        address _lendingPool,
        address _user,
        address _tokendst,
        address _oappaddressdst,
        uint256 _amount,
        uint256 _slippageTolerance,
        bytes calldata _options
    ) external payable {
        uint256 oftNativeFee = _quoteOftNativeFee(_dstEid, _oappaddressdst, _amount, _slippageTolerance);
        uint256 lzNativeFee = _quoteLzNativeFee(_dstEid, _lendingPool, _user, _tokendst, _amount, _options);

        if (msg.value < oftNativeFee + lzNativeFee) revert InsufficientNativeFee();

        _performOftSend(_dstEid, _oappaddressdst, _user, _amount, _slippageTolerance, oftNativeFee);
        _performLzSend(_dstEid, _lendingPool, _user, _tokendst, _amount, _options, lzNativeFee);
        emit SendCollateralFromSrc(_lendingPool, _user, _tokendst, _amount);
    }

    function _lzReceive(Origin calldata, bytes32, bytes calldata _message, address, bytes calldata) internal override {
        (address _lendingPool, address _user, address _token, uint256 _amount) =
            abi.decode(_message, (address, address, address, uint256));

        userAmount[_user] += _amount;
        lastMessage = _message;
        emit SendCollateralFromDst(_lendingPool, _user, _token, _amount);
    }

    /**
     * @notice Executes the collateral supply on the destination chain
     * @param _lendingPool The lending pool address
     * @param _user The user address
     * @param _amount The amount to supply as collateral
     * @dev Can only execute if user has sufficient received tokens
     */
    function execute(address _lendingPool, address _user, uint256 _amount) public {
        if (_amount > userAmount[_user]) revert InsufficientBalance();
        userAmount[_user] -= _amount;
        address collateralToken = _collateralToken(_lendingPool);
        IERC20(collateralToken).approve(_lendingPool, _amount);
        ILendingPool(_lendingPool).supplyCollateral(_amount, _user);
        emit ExecuteCollateral(_lendingPool, collateralToken, _user, _amount);
    }

    function _quoteOftNativeFee(uint32 _dstEid, address _oappaddressdst, uint256 _amount, uint256 _slippageTolerance)
        internal
        view
        returns (uint256)
    {
        OFTadapter oft = OFTadapter(oftaddress);
        bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(65000, 0);
        SendParam memory sendParam = SendParam({
            dstEid: _dstEid,
            to: addressToBytes32(_oappaddressdst),
            amountLD: _amount,
            minAmountLD: _amount * (100 - _slippageTolerance) / 100,
            extraOptions: extraOptions,
            composeMsg: "",
            oftCmd: ""
        });
        return oft.quoteSend(sendParam, false).nativeFee;
    }

    function _quoteLzNativeFee(
        uint32 _dstEid,
        address _lendingPool,
        address _user,
        address _tokendst,
        uint256 _amount,
        bytes calldata _options
    ) internal view returns (uint256) {
        bytes memory lzOptions = combineOptions(_dstEid, SEND, _options);
        bytes memory payload = abi.encode(_lendingPool, _user, _tokendst, _amount);
        return _quote(_dstEid, payload, lzOptions, false).nativeFee;
    }

    function _performOftSend(
        uint32 _dstEid,
        address _oappaddressdst,
        address _user,
        uint256 _amount,
        uint256 _slippageTolerance,
        uint256 _oftNativeFee
    ) internal {
        OFTadapter oft = OFTadapter(oftaddress);
        bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(65000, 0);
        SendParam memory sendParam = SendParam({
            dstEid: _dstEid,
            to: addressToBytes32(_oappaddressdst),
            amountLD: _amount,
            minAmountLD: _amount * (100 - _slippageTolerance) / 100,
            extraOptions: extraOptions,
            composeMsg: "",
            oftCmd: ""
        });
        IERC20(oft.tokenOFT()).safeTransferFrom(_user, address(this), _amount);
        IERC20(oft.tokenOFT()).approve(oftaddress, _amount);
        oft.send{value: _oftNativeFee}(sendParam, MessagingFee(_oftNativeFee, 0), _user);
    }

    function _performLzSend(
        uint32 _dstEid,
        address _lendingPool,
        address _user,
        address _tokendst,
        uint256 _amount,
        bytes calldata _options,
        uint256 _lzNativeFee
    ) internal {
        bytes memory lzOptions = combineOptions(_dstEid, SEND, _options);
        bytes memory payload = abi.encode(_lendingPool, _user, _tokendst, _amount);
        _lzSend(_dstEid, payload, lzOptions, MessagingFee(_lzNativeFee, 0), payable(_user));
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
     * @notice Gets the collateral token address from lending pool
     * @param _lendingPool The lending pool address
     * @return The collateral token address
     */
    function _collateralToken(address _lendingPool) internal view returns (address) {
        return ILPRouter(ILendingPool(_lendingPool).router()).collateralToken();
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
