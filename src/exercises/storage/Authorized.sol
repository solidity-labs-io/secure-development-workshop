pragma solidity 0.8.25;

/// inherit ownable, switch around the order o
contract Authorized {
    /// @notice Mapping of authorized tokens
    mapping(address => bool) public authorizedToken;
}
