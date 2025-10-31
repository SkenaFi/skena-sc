// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title USDTk
 * @author Senja Protocol
 * @notice Bridge token representing USDT on non-native chains
 * @dev ERC20 token with mint/burn functionality for cross-chain operations
 * Uses 6 decimals to match USDT standard
 */
contract USDTk is ERC20, Ownable {
    /// @notice Mapping of authorized operators who can mint and burn
    mapping(address => bool) public operator;

    /// @notice Error thrown when caller is not an operator
    error NotOperator();

    /**
     * @notice Constructor to initialize the USDT representative token
     * @dev Sets up the token with name, symbol, and owner
     */
    constructor() ERC20("USD Tether representative", "USDTk") Ownable(msg.sender) {}

    /**
     * @notice Modifier to restrict function access to operators only
     * @dev Reverts if caller is not an authorized operator
     */
    modifier onlyOperator() {
        _onlyOperator();
        _;
    }

    /**
     * @notice Internal function to check if caller is an operator
     * @dev Reverts with NotOperator if caller is not authorized
     */
    function _onlyOperator() internal view {
        if (!operator[msg.sender]) revert NotOperator();
    }

    /**
     * @notice Returns the number of decimals for the token
     * @return The number of decimals (6, matching USDT)
     * @dev Overrides ERC20 default of 18 decimals
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /**
     * @notice Sets the operator status for an address
     * @param _operator The address to set operator status for
     * @param _isOperator The operator status (true = operator, false = not operator)
     * @dev Only callable by owner
     */
    function setOperator(address _operator, bool _isOperator) public onlyOwner {
        operator[_operator] = _isOperator;
    }

    /**
     * @notice Mints tokens to an address
     * @param _to The address to mint tokens to
     * @param _amount The amount of tokens to mint
     * @dev Only callable by authorized operators
     */
    function mint(address _to, uint256 _amount) public onlyOperator {
        _mint(_to, _amount);
    }

    /**
     * @notice Burns tokens from an address
     * @param _from The address to burn tokens from
     * @param _amount The amount of tokens to burn
     * @dev Only callable by authorized operators
     */
    function burn(address _from, uint256 _amount) public onlyOperator {
        _burn(_from, _amount);
    }
}
