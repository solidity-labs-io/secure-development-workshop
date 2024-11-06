# Overview

Make the contract pauseable, while preserving all previous functionality. Users should not be able to deposit when the contract is paused. Users should be able to withdraw their liquidity when the contract is paused. Only the owner can pause and unpause the contract.

Then upgrade the existing contract's implementation to this new contract. This migration is forced, and users not wishing to stay for this new contract upgrade must withdraw their liquidity.
