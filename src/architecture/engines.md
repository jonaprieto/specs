# Engines

Anoma's implementation is structured as a set of communication _engines_. An _engine_ can be understood as a deterministic logical process operating within a trusted domain, and can be characterised as a function, parameterised over a state type, input message type, and output message type, taking a tuple of the current state and a set of input messages, and returning a tuple of a new state and a set of output messages. 

```haskell
type Engine State InMsg OutMsg = (State, Set InMsg) -> (State, Set OutMsg)
```

This interface is _compositional_, where two engines can be combined by routing specific messages to and from each other, to form a third engine which is a specific composition of the two.

> TODO: Specify this further.

Structuring the implementation as a composition of engines has many benefits:
- A clean separation of concerns between different areas of concern in the protocol (e.g. network layer interfacing, consensus message processing, signature generation).
- Easier upgrades, as engine implementations can be independently upgraded as long as interface properties (at the level of the engine function as above) are still satisfied.
- The possibility of hot reloading. Typiucally, engines can be hot reloaded as long as interface properties are still satisfied and state is appropriately transferred - messages are just queued.
- Different engines can be property tested and formally verified independently, since they have independently articulated properties. Testing and verification of engine compositions can build on these efforts.
- A natural mapping to separate physical processors or machines. Engines are assumed to operate within a single trust domain, but can otherwise be separated and run in parallel, in the form of separate cores on the same physical machine, multiple physical machines across a network boundary, etc.

Important notes:
- Engines are _logical_ processes, not physical ones. Any mapping of logical to physical processes is possible as long as the logical properties are adhered to.

Engines:
- [P2P](./engines/p2p.md)
- [Mempool](./engines/mempool.md)
- [Consensus](./engines/consensus.md)
- [Execution](./engines/execution.md)
- [Storage](./engines/storage.md)
- [Compute](./engines/compute.md)
- [Solver](./engines/solver.md)
- [Identity](./engines/identity.md)
- [Strategy synthesis](./engines/strategy-synthesis.md)
- [Interaction](./engines/interaction.md)