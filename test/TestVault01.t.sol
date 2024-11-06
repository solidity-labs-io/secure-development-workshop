pragma solidity ^0.8.0;

import {SafeERC20} from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console} from "@forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test} from "@forge-std/Test.sol";

import {Vault} from "src/exercises/01/Vault01.sol";
import {SIP01} from "src/exercises/01/SIP01.sol";

contract TestVault01 is Test, SIP01 {
    using SafeERC20 for IERC20;

    Vault public vault;

    /// @notice user addresses
    address public immutable userA = address(1111);
    address public immutable userB = address(2222);
    address public immutable userC = address(3333);

    /// @notice token addresses
    address public usdc;
    address public usdt;

    function setUp() public {
        /// set the environment variables
        vm.setEnv("DO_RUN", "false");
        vm.setEnv("DO_BUILD", "false");
        vm.setEnv("DO_DEPLOY", "true");
        vm.setEnv("DO_SIMULATE", "false");
        vm.setEnv("DO_PRINT", "false");
        vm.setEnv("DO_VALIDATE", "true");

        /// setup the proposal
        setupProposal();

        /// run the proposal
        deploy();

        usdc = addresses.getAddress("USDC");
        usdt = addresses.getAddress("USDT");
        vault = Vault(addresses.getAddress("V1_VAULT"));
    }

    function testVaultDepositUsdc() public {
        uint256 usdcDepositAmount = 1_000e6;

        _vaultDeposit(usdc, address(this), usdcDepositAmount);
    }

    function testMultipleUsersDepositUsdc() public {
        uint256 usdcDepositAmount = 1_000e6;

        _vaultDeposit(usdc, userA, usdcDepositAmount);
        _vaultDeposit(usdc, userB, usdcDepositAmount);
        _vaultDeposit(usdc, userC, usdcDepositAmount);
    }

    function testVaultWithdrawalUsdc() public {
        uint256 usdcDepositAmount = 1_000e6;

        _vaultDeposit(usdc, address(this), usdcDepositAmount);

        vault.withdraw(usdc, usdcDepositAmount);

        assertEq(
            vault.balanceOf(address(this)),
            0,
            "vault usdc balance not 0"
        );
        assertEq(
            vault.totalSupplied(), 0, "vault total supplied not 0"
        );
        assertEq(
            IERC20(usdc).balanceOf(address(this)),
            usdcDepositAmount,
            "user's usdc balance not increased"
        );
    }

    function testVaultDepositUsdt() public {
        uint256 usdtDepositAmount = 1_000e8;

        _vaultDeposit(usdt, address(this), usdtDepositAmount);
    }

    function testVaultWithdrawalUsdt() public {
        uint256 usdtDepositAmount = 1_000e8;

        _vaultDeposit(usdt, address(this), usdtDepositAmount);
        vault.withdraw(usdt, usdtDepositAmount);

        assertEq(
            vault.balanceOf(address(this)),
            0,
            "vault usdt balance not 0"
        );
        assertEq(
            vault.totalSupplied(), 0, "vault total supplied not 0"
        );
        assertEq(
            IERC20(usdt).balanceOf(address(this)),
            usdtDepositAmount,
            "user's usdt balance not increased"
        );
    }

    function testSwapTwoUsers() public {
        uint256 usdcDepositAmount = 1_000e6;
        uint256 usdtDepositAmount = 1_000e8;

        _vaultDeposit(usdc, userA, usdcDepositAmount);
        _vaultDeposit(usdt, userB, usdtDepositAmount);

        vm.prank(userA);
        vault.withdraw(usdt, usdcDepositAmount);
        assertEq(
            IERC20(usdt).balanceOf(userA),
            usdcDepositAmount,
            "userA usdt balance not increased"
        );

        vm.prank(userB);
        vault.withdraw(usdc, usdcDepositAmount);
        assertEq(
            IERC20(usdc).balanceOf(userB),
            usdcDepositAmount,
            "userB usdc balance not increased"
        );
        assertEq(
            IERC20(usdt).balanceOf(userA),
            usdcDepositAmount,
            "userB usdt balance remains unchanged"
        );
    }

    function _vaultDeposit(
        address token,
        address sender,
        uint256 amount
    ) private {
        uint256 startingTotalSupplied = vault.totalSupplied();
        uint256 startingTotalBalance =
            IERC20(token).balanceOf(address(vault));
        uint256 startingUserBalance = vault.balanceOf(sender);

        deal(token, sender, amount);

        vm.startPrank(sender);
        IERC20(token).safeIncreaseAllowance(
            addresses.getAddress("V1_VAULT"), amount
        );

        /// this executes 3 state transitions:
        ///     1. deposit dai into the vault
        ///     2. increase the user's balance in the vault
        ///     3. increase the total supplied amount in the vault
        vault.deposit(token, amount);
        vm.stopPrank();

        uint256 normalizedAmount =
            vault.getNormalizedAmount(token, amount);

        assertEq(
            vault.balanceOf(sender),
            startingUserBalance + normalizedAmount,
            "user vault balance not increased"
        );
        assertEq(
            vault.totalSupplied(),
            startingTotalSupplied + normalizedAmount,
            "vault total supplied not increased by deposited amount"
        );
        assertEq(
            IERC20(token).balanceOf(address(vault)),
            startingTotalBalance + amount,
            "token balance not increased"
        );
    }
}

interface USDT {
    function approve(address, uint256) external;
    function transferFrom(address, address, uint256) external;
}
