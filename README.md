## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

## Running a Local Testnet

Start a local instance of Sepolia in a separate terminal:

```shell
./test/anvil/start-sepolia-local.sh
```

Start a local instance of BNB in a separate terminal:

```shell
./test/anvil/start-bnb-local.sh
```

Start polygon local chain in a separate terminal:

```shell
./test/anvil/start-polygon-local.sh
```

Last step, start deploying router on each chain.

```shell
./test/anvil/deploy-router.sh
```
