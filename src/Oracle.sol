// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOrakl} from "./interfaces/IOrakl.sol";

/**
 * @title Pricefeed
 * @dev Mock price feed contract for testing purposes
 * @notice This contract simulates Chainlink-style price feed functionality
 * @author Senja Team
 * @custom:version 1.0.0
 */
contract Oracle is Ownable {
    // ============ State Variables ============

    /**
     * @dev Address of the oracle this price feed tracks
     */
    address public oracle;

    /**
     * @dev Current round ID for the price feed
     */
    uint80 public roundId;

    /**
     * @dev Current price of the oracle
     */
    uint256 public price;

    /**
     * @dev Timestamp when the current round started
     */
    uint256 public startedAt;

    /**
     * @dev Timestamp when the price was last updated
     */
    uint256 public updatedAt;

    /**
     * @dev Round ID in which the answer was computed
     */
    uint80 public answeredInRound;

    /**
     * @dev Number of decimal places for the price
     */

    /**
     * @dev Constructor for the Pricefeed contract
     * @param _oracle Address of the oracle to track
     * @notice Initializes the price feed with the specified oracle
     */
    constructor(address _oracle) Ownable(msg.sender) {
        oracle = _oracle;
    }

    /**
     * @notice Sets the oracle address
     * @param _oracle The new oracle address to use for price data
     * @dev Only callable by the owner
     */
    function setOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }

    /**
     * @notice Returns the latest round data in Chainlink format
     * @dev Fetches data from the underlying oracle contract
     * @return idRound The round ID
     * @return priceAnswer The current price answer
     * @return startedAt Timestamp when the round started
     * @return updated Timestamp when the price was last updated
     * @return answeredInRound The round ID in which the answer was computed
     */
    function latestRoundData() public view returns (uint80, uint256, uint256, uint256, uint80) {
        (uint80 idRound, int256 priceAnswer, uint256 updated) = IOrakl(oracle).latestRoundData();
        return (idRound, uint256(priceAnswer), startedAt, updated, answeredInRound);
    }

    /**
     * @notice Returns the number of decimals used by the oracle
     * @dev Fetches decimals from the underlying oracle contract
     * @return The number of decimal places
     */
    function decimals() public view returns (uint8) {
        return IOrakl(oracle).decimals();
    }
}
