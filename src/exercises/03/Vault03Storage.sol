pragma solidity 0.8.25;

import {OwnableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Vault03Storage is OwnableUpgradeable {
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
}
