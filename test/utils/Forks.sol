pragma solidity ^0.8.0;

import {Vm} from "@forge-std/Vm.sol";

uint256 constant ETHEREUM_FORK_ID = 0;

library ForkSelector {
    Vm internal constant vmContract =
        Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function createForksAndSelect(uint256 selectFork) internal {
        (bool success,) = address(vmContract).call(
            abi.encodeWithSignature("activeFork()")
        );
        (bool successSwitchFork,) = address(vmContract).call(
            abi.encodeWithSignature("selectFork(uint256)", selectFork)
        );

        if (!successSwitchFork || !success) {
            vmContract.createSelectFork("ethereum");
        } else {
            vmContract.selectFork(selectFork);
        }
    }
}
