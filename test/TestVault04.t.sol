pragma solidity ^0.8.0;

import {SafeERC20} from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test, console} from "@forge-std/Test.sol";
import {ERC1967Utils} from
    "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {ProxyAdmin} from
    "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

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

    function testValidate() public view {
        assertEq(
            vault.maxSupply(), 1_000_000e18, "max supply not set"
        );

        bytes32 adminSlot =
            vm.load(address(vault), ERC1967Utils.ADMIN_SLOT);
        address proxyAdmin = address(uint160(uint256(adminSlot)));

        assertEq(
            ProxyAdmin(proxyAdmin).owner(),
            addresses.getAddress("COMPOUND_TIMELOCK_BRAVO"),
            "owner not set"
        );
    }
}
