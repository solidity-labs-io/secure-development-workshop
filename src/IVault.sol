pragma solidity 0.8.25;

/// @notice interface for a vault where a user can deposit authorized tokens
/// and then withdraw tokens.
/// Acts as a Peg Stability Module of tokens of the same value. Users can
/// deposit tokens of type A and withdraw tokens of type B.
interface IVault {
    function authorizedToken(address) external view returns (bool);
    function balanceOf(address) external view returns (uint256);
    function totalSupplied() external view returns (uint256);

    /// @notice depositing increases balanceOf and totalSupplied by amount
    /// deposited
    function deposit(address token, uint256 amount) external;

    /// @notice withdrawing decreases balanceOf and totalSupplied by amount
    /// withdrawn
    function withdraw(address token, uint256 amount) external;
}
