// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {GovernorBravoProposal} from
    "@forge-proposal-simulator/src/proposals/GovernorBravoProposal.sol";
import {Addresses} from
    "@forge-proposal-simulator/addresses/Addresses.sol";

import {Vault04} from "src/exercises/04/Vault04.sol";
import {MockToken} from "@mocks/MockToken.sol";
import {ForkSelector, ETHEREUM_FORK_ID} from "@test/utils/Forks.sol";
import {
    ProxyAdmin,
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ERC1967Utils} from
    "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// DO_RUN=false DO_BUILD=false DO_DEPLOY=true DO_SIMULATE=false DO_PRINT=false DO_VALIDATE=true forge script src/exercises/SIP04.sol:SIP04 -vvvv
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
    }

    function name() public pure override returns (string memory) {
        return "SIP-04 Upgrade";
    }

    function description()
        public
        pure
        override
        returns (string memory)
    {
        return name();
    }

    function run() public override {
        setupProposal();

        setGovernor(addresses.getAddress("COMPOUND_GOVERNOR_BRAVO"));

        super.run();
    }

    function deploy() public override {
        if (!addresses.isAddressSet("PROXY_ADMIN")) {
            ProxyAdmin proxyAdmin = new ProxyAdmin();
            proxyAdmin.transferOwnership(
                addresses.getAddress("COMPOUND_TIMELOCK_BRAVO")
            );

            addresses.addAddress("PROXY_ADMIN", address(proxyAdmin), true);
        }

        address vaultProxy;
        if (!addresses.isAddressSet("V4_VAULT_IMPLEMENTATION")) {
            address vaultImpl = address(new Vault04());
            addresses.addAddress(
                "V4_VAULT_IMPLEMENTATION", vaultImpl, true
            );

            address[] memory tokens = new address[](3);
            tokens[0] = addresses.getAddress("USDC");
            tokens[1] = addresses.getAddress("DAI");
            tokens[2] = addresses.getAddress("USDT");

            address owner = addresses.getAddress("COMPOUND_TIMELOCK_BRAVO");

            // Generate calldata for initialize function of vault
            bytes memory data = abi.encodeWithSignature(
                "initialize(address[],address)", tokens, owner
            );

            vaultProxy = address(
                new TransparentUpgradeableProxy(
                    vaultImpl, owner, data
                )
            );
            addresses.addAddress("VAULT_PROXY", vaultProxy, true);
        }
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

        address vaultProxy = addresses.getAddress("VAULT_PROXY");
        bytes32 adminSlot =
            vm.load(vaultProxy, ERC1967Utils.ADMIN_SLOT);

        address proxyAdmin = address(uint160(uint256(adminSlot)));
    }
}
