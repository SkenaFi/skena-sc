// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWETH
 * @author Senja Protocol
 * @notice Interface for Wrapped ETH (WETH) token functionality
 * @dev Extends IERC20 with deposit and withdraw functions
 */
interface IWETH is IERC20 {
    /// @notice Deposits native ETH and mints equivalent WETH
    /// @dev Caller must send ETH with the transaction
    function deposit() external payable;
    
    /// @notice Withdraws WETH and sends native ETH to caller
    /// @param wad The amount of WETH to withdraw
    function withdraw(uint256 wad) external;
}
