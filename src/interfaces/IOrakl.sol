// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IOrakl
 * @author Senja Protocol
 * @notice Interface for Orakl Network price oracle
 * @dev Provides price feed data with different return format than Chainlink
 */
interface IOrakl {
    /// @notice Returns the latest price data from Orakl oracle
    /// @return roundId The round ID
    /// @return answer The price answer (int256 format)
    /// @return updatedAt Timestamp when the price was last updated
    function latestRoundData() external view returns (uint80, int256, uint256);
    
    /// @notice Returns the number of decimals for the price feed
    /// @return The number of decimals
    function decimals() external view returns (uint8);
}
