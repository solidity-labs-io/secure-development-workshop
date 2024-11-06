pragma solidity ^0.8.0;

import {SafeERC20} from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test, console} from "@forge-std/Test.sol";

import {SIP03} from "src/exercises/03/SIP03.sol";
import {SIP04} from "src/exercises/04/SIP04.sol";
import {Vault} from "src/exercises/04/Vault04.sol";

contract TestVault04 is Test, SIP04 {
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

    function _loadUsers() private {
        address[] memory users = new address[](3);
        users[0] = userA;
        users[1] = userB;
        users[2] = userC;

        for (uint256 i = 0; i < users.length; i++) {
            uint256 daiDepositAmount = 1_000e18;
            uint256 usdtDepositAmount = 1_000e8;
            uint256 usdcDepositAmount = 1_000e6;

            _vaultDeposit(dai, users[i], daiDepositAmount);
            _vaultDeposit(usdc, users[i], usdcDepositAmount);
            _vaultDeposit(usdt, users[i], usdtDepositAmount);
        }
    }

    function setUp() public {
        /// set the environment variables
        vm.setEnv("DO_RUN", "false");
        vm.setEnv("DO_BUILD", "false");
        vm.setEnv("DO_DEPLOY", "true");
        vm.setEnv("DO_SIMULATE", "false");
        vm.setEnv("DO_PRINT", "false");
        vm.setEnv("DO_VALIDATE", "false");

        SIP03 sip03 = new SIP03();

        sip03.setupProposal();
        sip03.deploy();

        /// set the addresses contrac to the SIP03 addresses for integration testing
        setAddresses(sip03.addresses());
        dai = addresses.getAddress("DAI");
        usdc = addresses.getAddress("USDC");
        usdt = addresses.getAddress("USDT");
        vault = Vault(addresses.getAddress("VAULT_PROXY"));

        vm.prank(vault.owner());
        vault.setMaxSupply(100_000_000e18);

        /// load data into newly deployed contract
        _loadUsers();

        /// setup the proposal
        setupProposal();

        /// overwrite the newly created proposal Addresses contract
        setAddresses(sip03.addresses());

        /// deploy contracts from MIP-04
        deploy();

        /// build and run proposal
        build();
        simulate();
    }

    function testSetup() public view {
        assertTrue(
            vault.authorizedToken(address(dai)), "Dai not whitelisted"
        );
        assertTrue(
            vault.authorizedToken(address(usdc)),
            "Usdc not whitelisted"
        );
        assertTrue(
            vault.authorizedToken(address(usdt)),
            "Usdt not whitelisted"
        );
    }

    function testVaultDepositDai() public {
        uint256 daiDepositAmount = 1_000e18;

        _vaultDeposit(dai, address(this), daiDepositAmount);
    }

    function testVaultWithdrawalDai() public {
        uint256 daiDepositAmount = 1_000e18;

        _vaultDeposit(dai, address(this), daiDepositAmount);
        uint256 startingVaultBalance = vault.balanceOf(address(this));
        uint256 startingTotalSupplied = vault.totalSupplied();

        vault.withdraw(dai, daiDepositAmount);

        assertEq(
            vault.balanceOf(address(this)),
            startingVaultBalance - daiDepositAmount,
            "vault dai balance not 0"
        );
        assertEq(
            vault.totalSupplied(),
            startingTotalSupplied - daiDepositAmount,
            "vault total supplied not 0"
        );
        assertEq(
            IERC20(dai).balanceOf(address(this)),
            daiDepositAmount,
            "user's dai balance not increased"
        );
    }

    function testWithdrawAlreadyDepositedUSDC() public {
        uint256 usdcDepositAmount = 1_000e6;

        _vaultDeposit(usdc, address(this), usdcDepositAmount);

        vault.withdraw(usdc, usdcDepositAmount);
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
            addresses.getAddress("VAULT_PROXY"), amount
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
