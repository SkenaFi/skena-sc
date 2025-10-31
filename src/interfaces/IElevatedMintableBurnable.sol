// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title IElevatedMintableBurnable
 * @author Senja Protocol
 * @notice Interface for tokens with elevated mint/burn permissions
 * @dev Used by cross-chain bridge operators that require mint/burn with return values
 */
interface IElevatedMintableBurnable {
    /// @notice Burns tokens from an address
    /// @param _from The address to burn tokens from
    /// @param _amount The amount of tokens to burn
    /// @return success True if burn was successful
    function burn(address _from, uint256 _amount) external returns (bool success);
    
    /// @notice Mints tokens to an address
    /// @param _to The address to mint tokens to
    /// @param _amount The amount of tokens to mint
    /// @return success True if mint was successful
    function mint(address _to, uint256 _amount) external returns (bool success);
}
