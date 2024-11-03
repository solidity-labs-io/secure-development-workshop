pragma solidity 0.8.25;

import {SafeERC20} from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault {
    using SafeERC20 for IERC20;

    /// @notice Mapping of authorized tokens
    mapping(address => bool) public authorizedToken;

    /// @notice User's balance of all tokens deposited in the vault
    mapping(address => uint256) public balanceOf;

    /// @notice Total amount of tokens supplied to the vault
    ///
    /// invariants:
    ///      totalSupplied = sum(balanceOf all users)
    ///      sum(balanceOf(vault) authorized tokens) >= totalSupplied
    ///
    uint256 public totalSupplied;

    /// @notice Deposit event
    /// @param token The token deposited
    /// @param sender The address that deposited the token
    /// @param amount The amount deposited
    event Deposit(
        address indexed token, address indexed sender, uint256 amount
    );

    /// @notice Withdraw event
    /// @param token The token withdrawn
    /// @param sender The address that withdrew the token
    /// @param amount The amount withdrawn
    event Withdraw(
        address indexed token, address indexed sender, uint256 amount
    );

    constructor(address[] memory _tokens) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            authorizedToken[_tokens[i]] = true;
        }
    }

    /// @notice Deposit tokens into the vault
    /// @param token The token to deposit, only authorized tokens allowed
    /// @param amount The amount to deposit
    function deposit(address token, uint256 amount) external {
        require(authorizedToken[token], "Vault: token not authorized");

        /// save on gas by using unchecked, no need to check for overflow
        /// as all deposited tokens are whitelisted
        unchecked {
            balanceOf[msg.sender] += amount;
            totalSupplied += amount;
        }

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(token, msg.sender, amount);
    }

    /// @notice Withdraw tokens from the vault
    /// @param token The token to withdraw, only authorized tokens are allowed
    /// this is implicitly checked because a user can only have a balance of an
    /// authorized token
    /// @param amount The amount to withdraw
    function withdraw(address token, uint256 amount) external {
        /// both a check and an effect, ensures user has sufficient funds for withdrawal
        balanceOf[msg.sender] -= amount;

        /// save on gas by using unchecked, no need to check for underflow
        /// as all deposited tokens are whitelisted
        unchecked {
            /// implicitly checks for balance
            totalSupplied -= amount;
        }

        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdraw(token, msg.sender, amount);
    }
}
