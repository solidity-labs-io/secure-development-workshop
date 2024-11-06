pragma solidity 0.8.25;

/// inherit ownable, switch around the order o
contract Balances {
    /// @notice User's balance of all tokens deposited in the vault
    mapping(address => uint256) public balanceOf;
}
