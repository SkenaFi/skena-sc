// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OFTAdapter} from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import {IElevatedMintableBurnable} from "../interfaces/IElevatedMintableBurnable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title OFTWETHadapter
 * @author Senja Protocol
 * @notice Omnichain Fungible Token adapter for WETH cross-chain transfers
 * @dev Extends OFTAdapter for WETH with 18 decimals
 * Handles both native chain (8453/Base) transfers and cross-chain minting/burning
 */
contract OFTWETHadapter is OFTAdapter, ReentrancyGuard {
    /// @notice Error thrown when contract has insufficient balance
    error InsufficientBalance();

    /// @notice Emitted when tokens are credited to a recipient
    /// @param to The recipient address
    /// @param amount The amount credited
    event Credit(address to, uint256 amount);
    
    /// @notice Emitted when tokens are debited from a sender
    /// @param from The sender address
    /// @param amount The amount debited
    event Debit(address from, uint256 amount);

    /// @notice Address of the WETH token
    address public tokenOFT;
    /// @notice Address of the elevated minter/burner contract
    address public elevatedMinterBurner;

    using SafeERC20 for IERC20;

    /**
     * @notice Constructor to initialize the WETH OFT adapter
     * @param _token The address of the WETH token
     * @param _elevatedMinterBurner The address of the minter/burner contract
     * @param _lzEndpoint The LayerZero endpoint address
     * @param _owner The owner of the adapter
     */
    constructor(address _token, address _elevatedMinterBurner, address _lzEndpoint, address _owner)
        OFTAdapter(_token, _lzEndpoint, _owner)
        Ownable(_owner)
    {
        tokenOFT = _token;
        elevatedMinterBurner = _elevatedMinterBurner;
    }

    /**
     * @notice Returns the shared decimals for cross-chain transfers
     * @return The number of shared decimals (18 for WETH)
     * @dev Overrides OFTAdapter to use WETH's 18 decimals
     */
    function sharedDecimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @notice Credits tokens to a recipient on the destination chain
     * @param _to The recipient address
     * @param _amountLD The amount in local decimals
     * @return amountReceivedLD The actual amount received
     * @dev On Base (8453), transfers existing tokens; on other chains, mints new tokens
     */
    function _credit(address _to, uint256 _amountLD, uint32)
        internal
        virtual
        override
        returns (uint256 amountReceivedLD)
    {
        if (_to == address(0x0)) _to = address(0xdead);
        if (block.chainid == 8453) {
            if (IERC20(tokenOFT).balanceOf(address(this)) < _amountLD) revert InsufficientBalance();
            IERC20(tokenOFT).safeTransfer(_to, _amountLD);
        } else {
            IElevatedMintableBurnable(elevatedMinterBurner).mint(_to, _amountLD);
        }
        emit Credit(_to, _amountLD);
        return _amountLD;
    }

    /**
     * @notice Debits tokens from the sender on the source chain
     * @param _from The sender address
     * @param _amountLD The amount in local decimals
     * @param _minAmountLD The minimum amount to send
     * @param _dstEid The destination endpoint ID
     * @return amountSentLD The amount sent
     * @return amountReceivedLD The amount that will be received
     * @dev On Base (8453), locks tokens; on other chains, burns tokens
     */
    function _debit(address _from, uint256 _amountLD, uint256 _minAmountLD, uint32 _dstEid)
        internal
        virtual
        override
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);
        if (block.chainid == 8453) {
            IERC20(tokenOFT).safeTransferFrom(_from, address(this), amountSentLD);
        } else {
            IERC20(tokenOFT).safeTransferFrom(_from, address(this), amountSentLD);
            IERC20(tokenOFT).approve(elevatedMinterBurner, amountSentLD);
            IElevatedMintableBurnable(elevatedMinterBurner).burn(_from, amountSentLD);
        }
        emit Debit(_from, _amountLD);
    }

    /**
     * @notice Sets the elevated minter/burner contract address
     * @param _elevatedMinterBurner The new elevated minter/burner address
     * @dev Only callable by owner
     */
    function setElevatedMinterBurner(address _elevatedMinterBurner) external onlyOwner {
        elevatedMinterBurner = _elevatedMinterBurner;
    }
}
