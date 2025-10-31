// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LendingPoolRouter} from "./LendingPoolRouter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LendingPoolRouterDeployer
 * @author Senja Protocol
 * @notice Deploys new LendingPoolRouter contracts for the protocol
 * @dev Factory contract uses this deployer to create router instances
 */
contract LendingPoolRouterDeployer is Ownable {
    /// @notice Error thrown when caller is not the factory
    error OnlyFactoryCanCall();

    /// @notice Emitted when a new lending pool router is deployed
    /// @param router The address of the newly deployed router
    /// @param collateralToken The address of the collateral token
    /// @param borrowToken The address of the borrow token
    /// @param ltv The loan-to-value ratio for the pool
    event LendingPoolRouterDeployed(
        address indexed router, address indexed collateralToken, address indexed borrowToken, uint256 ltv
    );

    /// @notice The most recently deployed router
    LendingPoolRouter public router;
    /// @notice The address of the factory contract
    address public factory;

    /**
     * @notice Constructor to initialize the deployer
     * @dev Sets the deployer as the initial owner
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Modifier to restrict function access to factory only
     * @dev Reverts if caller is not the factory
     */
    modifier onlyFactory() {
        _onlyFactory();
        _;
    }

    /**
     * @notice Deploys a new LendingPoolRouter contract
     * @param _factory The address of the factory contract
     * @param _collateralToken The address of the collateral token
     * @param _borrowToken The address of the borrow token
     * @param _ltv The loan-to-value ratio in basis points
     * @return The address of the newly deployed router
     * @dev Only callable by factory. Creates a new router instance with specified parameters
     */
    function deployLendingPoolRouter(address _factory, address _collateralToken, address _borrowToken, uint256 _ltv)
        public
        onlyFactory
        returns (address)
    {
        router = new LendingPoolRouter(address(0), _factory, _collateralToken, _borrowToken, _ltv);
        emit LendingPoolRouterDeployed(address(router), _collateralToken, _borrowToken, _ltv);
        return address(router);
    }

    /**
     * @notice Sets the factory address
     * @param _factory The new factory address
     * @dev Only callable by owner
     */
    function setFactory(address _factory) public onlyOwner {
        factory = _factory;
    }

    /**
     * @notice Internal function to check if caller is factory
     * @dev Reverts with OnlyFactoryCanCall if caller is not the factory
     */
    function _onlyFactory() internal view {
        if (msg.sender != factory) revert OnlyFactoryCanCall();
    }
}
