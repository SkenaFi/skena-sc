// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {OFTAdapter} from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import {OAppSupplyLiquidityUSDT} from "./OAppSupplyLiquidityUSDT.sol";
import {SendParam} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title OAppAdapter
 * @author Senja Protocol
 * @notice Adapter for coordinating cross-chain token transfers and liquidity operations
 * @dev Combines OFT token bridging with OApp messaging for liquidity supply operations
 */
contract OAppAdapter is ReentrancyGuard {
    /// @notice Emitted when tokens are bridged cross-chain with OApp message
    /// @param _oapp The OApp contract address
    /// @param _oft The OFT adapter address
    /// @param _lendingPoolDst The destination lending pool address
    /// @param _tokenSrc The source token address
    /// @param _tokenDst The destination token address
    /// @param _toAddress The recipient address
    /// @param _dstEid The destination endpoint ID
    /// @param _amount The amount bridged
    /// @param _oftFee The OFT fee paid
    /// @param _oappFee The OApp fee paid
    event sendBridgeOApp(
        address _oapp,
        address _oft,
        address _lendingPoolDst,
        address _tokenSrc,
        address _tokenDst,
        address _toAddress,
        uint32 _dstEid,
        uint256 _amount,
        uint256 _oftFee,
        uint256 _oappFee
    );

    using SafeERC20 for IERC20;
    using OptionsBuilder for bytes;

    /**
     * @notice Sends tokens cross-chain and supplies liquidity on destination
     * @param _oapp The OApp contract address for messaging
     * @param _oft The OFT adapter address for token bridging
     * @param _lendingPoolDst The destination lending pool address
     * @param _tokenSrc The source token address
     * @param _tokenDst The destination token address
     * @param _toAddress The recipient address
     * @param _dstEid The destination endpoint ID
     * @param _amount The amount to bridge
     * @param _oftFee The OFT fee to pay
     * @param _oappFee The OApp messaging fee to pay
     * @dev Coordinates both token transfer via OFT and message via OApp
     */
    function sendBridge(
        address _oapp,
        address _oft,
        address _lendingPoolDst,
        address _tokenSrc,
        address _tokenDst,
        address _toAddress,
        uint32 _dstEid,
        uint256 _amount,
        uint256 _oftFee,
        uint256 _oappFee
    ) external payable nonReentrant {
        (SendParam memory sendParam, MessagingFee memory fee) = _utils(_dstEid, _toAddress, _amount, _oft);
        OFTAdapter(_oft).send{value: _oftFee}(sendParam, fee, _toAddress);
        OAppSupplyLiquidityUSDT(_oapp).sendString{value: _oappFee}(
            _dstEid, _lendingPoolDst, _toAddress, _tokenDst, _amount, _oappFee, ""
        );
        emit sendBridgeOApp(
            _oapp, _oft, _lendingPoolDst, _tokenSrc, _tokenDst, _toAddress, _dstEid, _amount, _oftFee, _oappFee
        );
    }

    /**
     * @notice Internal utility function to prepare OFT send parameters
     * @param _dstEid The destination endpoint ID
     * @param _toAddress The recipient address
     * @param _amount The amount to send
     * @param _oft The OFT adapter address
     * @return sendParam The prepared send parameters
     * @return fee The messaging fee quote
     * @dev Builds the SendParam struct and gets fee quote from OFT
     */
    function _utils(uint32 _dstEid, address _toAddress, uint256 _amount, address _oft)
        internal
        view
        returns (SendParam memory sendParam, MessagingFee memory fee)
    {
        bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(65000, 0);

        sendParam = SendParam({
            dstEid: _dstEid,
            to: _addressToBytes32(_toAddress),
            amountLD: _amount,
            minAmountLD: _amount,
            extraOptions: extraOptions,
            composeMsg: "",
            oftCmd: ""
        });

        fee = OFTAdapter(_oft).quoteSend(sendParam, false);
    }

    /**
     * @notice Converts an address to bytes32 format
     * @param _addr The address to convert
     * @return The bytes32 representation of the address
     * @dev Used for LayerZero message encoding
     */
    function _addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
