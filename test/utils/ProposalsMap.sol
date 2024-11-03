// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {Script, stdJson} from "@forge-std/Script.sol";

import {Proposal} from "@proposals/Proposal.sol";

contract ProposalsMap is Script {
    using stdJson for string;

    struct ProposalFields {
        uint256 id;
        string path;
    }

    ProposalFields[] public proposals;

    mapping(uint256 id => uint256) private proposalIdToIndex;

    mapping(string path => uint256) private proposalPathToIndex;

    constructor() {
        string memory data = vm.readFile(
            string(
                abi.encodePacked(
                    vm.projectRoot(), "/src/proposals/sips/sips.json"
                )
            )
        );

        bytes memory parsedJson = vm.parseJson(data);

        ProposalFields[] memory jsonProposals =
            abi.decode(parsedJson, (ProposalFields[]));

        for (uint256 i = 0; i < jsonProposals.length; i++) {
            addProposal(jsonProposals[i]);
        }
    }

    function addProposal(ProposalFields memory proposal) public {
        uint256 index = proposals.length;

        proposals.push();

        proposals[index].id = proposal.id;
        proposals[index].path = proposal.path;

        proposalIdToIndex[proposal.id] = index + 1;
        proposalPathToIndex[proposal.path] = index;
    }

    function getProposalById(uint256 id)
        public
        view
        returns (string memory path)
    {
        if (proposalIdToIndex[id] == 0) {
            return "";
        }

        ProposalFields memory proposal = proposals[proposalIdToIndex[id] - 1];
        return proposal.path;
    }

    function getProposalByPath(string memory path)
        public
        view
        returns (uint256 proposalId)
    {
        ProposalFields memory proposal = proposals[proposalPathToIndex[path]];
        return proposal.id;
    }

    function getAllProposalsInDevelopment()
        public
        view
        returns (ProposalFields[] memory _proposals)
    {
        // filter proposals with id == 0;
        uint256 count = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].id == 0) {
                count++;
            }
        }

        _proposals = new ProposalFields[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].id == 0) {
                _proposals[index] = proposals[i];
                index++;
            }
        }
    }

    function runProposal(Addresses addresses, string memory proposalPath)
        public
        returns (Proposal proposal)
    {
        proposal = Proposal(deployCode(proposalPath));
        vm.makePersistent(address(proposal));

        vm.selectFork(proposal.primaryForkId());

        address deployer = address(proposal);
        proposal.initProposal(addresses);
        proposal.deploy(addresses, deployer);
        proposal.afterDeploy(addresses, deployer);
        proposal.build(addresses);
        proposal.teardown(addresses, deployer);
        proposal.run(addresses, deployer);
        proposal.validate(addresses, deployer);
    }
}
