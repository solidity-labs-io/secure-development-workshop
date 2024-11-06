// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {GovernorBravoProposal} from
    "@forge-proposal-simulator/src/proposals/GovernorBravoProposal.sol";
import {Addresses} from
    "@forge-proposal-simulator/addresses/Addresses.sol";
import {
    ProxyAdmin,
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ERC1967Utils} from
    "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Vault} from "src/exercises/04/Vault04.sol";
import {ForkSelector, ETHEREUM_FORK_ID} from "@test/utils/Forks.sol";

/// DO_RUN=false DO_BUILD=false DO_DEPLOY=true DO_SIMULATE=false DO_PRINT=false DO_VALIDATE=true forge script src/exercises/04/SIP04.sol:SIP04 -vvvv
contract SIP04 is GovernorBravoProposal {
    using ForkSelector for uint256;

    constructor() {
        primaryForkId = ETHEREUM_FORK_ID;
    }

    function setupProposal() public {
        ETHEREUM_FORK_ID.createForksAndSelect();

        string memory addressesFolderPath = "./addresses";
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 1;

        setAddresses(new Addresses(addressesFolderPath, chainIds));
        setGovernor(addresses.getAddress("COMPOUND_GOVERNOR_BRAVO"));
    }

    function name() public pure override returns (string memory) {
        return "SIP-04";
    }

    function description()
        public
        pure
        override
        returns (string memory)
    {
        return "Upgrade to V4 Vault Implementation";
    }

    function run() public override {
        setupProposal();

        setGovernor(addresses.getAddress("COMPOUND_GOVERNOR_BRAVO"));

        super.run();
    }

    function deploy() public override {
        if (!addresses.isAddressSet("V4_VAULT_IMPL")) {
            address vaultImpl = address(new Vault());
            addresses.addAddress("V4_VAULT_IMPL", vaultImpl, true);
        }
    }

    function build()
        public
        override
        buildModifier(addresses.getAddress("COMPOUND_TIMELOCK_BRAVO"))
    {
        address vaultProxy = addresses.getAddress("VAULT_PROXY");
        bytes32 adminSlot =
            vm.load(vaultProxy, ERC1967Utils.ADMIN_SLOT);

        address proxyAdmin = address(uint160(uint256(adminSlot)));

        /// recorded calls

        // upgrade to new implementation
        ProxyAdmin(proxyAdmin).upgradeAndCall(
            ITransparentUpgradeableProxy(vaultProxy),
            addresses.getAddress("V4_VAULT_IMPL"),
            ""
        );

        Vault(vaultProxy).setMaxSupply(1_000_000e18);
    }

    function validate() public view override {
        Vault vault = Vault(addresses.getAddress("VAULT_PROXY"));

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
        assertEq(
            vault.maxSupply(), 1_000_000e18, "max supply not set"
        );

        address vaultProxy = addresses.getAddress("VAULT_PROXY");
        bytes32 adminSlot =
            vm.load(vaultProxy, ERC1967Utils.ADMIN_SLOT);
        address proxyAdmin = address(uint160(uint256(adminSlot)));

        assertEq(
            ProxyAdmin(proxyAdmin).owner(),
            addresses.getAddress("COMPOUND_TIMELOCK_BRAVO"),
            "owner not set"
        );
    }
}
