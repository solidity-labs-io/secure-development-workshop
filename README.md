# Secure Development Workshop

This workshop will walk you through the basics of securing smart contracts by testing your deployment scripts and governance proposals. We will be using the [forge proposal simulator](https://github.com/solidity-labs-io/forge-proposal-simulator) to make this process easier.

## Overview

In this workshop we will be protecting a governance heavy application from the consequences of malicious upgrades and or deployment scripts.

## Bug Types
- **Deployment** - Incorrect parameters, caught with a validation
- **Deployment** - Incorrect parameters, caught with an integration test
****
- **Upgrade** - Storage offset changes, caught with an integration test, also caught with a validation
- **Upgrade** - Logic error, caught with an integration test
****
- **New contract** - Logic error, caught with formal verification
- **New contract** - Vulnerable to DoS vector, caught with static analysis
- **New contract** - Vulnerable to arbitrary calldata and targets, caught with static analysis

### Further Reading

For governance safety assistance, refer to our [forge proposal simulator](https://github.com/solidity-labs-io/forge-proposal-simulator) tool. See the [security checklist](https://github.com/solidity-labs-io/code-review-checklist) and [security](https://medium.com/@elliotfriedman3/a-security-stack-4aedd8617e8b) [stack](https://medium.com/@elliotfriedman3/a-security-stack-part-2-aaacbbf77346) for a list of items to consider when building a smart contract system.

## Environment Setup

Set the `ETH_RPC_URL` environment variable to the URL of an Ethereum node. For example, to use the Alchemy mainnet node, run: 

```bash
export ETH_RPC_URL=https://eth-mainnet.alchemyapi.io/v2/your-api-key
```

Make sure the latest version of foundry is installed. If not, run:

```bash
foundryup
```

Later exercises will use the certora prover. If you need to install, first check the system prerequisites from the Certora documentation. https://docs.certora.com/en/latest/docs/user-guide/install.html

To install the prover run:

```bash
pip3 install certora-cli
```
