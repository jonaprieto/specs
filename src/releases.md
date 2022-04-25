# Releases

In order to facilitate progressive deployment and iteration, the Anoma protocols are organised into a series of releases. Releases combine a selection of subcomponents of the Anoma protocols (which are themselves independently versioned) into a unified, compatible whole designed both to be architecturally self-contained and to provide a coherent product proposition.

Major release lines are defined by their product propositions - for example, once V1 is released, Heliax will continue to support, improve performance, and add features relevant to multi-asset shielded transfers, but features providing for a substantially different product proposition will be slated for other release lines. This method of organisation is not a position on how particular _instances_ of the Anoma protocols should evolve or upgrade, it is just a choice to cleanly separate different protocol version lines. Note, however, that the architectural capabilities of subsequent major version releases subsume previous ones - everything V1 can do, V2 can do as well - the version lines are a temporally scoped mode of organisation, Anoma is designed to converge to a singular suite of modular protocols.

At present, there are three major releases planned:

- [V1](./releases/v1.md): V1 provides for multi-asset shielded transfers, with assets from any connected chain sharing the same anonymity set, on top of a basic proof-of-stake Tendermint BFT stack.
- [V2](./releases/v2.md): V2 provides for programmable private bartering, counterparty discovery, and settlement, all on top of a bespoke heterogenous consensus system.
- [V3](./releases/v3.md): V3 provides for explicit information flow control and multiparty private state transitions.
