// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title IFactory
 * @dev Interface for lending pool factory functionality
 * @notice This interface defines the contract for creating and managing lending pools
 * @author Senja Team
 * @custom:version 1.0.0
 */
interface IFactory {
    /**
     * @dev Returns the data stream address for a token
     * @param _token Address of the token
     * @return Address of the data stream contract
     */
    function tokenDataStream(address _token) external view returns (address);

    function positionDeployer() external view returns (address);

    /**
     * @dev Returns the owner address of the factory
     * @return Address of the factory owner
     */
    function owner() external view returns (address);

    /**
     * @dev Returns the address of the health check contract
     * @return Address of the isHealthy contract
     */
    function isHealthy() external view returns (address);

    function operator(address _operator) external view returns (bool);

    function oftAddress(address _token) external view returns (address);

    function WETH() external view returns (address);

    /**
     * @dev Adds a token data stream to the factory
     * @param _token Address of the token
     * @param _dataStream Address of the data stream contract
     * @notice This function registers a new token data stream
     * @custom:security Only the owner should be able to add data streams
     */
    function addTokenDataStream(address _token, address _dataStream) external;

    /**
     * @dev Creates a new lending pool
     * @param _collateralToken Address of the collateral token
     * @param _borrowToken Address of the borrow token
     * @param _ltv Loan-to-value ratio for the pool
     * @return Address of the newly created lending pool
     * @notice This function deploys a new lending pool with specified parameters
     * @custom:security Only authorized addresses should be able to create pools
     */
    function createLendingPool(address _collateralToken, address _borrowToken, uint256 _ltv)
        external
        returns (address);

    /**
     * @dev Returns the protocol contract address
     * @return Address of the protocol contract
     */
    function protocol() external view returns (address);

    /**
     * @dev Returns the total number of pools created
     * @return Number of lending pools created by this factory
     */
    function poolCount() external view returns (uint256);

    /**
     * @dev Returns the helper contract address
     * @return Address of the helper contract
     */
    function helper() external view returns (address);

    /**
     * @dev Returns the interest rate model address for a specific lending pool
     * @param lendingPool Address of the lending pool
     * @return Address of the interest rate model contract
     */
    function getInterestRateModel(address lendingPool) external view returns (address);

    function setOftAddress(address _token, address _oftAddress) external;

    function setPositionDeployer(address _positionDeployer) external;

    /**
     * @dev Sets the lending pool deployer address
     * @param _lendingPoolDeployer Address of the lending pool deployer contract
     */
    function setLendingPoolDeployer(address _lendingPoolDeployer) external;

    /**
     * @dev Sets the protocol contract address
     * @param _protocol Address of the protocol contract
     */
    function setProtocol(address _protocol) external;

    /**
     * @dev Sets the health check contract address
     * @param _isHealthy Address of the isHealthy contract
     */
    function setIsHealthy(address _isHealthy) external;

    /**
     * @dev Sets the lending pool router deployer address
     * @param _lendingPoolRouterDeployer Address of the lending pool router deployer contract
     */
    function setLendingPoolRouterDeployer(address _lendingPoolRouterDeployer) external;

    /**
     * @dev Sets the operator status for an address
     * @param _operator Address of the operator
     * @param _status Status of the operator (true/false)
     */
    function setOperator(address _operator, bool _status) external;

    /**
     * @dev Returns the lending pool deployer address
     * @return Address of the lending pool deployer contract
     */
    function lendingPoolDeployer() external view returns (address);

    /**
     * @dev Returns the lending pool router deployer address
     * @return Address of the lending pool router deployer contract
     */
    function lendingPoolRouterDeployer() external view returns (address);
}
