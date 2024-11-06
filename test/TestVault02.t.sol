pragma solidity ^0.8.0;

import {SafeERC20} from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test} from "@forge-std/Test.sol";

import {Vault} from "src/exercises/02/Vault02.sol";
import {SIP02} from "src/exercises/02/SIP02.sol";

contract TestVault02 is Test, SIP02 {
    using SafeERC20 for IERC20;

    Vault public vault;

    /// @notice user addresses
    address public immutable userA = address(1111);
    address public immutable userB = address(2222);
    address public immutable userC = address(3333);

    /// @notice token addresses
    address public dai;
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

        dai = addresses.getAddress("DAI");
        usdc = addresses.getAddress("USDC");
        usdt = addresses.getAddress("USDT");
        vault = Vault(addresses.getAddress("V2_VAULT"));
    }

    function testValidate() public view {
        /// validate the proposal
        validate();
    }

    function testVaultDepositDai() public {
        uint256 daiDepositAmount = 1_000e18;

        _vaultDeposit(dai, address(this), daiDepositAmount);
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

    function testVaultDepositUsdt() public {
        uint256 usdtDepositAmount = 1_000e6;

        deal(usdt, address(this), usdtDepositAmount);

        USDT(usdt).approve(
            addresses.getAddress("V2_VAULT"), usdtDepositAmount
        );

        vault.deposit(usdt, usdtDepositAmount);

        assertEq(
            vault.balanceOf(address(this)),
            vault.getNormalizedAmount(usdt, usdtDepositAmount),
            "vault token balance not increased"
        );
        assertEq(
            vault.totalSupplied(),
            vault.getNormalizedAmount(usdt, usdtDepositAmount),
            "vault total supplied not increased"
        );
        assertEq(
            IERC20(usdt).balanceOf(address(vault)),
            usdtDepositAmount,
            "token balance not increased"
        );
    }

    function testVaultWithdrawalDai() public {
        uint256 daiDepositAmount = 1_000e18;

        _vaultDeposit(dai, address(this), daiDepositAmount);

        vault.withdraw(dai, daiDepositAmount);

        assertEq(
            vault.balanceOf(address(this)),
            0,
            "vault dai balance not 0"
        );
        assertEq(
            vault.totalSupplied(), 0, "vault total supplied not 0"
        );
        assertEq(
            IERC20(dai).balanceOf(address(this)),
            daiDepositAmount,
            "user's dai balance not increased"
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
            "userB usdc balance not increased"
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
            addresses.getAddress("V2_VAULT"), amount
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
