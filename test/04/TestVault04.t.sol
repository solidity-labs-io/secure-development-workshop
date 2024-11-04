pragma solidity ^0.8.0;

import {SafeERC20} from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test} from "@forge-std/Test.sol";

import {Vault04} from "src/examples/04/vault04.sol";
import {SIP02IncorrectUpgrade} from "src/proposals/sips/SIP02IncorrectUpgrade.sol";

contract TestVault04 is Test, SIP02IncorrectUpgrade {
    using SafeERC20 for IERC20;

    Vault04 public vault;

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
        vm.setEnv("DO_VALIDATE", "false");

        /// setup the proposal
        setupProposal();

        /// run the proposal
        vm.startPrank(addresses.getAddress("DEPLOYER_EOA"));
        deploy();
        vm.stopPrank();
        dai = addresses.getAddress("DAI");
        usdc = addresses.getAddress("USDC");
        usdt = addresses.getAddress("USDT");
        vault = Vault04(addresses.getAddress("VAULT_PROXY"));
    }

    function testVaultDepositDai() public {
        uint256 daiDepositAmount = 1_000e18;

        _vaultDeposit(dai, address(this), daiDepositAmount);
    }

    function testVaultWithdrawalDai() public {
        uint256 daiDepositAmount = 1_000e18;

        _vaultDeposit(dai, address(this), daiDepositAmount);

        vault.withdraw(dai, daiDepositAmount);

        assertEq(vault.balanceOf(address(this)), 0, "vault dai balance not 0");
        assertEq(vault.totalSupplied(), 0, "vault total supplied not 0");
        assertEq(
            IERC20(dai).balanceOf(address(this)),
            daiDepositAmount,
            "user's dai balance not increased"
        );
    }

    function testWithdrawAlreadyDepositedUSDC() public {
        uint256 usdcDepositAmount = 1_000e6;
        vault.withdraw(usdc, usdcDepositAmount);
    }

    function _vaultDeposit(address token, address sender, uint256 amount)
        private
    {
        uint256 startingTotalSupplied = vault.totalSupplied();
        uint256 startingTotalBalance = IERC20(token).balanceOf(address(vault));
        uint256 startingUserBalance = vault.balanceOf(sender);

        deal(token, sender, amount);

        vm.startPrank(sender);
        IERC20(token).safeIncreaseAllowance(
            addresses.getAddress("VAULT_PROXY"), amount
        );

        /// this executes 3 state transitions:
        ///     1. deposit dai into the vault
        ///     2. increase the user's balance in the vault
        ///     3. increase the total supplied amount in the vault
        vault.deposit(token, amount);
        vm.stopPrank();

        assertEq(
            vault.balanceOf(sender),
            startingUserBalance + amount,
            "user vault balance not increased"
        );
        assertEq(
            vault.totalSupplied(),
            startingTotalSupplied + amount,
            "vault total supplied not increased by deposited amount"
        );
        assertEq(
            IERC20(token).balanceOf(address(vault)),
            startingTotalBalance + amount,
            "token balance not increased"
        );
    }
}
