// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {GovernorBravoProposal} from
    "@forge-proposal-simulator/src/proposals/GovernorBravoProposal.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

import {Vault} from "src/examples/00/Vault.sol";
import {MockToken} from "@mocks/MockToken.sol";
import {ForkSelector, ETHEREUM_FORK_ID} from "@test/utils/Forks.sol";

/// DO_RUN=false DO_BUILD=false DO_DEPLOY=true DO_SIMULATE=false DO_PRINT=false DO_VALIDATE=true forge script src/proposals/sips/SIP_00.sol:SIP_00 -vvvv
contract SIP_00 is GovernorBravoProposal {
    using ForkSelector for uint256;

    constructor() {
        // ETHEREUM_FORK_ID.createForksAndSelect();
        primaryForkId = ETHEREUM_FORK_ID;
    }

    function name() public pure override returns (string memory) {
        return "SIP-00 System Deploy";
    }

    function description() public pure override returns (string memory) {
        return name();
    }

    function run() public override {
        ETHEREUM_FORK_ID.createForksAndSelect();
        
        string memory addressesFolderPath = "./addresses";
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 1;
        
        setAddresses(new Addresses(addressesFolderPath, chainIds));
        
        setGovernor(addresses.getAddress("COMPOUND_GOVERNOR_BRAVO"));
        
        super.run();
    }

    function deploy() public override {
        if (!addresses.isAddressSet("OZ_GOVERNOR_VAULT")) {
            address[] memory tokens = new address[](3);
            tokens[0] = addresses.getAddress("USDC");
            tokens[1] = addresses.getAddress("DAI");
            tokens[2] = addresses.getAddress("USDT");

            Vault vault = new Vault(tokens);

            addresses.addAddress("V1_VAULT", address(vault), true);
        }
    }

    function validate() public view override {
        Vault vault = Vault(addresses.getAddress("V1_VAULT"));

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
    }
}