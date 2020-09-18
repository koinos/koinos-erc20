Deploying the Koinos ERC20 Mining contract via OpenZeppelin is fairly straight forward using their command line tooling.

Install the OpenZeppelin CLI via node:

```
$ npm install @openzeppelin/cli
```

This guide assumes you are running a local testnet, listening on port 8545. OpenZeppelin CLI will refer to this network as `development`.

## Ropsten

The provided `network.js` also has Ropsten running locally on port 8545. Obviously both Ropsten and Ganache cannot be accessible on the same port. Modify `network.js` to suite your development needs.

We will use `dotenv` to store a mnemonic phrase for dev key management.

Use `npx nmemonic` to generate a 12 word seed phrase and put it in `.env`

```
DEV_MNEMONIC="your twelve word seed phrase goes here"
```

You will also need `truffle-hdwallet-provider`. Install it as a dev dependency.

```
$ npm install --save-dev truffle-hdwallet-provider
```

You can get the address associated with the mnemonic using OpenZeppelin.

```
$ npx oz accounts
? Pick a network ropsten
Accounts for ropsten:
Default: 0x3884b0d00B71Cb190b5b112eC2f6d136c20404eE
All:
- 0: 0x3884b0d00B71Cb190b5b112eC2f6d136c20404eE
```

Fund this account using a testnet faucet and then follow the deployment instruction below.

We had success using https://faucet.dimensions.network/

## Deployment

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

We need to set `KnsTokenMining` as a minter of `KnsToken`.

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

Finally, we need to enable a snapshotter. This address will be able to trigger a snapshot after the mining is complete.
This constant can be grabbed from `KnsToken` similarly to `MINTER_ROLE`.

```
$ npx oz call
? Pick a network development
? Pick an instance KnsToken at 0xDb5a94a049395Ac047aE3849107071691B545b43
? Select which function SNAPSHOTTER_ROLE()
✓ Method 'SNAPSHOTTER_ROLE()' returned: 0x1aa1fd5f7b0f7c50bfda2b3788dca5be0ff1c53a5be56745dadbd234c0ff987c
0x1aa1fd5f7b0f7c50bfda2b3788dca5be0ff1c53a5be56745dadbd234c0ff987c
```

```
$ npx oz send-tx
? Pick a network development
? Pick an instance KnsToken at 0xDb5a94a049395Ac047aE3849107071691B545b43
? Select which function grantRole(role: bytes32, account: address)
? role: bytes32: 0x1aa1fd5f7b0f7c50bfda2b3788dca5be0ff1c53a5be56745dadbd234c0ff987c
? account: address: 0xad23cfB4c183D3DaAB649DC18AcAe7a424Da67D3
✓ Transaction successful. Transaction hash: 0xb022acdc06f985ed4d1a18f38a77fa03cefdfaf10fc765924c9d60f0237fe570
Events emitted:
 - RoleGranted(0x1aa1fd5f7b0f7c50bfda2b3788dca5be0ff1c53a5be56745dadbd234c0ff987c, 0xad23cfB4c183D3DaAB649DC18AcAe7a424Da67D3, 0xad23cfB4c183D3DaAB649DC18AcAe7a424Da67D3)
```
