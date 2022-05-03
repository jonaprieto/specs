# Execution Engine
## Summary
Given a total order (from the [consensus](heterogeneous_paxos.md)) of transactions (from the [mempool](mempool.md)), the execution engine updates and stores the "current" state of the virtual machine, using as much concurrency as possible. 
Proofs from the execution engine allow light clients to read the current state.
When the execution engine has finished with a transaction, it communicates to the [mempool](mempool.md) that the transaction can be garbage-collected from storage. 
