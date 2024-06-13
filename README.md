# Equito EVM Contracts

Equito is a cutting-edge cross-chain messaging protocol designed to facilitate seamless, secure, and efficient communication across diverse blockchain networks. As a gateway for interoperability, Equito empowers developers to extend the functionality of decentralized applications (dApps) beyond the constraints of single blockchains.

This repository provides the smart contracts required for EVM-compatible networks to interact with the Equito cross-chain messaging protocol.

## Key Components

- **Router**, which handles message sending and receiving. Equito Validators listen to events emitted by Routers and perform consensus operations to generate proofs for cross-chain messages validation.
- **EquitoApp**, which abstracts interaction with the Router and other standard practices to simplify the development of cross-chain applications. Under the hood, it implements the **IEquitoReceiver** interface to handle incoming messages.
- **ECDSAVerifier**, which verifies ECDSA signatures produced by the Equito Validators for individual and batched cross-chain messages. Under the hood, this contract implements **IEquitoVerifier** that provides a standard interface for signature verification, and **IEquitoFees**, used to calculate fees for sending a cross-chain message.

## Examples

The `examples` directory contains:
- **PingPong**, featured in the [Build my first Equito App]() tutorial, demonstrates how to send and receive messages using Equito.
- **CrossChainSwap**, a simple implementation of a cross-chain swap between two networks, demonstrating how to send and receive messages using Equito.

## Tests & Scripts

In addition to the contracts, this repository includes tests to ensure their correct functionality, and scripts to simplify the deployment and interaction with the contracts.
