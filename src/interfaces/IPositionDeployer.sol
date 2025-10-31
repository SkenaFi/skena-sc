// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title IPositionDeployer
 * @author Senja Protocol
 * @notice Interface for deploying new Position contracts
 * @dev This interface defines the deployment functionality for user positions
 */
interface IPositionDeployer {
    /// @notice Deploys a new Position contract for a user
    /// @param _lendingPool The address of the lending pool
    /// @param _user The address of the user
    /// @return The address of the deployed Position contract
    function deployPosition(address _lendingPool, address _user) external returns (address);
    
    /// @notice Sets the owner of the deployer contract
    /// @param _owner The new owner address
    function setOwner(address _owner) external;
}
