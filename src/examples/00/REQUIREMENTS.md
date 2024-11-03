# Overview

The business team needs a simple contract that allows swapping between various different tokens of the same value. This is a peg stability module that allows users to deposit one asset, and withdraw another of the same value. It does not use chainlink and assumes price parity of all assets. There are no swap fees, and LP deposit then withdraw to swap.

Create a contract that allows users to deposit any of the supported tokens, and withdraw any of the supported tokens.

User balances should be tracked, a user's balance should go up when they deposit a token and go down when they withdraw a token. A user should only be able to withdraw up to the amount of tokens they have deposited.