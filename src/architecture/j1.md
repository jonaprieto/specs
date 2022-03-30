# J1

A verifiable protocol design language *should*:

1. Abstract complexity properly so that complex programs can be written and reasoned about (by the programmer).

   *This isn't too tall an order - Rust, Haskell, etc. do a fine job at this - but e.g. Solidity fails. See [this paper](https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf) for a more detailed discussion.*

2. Allow for the expression of compact (constant-size) invariants (properties) against which the correctness of a much longer algorithm (any computable size) can be automatically checked (perhaps with a programmer-crafted proof). This verification should be composable, so that properties checked against lower-level algorithms can be used in proofs of properties of higher-level algorithms using the lower-level algorithms as components.

   *A whole discipline of existing research - dependently-typed programming - seems capable of fulfilling this requirement.*

3. Support multiple heterogeneous backends and execution environments so that applications can be written once in an integrated fashion and deployed to multiple parts in different execution models and environments.

   *Execution models such as WASM, ZK circuit, MPC circuit; execution environments such as Anoma VPs on multiple fractal instances, Near WASM, other chains.*

Right now, we have three layers:
- [Juvix](https://github.com/anoma/juvix).
- [Alucard](https://github.com/heliaxdev/alu).
- [Vampir](./j1/vampir/vampir.md).
