// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {GovernorBravoProposal} from
    "@forge-proposal-simulator/src/proposals/GovernorBravoProposal.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

import {Vault03} from "src/examples/03/Vault03.sol";
import {Vault04} from "src/examples/04/Vault04.sol";
import {MockToken} from "@mocks/MockToken.sol";
import {ForkSelector, ETHEREUM_FORK_ID} from "@test/utils/Forks.sol";
import {ProxyAdmin, TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/// DO_RUN=false DO_BUILD=false DO_DEPLOY=true DO_SIMULATE=false DO_PRINT=false DO_VALIDATE=true forge script src/proposals/sips/SIP02.sol:SIP02 -vvvv
contract SIP02 is GovernorBravoProposal {
    using ForkSelector for uint256;

    constructor() {
        // ETHEREUM_FORK_ID.createForksAndSelect();
        primaryForkId = ETHEREUM_FORK_ID;
    }

    function setupProposal() public {
        ETHEREUM_FORK_ID.createForksAndSelect();

        string memory addressesFolderPath = "./addresses";
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 1;

        setAddresses(new Addresses(addressesFolderPath, chainIds));
    }

    function name() public pure override returns (string memory) {
        return "SIP-02 Upgrade";
    }

    function description() public pure override returns (string memory) {
        return name();
    }

    function run() public override {
        setupProposal();

        setGovernor(addresses.getAddress("COMPOUND_GOVERNOR_BRAVO"));

        super.run();
    }

    function deploy() public override {
        address vaultProxy;
        if (!addresses.isAddressSet("V3_VAULT_IMPLEMENTATION")) {
            address vaultImpl = address(new Vault03());
            addresses.addAddress("V3_VAULT_IMPLEMENTATION", vaultImpl, true);

            address[] memory tokens = new address[](3);
            tokens[0] = addresses.getAddress("USDC");
            tokens[1] = addresses.getAddress("DAI");
            tokens[2] = addresses.getAddress("USDT");

            address owner = addresses.getAddress("DEPLOYER_EOA");

            // Generate calldata for initialize function of vault
            bytes memory data = abi.encodeWithSignature("initialize(address[],address)", tokens, owner);

            vaultProxy = address(new TransparentUpgradeableProxy(vaultImpl, owner, data));
            addresses.addAddress("VAULT_PROXY", vaultProxy, true);
        }

        deal(addresses.getAddress("USDC"), addresses.getAddress("DEPLOYER_EOA"), 1_000e18);
        IERC20(addresses.getAddress("USDC")).approve(vaultProxy, type(uint256).max);
        Vault03(vaultProxy).deposit(addresses.getAddress("USDC"), uint256(1_000e18));

        bytes32 adminSlot = vm.load(vaultProxy, ERC1967Utils.ADMIN_SLOT);
        address admin = address(uint160(uint256(adminSlot)));

        if (!addresses.isAddressSet("V4_VAULT_IMPLEMENTATION")) {
            address vaultImpl = address(new Vault04());
            addresses.addAddress("V4_VAULT_IMPLEMENTATION", vaultImpl, true);

            // upgrade to new implementation
            ProxyAdmin(admin).upgradeAndCall(ITransparentUpgradeableProxy(vaultProxy), vaultImpl, "");
        }

        Vault04(vaultProxy).setMaxSupply(1_000_000e18);
    }

    function validate() public view override {
        Vault04 vault = Vault04(addresses.getAddress("VAULT_PROXY"));

        assertEq(
            vault.authorizedToken(addresses.getAddress("USDC")),
            true,
            "USDC should be authorized"
        );
        assertEq(
            vault.authorizedToken(addresses.getAddress("DAI")),
            true,
            "DAI should be authorized"
        );
        assertEq(
            vault.authorizedToken(addresses.getAddress("USDT")),
            true,
            "USDT should be authorized"
        );

        assertEq(vault.maxSupply(), 1_000_000e18, "Max supply should be 1,000,000 USDC");
        // fails as slot for totalSupplied is changed
        assertEq(vault.totalSupplied(), 1_000e18, "Total supplied should be 1000 USDC");
    }
}

