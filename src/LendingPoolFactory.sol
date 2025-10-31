// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ILPDeployer} from "./interfaces/ILPDeployer.sol";
import {ILPRouterDeployer} from "./interfaces/ILPRouterDeployer.sol";
import {ILPRouter} from "./interfaces/ILPRouter.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title LendingPoolFactory
 * @author Senja Protocol
 * @notice Factory contract for creating and managing lending pools
 * @dev This contract serves as the main entry point for creating new lending pools.
 * It maintains a registry of all created pools and manages token data streams
 * and cross-chain token senders.
 */
contract LendingPoolFactory is
    Initializable,
    ContextUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    /**
     * @notice Emitted when a new lending pool is created
     * @param collateralToken The address of the collateral token
     * @param borrowToken The address of the borrow token
     * @param lendingPool The address of the created lending pool
     * @param ltv The Loan-to-Value ratio for the pool
     */

    event LendingPoolCreated(
        address indexed collateralToken, address indexed borrowToken, address indexed lendingPool, uint256 ltv
    );

    /**
     * @notice Emitted when an operator is set
     * @param operator The address of the operator
     * @param status The status of the operator
     */
    event OperatorSet(address indexed operator, bool status);

    /**
     * @notice Emitted when an oft address is set
     * @param token The address of the token
     * @param oftAddress The address of the oft address
     */
    event OftAddressSet(address indexed token, address indexed oftAddress);

    /**
     * @notice Emitted when a token data stream is added
     * @param token The address of the token
     * @param dataStream The address of the data stream contract
     */
    event TokenDataStreamAdded(address indexed token, address indexed dataStream);
    event LendingPoolDeployerSet(address indexed lendingPoolDeployer);

    event ProtocolSet(address indexed protocol);

    event IsHealthySet(address indexed isHealthy);

    event PositionDeployerSet(address indexed positionDeployer);

    event LendingPoolRouterDeployerSet(address indexed lendingPoolRouterDeployer);

    /**
     * @notice Structure representing a lending pool
     * @param collateralToken The address of the collateral token
     * @param borrowToken The address of the borrow token
     * @param lendingPoolAddress The address of the lending pool contract
     */
    // solhint-disable-next-line gas-struct-packing
    struct Pool {
        address collateralToken;
        address borrowToken;
        address lendingPoolAddress;
    }

    /// @notice The address of the IsHealthy contract for health checks
    address public isHealthy;

    /// @notice The address of the lending pool deployer contract
    address public lendingPoolDeployer;

    /// @notice The address of the protocol contract
    address public protocol;

    /// @notice The address of the position deployer contract
    address public positionDeployer;

    /// @notice WETH address on Base mainnet
    address public constant WETH = 0x4200000000000000000000000000000000000006;

    /// @notice Mapping from token address to its data stream address
    mapping(address => address) public tokenDataStream;

    /// @notice Mapping from operator address to their status
    mapping(address => bool) public operator;

    /// @notice Mapping from token to its OFT adapter address for cross-chain operations
    mapping(address => address) public oftAddress; // token => oftaddress

    /// @notice Array of all created pools
    Pool[] public pools;

    /// @notice Total number of pools created
    uint256 public poolCount;

    /// @notice VERSION Upgraded
    uint8 public constant VERSION = 2;

    /// @notice The address of the lending pool router deployer contract
    address public lendingPoolRouterDeployer;

    /**
     * @notice Constructor that disables initializers for UUPS proxy pattern
     * @dev Prevents initialization of the implementation contract
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Pauses all pausable operations in the contract
     * @dev Only callable by addresses with PAUSER_ROLE
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses all pausable operations in the contract
     * @dev Only callable by addresses with PAUSER_ROLE
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Initializes the factory contract with core addresses
     * @param _isHealthy The address of the IsHealthy contract
     * @param _lendingPoolRouterDeployer The address of the lending pool router deployer
     * @param _lendingPoolDeployer The address of the lending pool deployer
     * @param _protocol The address of the protocol contract
     * @param _positionDeployer The address of the position deployer
     * @dev This function can only be called once due to the initializer modifier
     */
    function initialize(
        address _isHealthy,
        address _lendingPoolRouterDeployer,
        address _lendingPoolDeployer,
        address _protocol,
        address _positionDeployer
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);

        isHealthy = _isHealthy;
        lendingPoolRouterDeployer = _lendingPoolRouterDeployer;
        lendingPoolDeployer = _lendingPoolDeployer;
        protocol = _protocol;
        positionDeployer = _positionDeployer;
    }

    /**
     * @notice Creates a new lending pool with the specified parameters
     * @param collateralToken The address of the collateral token
     * @param borrowToken The address of the borrow token
     * @param ltv The Loan-to-Value ratio for the pool (in basis points)
     * @dev This function deploys a new lending pool using the lending pool deployer
     * @return The address of the newly created lending pool
     * @dev This function deploys a new lending pool using the lending pool deployer
     */
    function createLendingPool(address collateralToken, address borrowToken, uint256 ltv) public returns (address) {
        // Deploy a new router for this pool
        address router = ILPRouterDeployer(lendingPoolRouterDeployer).deployLendingPoolRouter(
            address(this), collateralToken, borrowToken, ltv
        );
        // Deploy the LendingPool
        address lendingPool = ILPDeployer(lendingPoolDeployer).deployLendingPool(address(router));

        // Configure the lending pool address in the router
        // This allows only the lending pool to update its own interest rate parameters
        ILPRouter(router).setLendingPool(address(lendingPool));

        pools.push(Pool(collateralToken, borrowToken, address(lendingPool)));
        poolCount++;

        emit LendingPoolCreated(collateralToken, borrowToken, address(lendingPool), ltv);

        return address(lendingPool);
    }

    /**
     * @notice Adds a token data stream for price feeds and other data
     * @param _token The address of the token
     * @param _dataStream The address of the data stream contract
     * @dev Only callable by the owner
     */
    function addTokenDataStream(address _token, address _dataStream) public onlyRole(OWNER_ROLE) {
        tokenDataStream[_token] = _dataStream;
        emit TokenDataStreamAdded(_token, _dataStream);
    }

    /**
     * @notice Sets the operator status for an address
     * @param _operator The address to set operator status for
     * @param _status The operator status (true = operator, false = not operator)
     * @dev Only callable by addresses with OWNER_ROLE
     */
    function setOperator(address _operator, bool _status) public onlyRole(OWNER_ROLE) {
        operator[_operator] = _status;
        emit OperatorSet(_operator, _status);
    }

    /**
     * @notice Sets the OFT (Omnichain Fungible Token) adapter address for a token
     * @param _token The address of the token
     * @param _oftAddress The address of the OFT adapter for cross-chain operations
     * @dev Only callable by addresses with OWNER_ROLE
     */
    function setOftAddress(address _token, address _oftAddress) public onlyRole(OWNER_ROLE) {
        oftAddress[_token] = _oftAddress;
        emit OftAddressSet(_token, _oftAddress);
    }

    /**
     * @notice Sets the lending pool deployer address
     * @param _lendingPoolDeployer The new lending pool deployer address
     * @dev Only callable by addresses with OWNER_ROLE
     */
    function setLendingPoolDeployer(address _lendingPoolDeployer) public onlyRole(OWNER_ROLE) {
        lendingPoolDeployer = _lendingPoolDeployer;
        emit LendingPoolDeployerSet(_lendingPoolDeployer);
    }

    /**
     * @notice Sets the protocol contract address
     * @param _protocol The new protocol contract address
     * @dev Only callable by addresses with OWNER_ROLE
     */
    function setProtocol(address _protocol) public onlyRole(OWNER_ROLE) {
        protocol = _protocol;
        emit ProtocolSet(_protocol);
    }

    /**
     * @notice Sets the IsHealthy contract address
     * @param _isHealthy The new IsHealthy contract address
     * @dev Only callable by addresses with OWNER_ROLE
     */
    function setIsHealthy(address _isHealthy) public onlyRole(OWNER_ROLE) {
        isHealthy = _isHealthy;
        emit IsHealthySet(_isHealthy);
    }

    /**
     * @notice Sets the position deployer address
     * @param _positionDeployer The new position deployer address
     * @dev Only callable by addresses with OWNER_ROLE
     */
    function setPositionDeployer(address _positionDeployer) public onlyRole(OWNER_ROLE) {
        positionDeployer = _positionDeployer;
        emit PositionDeployerSet(_positionDeployer);
    }

    /**
     * @notice Sets the lending pool router deployer address
     * @param _lendingPoolRouterDeployer The new lending pool router deployer address
     * @dev Only callable by addresses with OWNER_ROLE
     */
    function setLendingPoolRouterDeployer(address _lendingPoolRouterDeployer) public onlyRole(OWNER_ROLE) {
        lendingPoolRouterDeployer = _lendingPoolRouterDeployer;
        emit LendingPoolRouterDeployerSet(_lendingPoolRouterDeployer);
    }

    /**
     * @notice Authorizes contract upgrades
     * @param newImplementation The address of the new implementation
     * @dev Only callable by addresses with UPGRADER_ROLE
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}
