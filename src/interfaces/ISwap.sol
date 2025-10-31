// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISwap
 * @author Senja Protocol
 * @notice Interface for UniSwap V3 Router token swapping
 * @dev Provides single-hop token swap functionality
 */
interface ISwap {
    /// @notice Parameters for exact input single-hop swap
    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param fee The pool fee tier (500 = 0.05%, 3000 = 0.3%, 10000 = 1%)
    /// @param recipient The address to receive the output tokens
    /// @param amountIn The amount of input tokens to swap
    /// @param amountOutMinimum The minimum amount of output tokens (slippage protection)
    /// @param sqrtPriceLimitX96 The price limit for the swap (0 = no limit)
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps tokens using exact input amount
    /// @param params The swap parameters
    /// @return amountOut The amount of output tokens received
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}
