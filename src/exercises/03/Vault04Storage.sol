pragma solidity 0.8.25;

/// inherit ownable, switch around the order o
contract Vault04Storage {
    /// @notice Mapping of authorized tokens
    mapping(address => bool) public authorizedToken;

    /// @notice User's balance of all tokens deposited in the vault
    mapping(address => uint256) public balanceOf;

    /// @notice Maximum amount of tokens that can be supplied to the vault
    uint256 public maxSupply;

    /// @notice Total amount of tokens supplied to the vault
    ///
    /// invariants:
    ///      totalSupplied = sum(balanceOf all users)
    ///      sum(balanceOf(vault) authorized tokens) >= totalSupplied
    ///
    uint256 public totalSupplied;
}
