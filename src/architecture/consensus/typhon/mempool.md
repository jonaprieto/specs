# Mempool

## Summary
Validators run the mempool protocol. 
They receive transactions from clients, store them, and make them available for the [execution engine](execution.md) to read. 
The mempool protocol, which is based on [Narwhal](https://arxiv.org/abs/2105.11827) also produces a [DAG](https://en.wikipedia.org/wiki/Directed_acyclic_graph) of *headers*, which reference batches of transactions (via hash), and prove that those transactions are available for the [execution engine](execution.md). 
These headers are ultimately what the [consensus](heterogeneous_paxos.md) decides on, in order to establish a total order of transactions.

## Heterogeneous Narwhal
The core idea here is that we run an instance of Narwhal for each learner. 
For chimera chains, an "atomic batch" of transactions can be stored in any involved learner's Narwhal. 

We also make 2 key changes:
- The availability proofs must show that any transaction is sufficiently available for all learners. 
This should not be a problem, since in Heterogeneous Paxos, for any connected learner graph, any learner's quorum is a weak quorum for all learners. 
- Whenever a validator's Narwhal primary produces a batch, it must link in that batch not only to a quorum of that learner's block headers from the prior round, but also to the most recent batch this validator has produced *for any learner*. 
This ensures that, within a finite number of rounds (3, I think), any transaction batch referenced by a weak quorum of batches in its own Narwhal will be (transitively) referenced by all batches in all Narwhals for entangled learners. 


