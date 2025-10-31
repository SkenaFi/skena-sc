// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LendingPool} from "./LendingPool.sol";

/**
 * @title LendingPoolDeployer
 * @author Senja Protocol
 * @notice A factory contract for deploying new LendingPool instances
 * @dev This contract is responsible for creating new lending pools with specified parameters
 *
 * The LendingPoolDeployer allows the factory to create new lending pools with different
 * collateral and borrow token pairs, along with configurable loan-to-value (LTV) ratios.
 * Each deployed pool is a separate contract instance that manages lending and borrowing
 * operations for a specific token pair.
 */
contract LendingPoolDeployer {
    /// @notice Error thrown when caller is not the factory
    error OnlyFactoryCanCall();
    /// @notice Error thrown when caller is not the owner
    error OnlyOwnerCanCall();

    /// @notice The address of the factory contract
    address public factory;
    /// @notice The address of the owner
    address public owner;

    /**
     * @notice Constructor to initialize the deployer
     * @dev Sets the deployer as the initial owner
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Modifier to restrict function access to factory only
     * @dev Reverts if caller is not the factory
     */
    modifier onlyFactory() {
        _onlyFactory();
        _;
    }

    /**
     * @notice Internal function to check if caller is factory
     * @dev Reverts with OnlyFactoryCanCall if caller is not the factory
     */
    function _onlyFactory() internal view {
        if (msg.sender != factory) revert OnlyFactoryCanCall();
    }

    /**
     * @notice Modifier to restrict function access to owner only
     * @dev Reverts if caller is not the owner
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @notice Internal function to check if caller is owner
     * @dev Reverts with OnlyOwnerCanCall if caller is not the owner
     */
    function _onlyOwner() internal view {
        if (msg.sender != owner) revert OnlyOwnerCanCall();
    }

    /**
     * @notice Deploys a new LendingPool contract with specified parameters
     * @param _router The address of the router contract
     * @return The address of the newly deployed LendingPool contract
     *
     * @dev This function creates a new LendingPool instance with the provided parameters.
     * Only the factory contract should call this function to ensure proper pool management.
     *
     * Requirements:
     * - _router must be a valid router contract address
     *
     * @custom:security This function should only be called by the factory contract
     */
    function deployLendingPool(address _router) public onlyFactory returns (address) {
        // Deploy the LendingPool with the provided router
        LendingPool lendingPool = new LendingPool(_router);

        return address(lendingPool);
    }

    /**
     * @notice Sets the factory address
     * @param _factory The new factory address
     * @dev Only callable by owner
     */
    function setFactory(address _factory) public onlyOwner {
        factory = _factory;
    }
}
