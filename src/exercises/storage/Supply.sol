pragma solidity 0.8.25;

/// inherit ownable, switch around the order o
contract Supply {
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
