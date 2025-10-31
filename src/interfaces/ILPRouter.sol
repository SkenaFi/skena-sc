// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILPRouter
 * @author Senja Protocol
 * @notice Interface for the Lending Pool Router that manages pool state and operations
 * @dev This interface defines the core routing logic for lending pool operations
 */
interface ILPRouter {
    // ============ Read Functions ============
    
    /// @notice Returns the total supply assets in the pool
    function totalSupplyAssets() external view returns (uint256);
    
    /// @notice Returns the total supply shares issued
    function totalSupplyShares() external view returns (uint256);
    
    /// @notice Returns the total borrowed assets from the pool
    function totalBorrowAssets() external view returns (uint256);
    
    /// @notice Returns the total borrow shares issued
    function totalBorrowShares() external view returns (uint256);
    
    /// @notice Returns the timestamp of last interest accrual
    function lastAccrued() external view returns (uint256);
    
    /// @notice Returns the supply shares for a user
    /// @param _user The address of the user
    function userSupplyShares(address _user) external view returns (uint256);
    
    /// @notice Returns the borrow shares for a user
    /// @param _user The address of the user
    function userBorrowShares(address _user) external view returns (uint256);
    
    /// @notice Returns the collateral amount for a user
    /// @param _user The address of the user
    function userCollateral(address _user) external view returns (uint256);
    
    /// @notice Returns the position contract address for a user
    /// @param _user The address of the user
    function addressPositions(address _user) external view returns (address);
    
    /// @notice Returns the lending pool address
    function lendingPool() external view returns (address);
    
    /// @notice Returns the collateral token address
    function collateralToken() external view returns (address);
    
    /// @notice Returns the borrow token address
    function borrowToken() external view returns (address);
    
    /// @notice Returns the loan-to-value ratio
    function ltv() external view returns (uint256);
    
    /// @notice Returns the factory contract address
    function factory() external view returns (address);
    
    /// @notice Calculates the current borrow rate
    /// @return The borrow rate scaled by 100
    function calculateBorrowRate() external view returns (uint256);
    
    /// @notice Gets the current utilization rate
    /// @return The utilization rate scaled by 10000
    function getUtilizationRate() external view returns (uint256);
    
    /// @notice Calculates the current supply rate
    /// @return The supply rate scaled by 100
    function calculateSupplyRate() external view returns (uint256);

    // ============ Write Functions ============
    
    /// @notice Sets the lending pool address
    /// @param _lendingPool The new lending pool address
    function setLendingPool(address _lendingPool) external;
    
    /// @notice Supplies liquidity to the pool
    /// @param _amount The amount to supply
    /// @param _user The user address
    /// @return shares The amount of shares minted
    function supplyLiquidity(uint256 _amount, address _user) external returns (uint256 shares);
    
    /// @notice Withdraws liquidity from the pool
    /// @param _shares The amount of shares to burn
    /// @param _user The user address
    /// @return amount The amount of tokens withdrawn
    function withdrawLiquidity(uint256 _shares, address _user) external returns (uint256 amount);
    
    /// @notice Records collateral supplied by a user
    /// @param _user The user address
    /// @param _amount The amount of collateral
    function supplyCollateral(address _user, uint256 _amount) external;
    
    /// @notice Withdraws collateral for a user
    /// @param _amount The amount to withdraw
    /// @param _user The user address
    /// @return The remaining collateral balance
    function withdrawCollateral(uint256 _amount, address _user) external returns (uint256);
    
    /// @notice Accrues interest to the pool
    function accrueInterest() external;
    
    /// @notice Borrows debt from the pool
    /// @param _amount The amount to borrow
    /// @param _user The user address
    /// @return protocolFee The protocol fee charged
    /// @return userAmount The amount sent to user
    /// @return shares The borrow shares minted
    function borrowDebt(uint256 _amount, address _user)
        external
        returns (uint256 protocolFee, uint256 userAmount, uint256 shares);
    
    /// @notice Repays debt by burning borrow shares
    /// @param _shares The shares to burn
    /// @param _user The user address
    /// @return Multiple return values for repayment details
    function repayWithSelectedToken(uint256 _shares, address _user)
        external
        returns (uint256, uint256, uint256, uint256);
    
    /// @notice Creates a new position for a user
    /// @param _user The user address
    /// @return The address of the created position
    function createPosition(address _user) external returns (address);

    // ============ Liquidation Functions ============
    
    /// @notice Liquidates a user's position
    /// @param _user The user address
    /// @param _repayAmount The debt amount being repaid
    function liquidatePosition(address _user, uint256 _repayAmount) external;
    
    /// @notice Emergency reset of a user's position
    /// @param _user The user address
    function emergencyResetPosition(address _user) external;
    
    /// @notice Reduces user collateral during liquidation
    /// @param _user The user address
    /// @param _amount The amount to reduce
    function reduceUserCollateral(address _user, uint256 _amount) external;
}
