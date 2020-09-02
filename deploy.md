Deploying the Koinos ERC20 Mining contract via OpenZeppelin is fairly straight forward using their command line tooling.

Install the OpenZeppelin CLI via node:

```
$ npm install @openzeppelin/cli
```

This guide assumes you are running a local testnet, listening on port 8545. OpenZeppelin CLI will refer to this network as `development`.

More networks, such as a public testnet or the Ethereum mainnet can be added to `network.js`.

There are two distinct contracts that need to be uploaded to support the Koinos ERC 20 Mining, `KnsToken` and `KnsTokenMining`.

First, we will upload both contracts using `npx oz deploy`.

``` 
$ npx oz deploy
✓ Compiled contracts with solc 0.6.7 (commit.b8d736ae)
? Choose the kind of deployment regular
? Pick a network development
? Pick a contract to deploy KnsToken
? name: string: Test Koinos
? symbol: string: TEST.KNS
? minter: address: 0x0000000000000000000000000000000000000000
✓ Deployed instance of KnsToken
0xDb5a94a049395Ac047aE3849107071691B545b43
```

When deploying `KnsTokenMining`, we will use the contract address returned when deploying `KnsToken` as the token address for `KnsTokenMining`. In this case it is `0x68D3aD02f4496AEE69AD65578265f809e0E87319`.
The start time is epoch seconds. Choose a reasonable time based on your needs.

```
$ npx oz deploy
Nothing to compile, all contracts are up to date.
? Choose the kind of deployment regular
? Pick a network development
? Pick a contract to deploy KnsTokenMining
? tok: address: 0xDb5a94a049395Ac047aE3849107071691B545b43
? start_t: uint256: 1598465000
? start_hc_reserve: uint256: 1000
? testing: bool: false
✓ Deployed instance of KnsTokenMining
0x4F744bAEE596D8F47d39a7AeEa93E882F4CBBD6b
```

We need to set `KnsTokenMining` as a minter of `KnsToken`. We will need to grab a constant, `MINTER_ROLE` from `KnsToken`.

```
$ npx oz call
? Pick a network development
? Pick an instance KnsToken at 0xDb5a94a049395Ac047aE3849107071691B545b43
? Select which function MINTER_ROLE()
✓ Method 'MINTER_ROLE()' returned: 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
```

Finally, we create a transaction that sets `KnsTokenMining` as a minter of `KnsToken`.

```
$ npx oz send-tx
? Pick a network development
? Pick an instance KnsToken at 0xDb5a94a049395Ac047aE3849107071691B545b43
? Select which function grantRole(role: bytes32, account: address)
? role: bytes32: 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
? account: address: 0x4F744bAEE596D8F47d39a7AeEa93E882F4CBBD6b
✓ Transaction successful. Transaction hash: 0x9b081a4c27b3c6884427fed1d69edc9a90dc0117e4da6f46675b5b0ba886e02f
Events emitted:
 - RoleGranted(0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6, 0x4F744bAEE596D8F47d39a7AeEa93E882F4CBBD6b, 0x8bb871Ec7dA3BC0b9E25A87F7c7B86E0eF1d11a1)
```
