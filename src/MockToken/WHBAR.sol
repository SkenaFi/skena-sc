// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title WHBAR
 * @author Senja Protocol
 * @notice Mock WHBAR token for testing purposes
 * @dev Simple ERC20 token with public mint/burn functions for testing
 * Uses 8 decimals to match real WHBAR
 */
contract WHBAR is ERC20 {
    /**
     * @notice Constructor to initialize the mock WHBAR token
     * @dev Sets up the token with name and symbol
     */
    constructor() ERC20("WHBAR", "WHBAR") {}

    /**
     * @notice Returns the number of decimals for the token
     * @return The number of decimals (8, matching real WHBAR)
     * @dev Overrides ERC20 default decimals
     */
    function decimals() public pure override returns (uint8) {
        return 8;
    }

    /**
     * @notice Mints tokens to an address
     * @param _to The address to mint tokens to
     * @param _amount The amount of tokens to mint
     * @dev Public function for testing - no access control
     */
    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    /**
     * @notice Burns tokens from an address
     * @param _from The address to burn tokens from
     * @param _amount The amount of tokens to burn
     * @dev Public function for testing - no access control
     */
    function burn(address _from, uint256 _amount) public {
        _burn(_from, _amount);
    }
}
