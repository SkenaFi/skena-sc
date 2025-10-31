// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title ISrcEidLib
 * @author Senja Protocol
 * @notice Interface for managing source endpoint ID information in LayerZero
 * @dev Stores decimal information for different chain endpoints
 */
interface ISrcEidLib {
    /// @notice Struct containing endpoint ID and decimal information
    /// @param eid The LayerZero endpoint ID
    /// @param decimals The number of decimals for tokens on that endpoint
    struct SrcEidInfo {
        uint32 eid;
        uint8 decimals;
    }

    /// @notice Returns the decimals for a source endpoint
    /// @param eid The endpoint ID to query
    /// @return The number of decimals for that endpoint
    function srcDecimals(uint32 eid) external view returns (uint8);
    
    /// @notice Sets the source endpoint information
    /// @param srcEid The source endpoint ID
    /// @param decimals The number of decimals for that endpoint
    function setSrcEidInfo(uint32 srcEid, uint8 decimals) external;
}
