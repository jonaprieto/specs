# Mempool

## Summary
Validators run the mempool protocol. 
They receive transactions from clients, store them, and make them available for the [execution engine](execution.md) to read. 
The mempool protocol also produces a DAG of *headers*, which reference batches of transactions (via hash), and prove that those transactions are available for the [execution engine](execution.md). 
These headers are ultimately what the [consensus](heterogeneous_paxos.md) decides on, in order to establish a total order of transactions.
