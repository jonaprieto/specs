# Typhon

## Summary
Typhon stores, orders, and executes transactions on Anoma blockchains. 
It can be broken down into (roughly) 3 layers: 
- a [mempool](typhon/mempool.md), which stores received transactions
- a [consensus](typhon/heterogeneous_paxos.md), which orders transactions stored by the mempool, and
- an [execution engine](typhon/execution.md), which executes the transactions on the state machine.
![layer diagram](typhon/layers_web.svg)
