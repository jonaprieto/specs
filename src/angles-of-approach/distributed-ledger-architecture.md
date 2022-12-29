# Blockchain systems architecture

vis-a-vis cosmos/ibc

- rollups: rollups-on-demand
- cosmos/ibc: state not tied to instances in the same way, consensus provision separate from application logic, automatic resolution of cross-instance state
- fractal scaling - implementation of all n layers
- mesh security - scale-free implementation architecture

 We unify the privacy-preserving double-spend prevention technique of Zerocash/Zexe/Taiga - nullifiers, uniquely binding to note commitments, unlinkable and calculable with secret information - with the double-spend prevention required of distributed database systems / blockchains (preventing multiple valid conflicting descendents of the same block), recasting the mechanism as a distributed enforcement system for a linear resource logic.

 - We unify various concepts of state-machine-level cryptographic identity -- public-key-based accounts, smart-contract accounts, BFT light clients, threshold keys -- and network-level cryptographic identity into a singular information-theoretic duality of _external identity_ and _internal identity_, the fundamental abstraction on top of which the protocol is built.
- We unify the concepts of _message_ and _state_, in that each message commits to its own history, and that there is no state other than can be computed from a set of messages at a particular point in partially-ordered logical time.

