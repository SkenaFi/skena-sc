// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title ILPRouterDeployer
 * @author Senja Protocol
 * @notice Interface for deploying new LendingPoolRouter contracts
 * @dev This interface defines the deployment functionality for lending pool routers
 */
interface ILPRouterDeployer {
    /// @notice Deploys a new LendingPoolRouter contract
    /// @param _factory The address of the factory contract
    /// @param _collateralToken The address of the collateral token
    /// @param _borrowToken The address of the borrow token
    /// @param _ltv The loan-to-value ratio in basis points
    /// @return The address of the deployed LendingPoolRouter contract
    function deployLendingPoolRouter(address _factory, address _collateralToken, address _borrowToken, uint256 _ltv)
        external
        returns (address);
}
