// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Position} from "./Position.sol";

/**
 * @title PositionDeployer
 * @author Senja Protocol
 * @notice A factory contract for deploying new Position instances
 * @dev This contract is responsible for creating new positions with specified parameters
 *
 * The PositionDeployer allows the factory to create new positions with different
 * collateral and borrow token pairs, along with configurable loan-to-value (LTV) ratios.
 * Each deployed position is a separate contract instance that manages position and borrowing
 * operations for a specific token pair.
 */
contract PositionDeployer {
    /// @notice Error thrown when caller is not the owner
    error OnlyOwnerCanCall();

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
     * @notice Deploys a new Position contract with specified parameters
     * @param _lendingPool The address of the lending pool contract
     * @param _user The address of the user
     * @return The address of the newly deployed Position contract
     *
     * @dev This function creates a new Position instance with the provided parameters.
     * Only the factory contract should call this function to ensure proper pool management.
     *
     * Requirements:
     * - _lendingPool must be a valid lending pool contract address
     * - _user must be a valid user address
     *
     * @custom:security This function should only be called by the factory contract
     */
    function deployPosition(address _lendingPool, address _user) public returns (address) {
        // Deploy the Position with the provided router
        Position position = new Position(_lendingPool, _user);

        return address(position);
    }

    /**
     * @notice Sets the owner address
     * @param _owner The new owner address
     * @dev Only callable by current owner
     */
    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
}
