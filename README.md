# Koinos Token Mining

The initial distribution of the Koinos Mainnet Token (KOIN) will be determined via a public mining contract on Ethereum.

The Proof of Work algorithm is a memory hard generalized birthday problem.

Each client will populate a list keccak-256 hashes (deemed the word list), generated from a recent Ethereum block hash. This word list is shared among all miners.

Each miner also provides a destination address, pow height, desired difficulty, and nonce. The address and pow height are a unique tuple for each proof. Because of this, each miner is competing only against themselves. (i.e. there are no race conditions between miners that can invalidate a proof)

The hash of the destination address, recent Ethereum block hash, corresponding block number, pow height, difficulty, and nonce is an input in to a function that generates psuedo random numbers as indices into the word list.

Each word at those indices is XORed along with the hash to provide the result of the work.

A valid proof is any whose work is less than the desired difficulty that was an input in to the original hash.

As there is no contention for block production, each miner can choose their own difficulty. The mining contract tracks tokens to mint via an xyk market maker. When proofs are submitted, they are credited with expected hashes and submitted to the market maker to determine the reward for the proof. Over time, tokens are added to the market maker, reducing the cost (in hashes) of purchasing the tokens, while increased competition will increase the price of purchasing tokens.

## Upgrade Policy

The mining contract we are deploying will not be upgradable. Only in the case of a catastrophic event, such as undermining property rights or completely trivializing the mining algorithm such that it is not longer competitive, will we consider an upgrade via a relaunch of the mining contract and token. In such a scenario will make a best effort to determine the time of the event and share drop on legitimately mined koins prior to the event.

If the mining and distribution algorithms do not act exactly as expected, but are behaving according to the intended implementation, the contract will not be upgraded.

GPU/FPGA/ASIC resistance is best effort, but not guaranteed.
