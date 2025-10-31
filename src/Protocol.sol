// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {ISwap} from "./interfaces/ISwap.sol";

/**
 * @title Protocol
 * @dev Protocol contract for managing protocol fees and withdrawals
 * @notice This contract handles protocol-level operations including fee collection and withdrawals
 * @author Senja Team
 * @custom:version 1.0.0
 */
contract Protocol is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // WETH contract address on Base mainnet
    address public constant WETH = 0x4200000000000000000000000000000000000006;

    // UniSwap router address on Base mainnet
    address public constant UNISWAP_ROUTER = 0x2626664c2603336E57B271c5C0b26F421741e481;

    // Buyback configuration
    uint256 public constant PROTOCOL_SHARE = 95; // 95% for protocol (locked)
    uint256 public constant OWNER_SHARE = 5; // 5% for owner
    uint256 public constant PERCENTAGE_DIVISOR = 100;

    // State variables for buyback tracking
    mapping(address => uint256) public protocolLockedBalance; // Token => locked amount for protocol
    mapping(address => uint256) public ownerAvailableBalance; // Token => available amount for owner

    // ============ Errors ============

    /**
     * @dev Error thrown when there are insufficient tokens for withdrawal
     * @param token Address of the token with insufficient balance
     * @param amount Amount that was attempted to withdraw
     */
    error InsufficientBalance(address token, uint256 amount);

    /**
     * @dev Error thrown when swap fails
     * @param tokenIn Address of the input token
     * @param tokenOut Address of the output token
     * @param amountIn Amount of input tokens
     */
    error SwapFailed(address tokenIn, address tokenOut, uint256 amountIn);

    /**
     * @dev Error thrown when insufficient output amount is received
     * @param expectedMinimum Expected minimum output amount
     * @param actualOutput Actual output amount received
     */
    error InsufficientOutputAmount(uint256 expectedMinimum, uint256 actualOutput);

    /**
     * @dev Error thrown when invalid token address is provided
     */
    error InvalidTokenAddress();

    /**
     * @dev Error thrown when amount is zero or invalid
     */
    error InvalidAmount();

    /**
     * @dev Error thrown when deadline has passed
     */
    error DeadlinePassed();

    /**
     * @dev Error thrown when trying to swap WETH for WETH
     */
    error CannotSwapWETHForWETH();

    // ============ Events ============

    /**
     * @dev Emitted when buyback is executed
     * @param tokenIn Address of the input token used for buyback
     * @param totalAmountIn Total amount of input tokens used
     * @param protocolAmount Amount allocated to protocol (locked)
     * @param ownerAmount Amount allocated to owner
     * @param wethReceived Total WETH received from buyback
     */
    event BuybackExecuted(
        address indexed tokenIn,
        uint256 totalAmountIn,
        uint256 protocolAmount,
        uint256 ownerAmount,
        uint256 wethReceived
    );

    /**
     * @dev Constructor for the Protocol contract
     * @notice Initializes the protocol contract with the deployer as owner
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @dev Allows the contract to receive native tokens (BASE) and auto-wraps them to WETH
     * @notice Required for protocol fee collection in native tokens
     */
    receive() external payable {
        if (msg.value > 0) {
            // Always wrap native tokens to WETH for consistent handling
            IWETH(WETH).deposit{value: msg.value}();
        }
    }

    /**
     * @dev Fallback function - rejects calls with data to prevent accidental interactions
     */
    fallback() external {
        revert("Fallback not allowed");
    }

    /**
     * @dev Executes buyback using protocol's accumulated balance
     * @param tokenIn Address of the token to use for buyback
     * @param amountIn Amount of tokens to use for buyback
     * @param amountOutMinimum Minimum amount of WETH to receive (slippage protection)
     * @param fee Fee tier for the swap (0.05% = 500, 0.3% = 3000, 1% = 10000)
     * @param deadline Deadline for the swap transaction
     * @return totalWethReceived Total amount of WETH received from buyback
     * @notice Uses protocol's balance to buy WETH, splits 95% to protocol (locked) and 5% to owner
     * @custom:security Only the owner can execute buyback
     */
    function executeBuyback(address tokenIn, uint256 amountIn, uint256 amountOutMinimum, uint24 fee, uint256 deadline)
        external
        nonReentrant
        returns (uint256 totalWethReceived)
    {
        return _executeBuyback(tokenIn, amountIn, amountOutMinimum, fee, deadline);
    }

    /**
     * @dev Internal function to execute buyback using protocol's accumulated balance
     * @param tokenIn Address of the token to use for buyback
     * @param amountIn Amount of tokens to use for buyback
     * @param amountOutMinimum Minimum amount of WETH to receive (slippage protection)
     * @param fee Fee tier for the swap (0.05% = 500, 0.3% = 3000, 1% = 10000)
     * @param deadline Deadline for the swap transaction
     * @return totalWethReceived Total amount of WETH received from buyback
     * @notice Uses protocol's balance to buy WETH, splits 95% to protocol (locked) and 5% to owner
     */
    function _executeBuyback(address tokenIn, uint256 amountIn, uint256 amountOutMinimum, uint24 fee, uint256 deadline)
        internal
        returns (uint256 totalWethReceived)
    {
        // Validate inputs
        if (tokenIn == address(0)) revert InvalidTokenAddress();
        if (amountIn == 0) revert InvalidAmount();
        if (deadline <= block.timestamp) revert DeadlinePassed();
        if (tokenIn == WETH) revert CannotSwapWETHForWETH();

        // Check if protocol has sufficient balance
        uint256 protocolBalance = IERC20(tokenIn).balanceOf(address(this));
        if (protocolBalance < amountIn) {
            revert InsufficientBalance(tokenIn, amountIn);
        }

        // Calculate shares
        uint256 protocolAmount = (amountIn * PROTOCOL_SHARE) / PERCENTAGE_DIVISOR;
        uint256 ownerAmount = amountIn - protocolAmount; // Remaining amount for owner

        // Approve UniSwap router to spend tokens
        IERC20(tokenIn).approve(UNISWAP_ROUTER, amountIn);

        // Prepare swap parameters for protocol share
        ISwap.ExactInputSingleParams memory params = ISwap.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: WETH,
            fee: fee,
            recipient: address(this), // Send to protocol
            amountIn: protocolAmount,
            amountOutMinimum: (amountOutMinimum * PROTOCOL_SHARE) / PERCENTAGE_DIVISOR,
            sqrtPriceLimitX96: 0 // No price limit
        });

        // Execute swap for protocol share
        uint256 protocolWethReceived;
        try ISwap(UNISWAP_ROUTER).exactInputSingle(params) returns (uint256 _amountOut) {
            protocolWethReceived = _amountOut;
        } catch {
            revert SwapFailed(tokenIn, WETH, protocolAmount);
        }

        // Update protocol locked balance
        protocolLockedBalance[WETH] += protocolWethReceived;

        // If there's an owner amount, execute swap for owner
        uint256 ownerWethReceived = 0;
        if (ownerAmount > 0) {
            // Prepare swap parameters for owner share
            params.amountIn = ownerAmount;
            params.recipient = owner();
            params.amountOutMinimum = (amountOutMinimum * OWNER_SHARE) / PERCENTAGE_DIVISOR;

            try ISwap(UNISWAP_ROUTER).exactInputSingle(params) returns (uint256 _amountOut) {
                ownerWethReceived = _amountOut;
                ownerAvailableBalance[WETH] += ownerWethReceived;
            } catch {
                revert SwapFailed(tokenIn, WETH, ownerAmount);
            }
        }

        totalWethReceived = protocolWethReceived + ownerWethReceived;

        // Emit buyback event
        emit BuybackExecuted(tokenIn, amountIn, protocolAmount, ownerAmount, totalWethReceived);
    }

    /**
     * @dev Executes buyback with default deadline (1 hour)
     * @param tokenIn Address of the token to use for buyback
     * @param amountIn Amount of tokens to use for buyback
     * @param amountOutMinimum Minimum amount of WETH to receive (slippage protection)
     * @param fee Fee tier for the swap (0.05% = 500, 0.3% = 3000, 1% = 10000)
     * @return totalWethReceived Total amount of WETH received from buyback
     */
    function executeBuybackSimple(address tokenIn, uint256 amountIn, uint256 amountOutMinimum, uint24 fee)
        external
        onlyOwner
        returns (uint256 totalWethReceived)
    {
        return _executeBuyback(tokenIn, amountIn, amountOutMinimum, fee, block.timestamp + 3600);
    }

    /**
     * @dev Withdraws tokens from the protocol contract
     * @param token Address of the token to withdraw (WETH for wrapped BASE)
     * @param amount Amount of tokens to withdraw
     * @param unwrapToNative Whether to unwrap WETH to native BASE
     * @notice This function allows the owner to withdraw accumulated protocol fees
     * @custom:security Only the owner can withdraw tokens
     */
    function withdraw(address token, uint256 amount, bool unwrapToNative) public nonReentrant onlyOwner {
        if (token == WETH) {
            // Handle WETH withdrawal
            if (IERC20(WETH).balanceOf(address(this)) < amount) {
                revert InsufficientBalance(token, amount);
            }

            if (unwrapToNative) {
                // Unwrap WETH to native BASE and send to owner
                IWETH(WETH).withdraw(amount);
                (bool sent,) = msg.sender.call{value: amount}("");
                require(sent, "Failed to send native token");
            } else {
                // Send WETH directly to owner
                IERC20(WETH).safeTransfer(msg.sender, amount);
            }
        } else {
            // Handle ERC20 token withdrawal
            if (IERC20(token).balanceOf(address(this)) < amount) {
                revert InsufficientBalance(token, amount);
            }
            IERC20(token).safeTransfer(msg.sender, amount);
        }
    }

    /**
     * @dev Withdraws tokens from the protocol contract (backward compatibility)
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     * @notice Defaults to not unwrapping WETH
     */
    function withdraw(address token, uint256 amount) public nonReentrant onlyOwner {
        withdraw(token, amount, false);
    }

    /**
     * @dev Withdraws owner's available balance
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     * @param unwrapToNative Whether to unwrap WETH to native BASE
     * @notice Owner can only withdraw their available balance (5% share from buybacks)
     */
    function withdrawOwnerBalance(address token, uint256 amount, bool unwrapToNative) public nonReentrant onlyOwner {
        if (amount > ownerAvailableBalance[token]) {
            revert InsufficientBalance(token, amount);
        }

        ownerAvailableBalance[token] -= amount;

        if (token == WETH) {
            // Handle WETH withdrawal
            if (unwrapToNative) {
                // Unwrap WETH to native BASE and send to owner
                IWETH(WETH).withdraw(amount);
                (bool sent,) = msg.sender.call{value: amount}("");
                require(sent, "Failed to send native token");
            } else {
                // Send WETH directly to owner
                IERC20(WETH).safeTransfer(msg.sender, amount);
            }
        } else {
            // Handle ERC20 token withdrawal
            IERC20(token).safeTransfer(msg.sender, amount);
        }
    }

    /**
     * @dev Withdraws owner's available balance (backward compatibility)
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     * @notice Defaults to not unwrapping WETH
     */
    function withdrawOwnerBalance(address token, uint256 amount) public onlyOwner {
        withdrawOwnerBalance(token, amount, false);
    }

    /**
     * @dev Gets the total protocol locked balance for a token
     * @param token Address of the token
     * @return The locked balance for the protocol
     */
    function getProtocolLockedBalance(address token) public view returns (uint256) {
        return protocolLockedBalance[token];
    }

    /**
     * @dev Gets the owner's available balance for a token
     * @param token Address of the token
     * @return The available balance for the owner
     */
    function getOwnerAvailableBalance(address token) public view returns (uint256) {
        return ownerAvailableBalance[token];
    }

    /**
     * @dev Gets the total protocol balance (locked + available) for a token
     * @param token Address of the token
     * @return The total balance held by the protocol
     */
    function getTotalProtocolBalance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}
