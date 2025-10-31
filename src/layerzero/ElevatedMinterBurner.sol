// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {IMintableBurnable} from "../interfaces/IMintableBurnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ElevatedMinterBurner
 * @author Senja Protocol
 * @notice Contract for managing minting and burning operations with elevated permissions
 * @dev Used by OFT adapters for cross-chain token operations
 * Only authorized operators can mint or burn tokens
 */
contract ElevatedMinterBurner is Ownable {
    /// @notice Emitted when tokens are burned
    /// @param from The address tokens were burned from
    /// @param to The address that initiated the burn
    /// @param amount The amount of tokens burned
    event Burn(address indexed from, address indexed to, uint256 amount);
    
    /// @notice Emitted when tokens are minted
    /// @param to The address tokens were minted to
    /// @param from The address that initiated the mint
    /// @param amount The amount of tokens minted
    event Mint(address indexed to, address indexed from, uint256 amount);

    /// @notice The token address that this contract manages
    address public immutable TOKEN;
    /// @notice Mapping of authorized operators
    mapping(address => bool) public operators;

    using SafeERC20 for IERC20;

    /**
     * @notice Modifier to restrict access to operators only
     * @dev Allows both operators and owner to call the function
     */
    modifier onlyOperators() {
        _onlyOperators();
        _;
    }

    /**
     * @notice Internal function to check if caller is an operator
     * @dev Reverts if caller is neither an operator nor the owner
     */
    function _onlyOperators() internal view {
        require(operators[msg.sender] || msg.sender == owner(), "Not authorized");
    }

    /**
     * @notice Constructor to initialize the minter/burner
     * @param _token The address of the token to manage
     * @param _owner The owner of the contract
     */
    constructor(address _token, address _owner) Ownable(_owner) {
        TOKEN = _token;
    }

    /**
     * @notice Sets the operator status for an address
     * @param _operator The address to set operator status for
     * @param _status The operator status (true = operator, false = not operator)
     * @dev Only callable by owner
     */
    function setOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
    }

    /**
     * @notice Burns tokens from the contract's balance
     * @param _from The address initiating the burn (for tracking)
     * @param _amount The amount of tokens to burn
     * @return success True if burn was successful
     * @dev Transfers tokens from caller to this contract, then burns them
     */
    function burn(address _from, uint256 _amount) external onlyOperators returns (bool) {
        IERC20(TOKEN).safeTransferFrom(msg.sender, address(this), _amount);
        IMintableBurnable(TOKEN).burn(address(this), _amount);
        emit Burn(_from, msg.sender, _amount);
        return true;
    }

    /**
     * @notice Mints tokens to a recipient
     * @param _to The address to mint tokens to
     * @param _amount The amount of tokens to mint
     * @return success True if mint was successful
     * @dev Only authorized operators can mint
     */
    function mint(address _to, uint256 _amount) external onlyOperators returns (bool) {
        IMintableBurnable(TOKEN).mint(_to, _amount);
        emit Mint(_to, msg.sender, _amount);
        return true;
    }
}
