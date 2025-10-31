// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title IMintableBurnable
 * @author Senja Protocol
 * @notice Interface for tokens that can be minted and burned
 * @dev Used for tokens that require mint/burn functionality for cross-chain operations
 */
interface IMintableBurnable {
    /// @notice Burns tokens from an address
    /// @param _from The address to burn tokens from
    /// @param _amount The amount of tokens to burn
    function burn(address _from, uint256 _amount) external;
    
    /// @notice Mints tokens to an address
    /// @param _to The address to mint tokens to
    /// @param _amount The amount of tokens to mint
    function mint(address _to, uint256 _amount) external;
}
