# Execution Engine
## Summary
Given a total order (from the [consensus](heterogeneous_paxos.md)) of transactions (from the [mempool](mempool.md)), the execution engine updates and stores the "current" state of the virtual machine, using as much concurrency as possible. 
Proofs from the execution engine allow light clients to read the current state.
When the execution engine has finished with a transaction, it communicates to the [mempool](mempool.md) that the transaction can be garbage-collected from storage. 


## Vocabulary
- *Shards* are processes that store and update state.
  - Different shards may be on different machines. Redistributing state between shards is called *Re-Sharding*.
  - Each Shard is specific to 1 learner.
    However, as an optimization, an implementation could conceivably use 1 process to do the work of 2 shards with different learners so long as those shards are identical, and fork that process if / when the learners diverge. 

- *Executors* are processes that actually run the VM and compute updates. Executors should probably be co-located with shards. 

Either:
- We assume the [Mempool](mempool.md) is using the Heterogeneous Narwhal setup?
  - In which case *Consensus* picks leaders in the DAG
- [Mempool](mempool.md) is treated as some kind of black-box set of processes that can each transmit transactions to Shards. 
  - In which case *Consensus* produces more detailed ordering information
Perhaps we should have some general notion of *Timestamp* on transactions?

The *VM* is largely a black box: we assume we can give it a set of input key-value pairs and a transaction, and get output key-value pairs. 

## State
State is stored as mutable *Values* (unlimited size blobs of binary), each of which is identified with an immutable *Key*.
If you want to mutate a Key associated with a specific Value, that's equivalent to deleting the Value associated with the old Key, and writing it to the new Key. 
Keys that have never had a Value written to them are mapped to an empty value. 

For each Learner, all processes can map Transactions to a set of Shards whose state they read, and a set of shards whose state they write.
This makes Re-Sharding challenging. 

$$
read(L : Learner, T : Transaction) : Set[Shard]
$$
$$
write(L : Learner, T : Transaction) : Set[Shard]
$$

One way to implement this is to *partition* the space of Keys across Shards, and *Label* each Transaction with a *Sub-Space* of keys it touches. 
One possible Key-space would be to arrange *Keys* in some kind of a tree configuration.

## Mempool Interface
We assume, for each Learner, that each transaction has a unique Executor:
$$
executor(L : Learner, T : Transaction) : Executor
$$
It would be more efficient if $executor(L, T)$ is co-located with a shard in $write(L, T)$ or $read(L, T)$.
As an optimization, we can have one process do the work of multiple learners' executors, so long as those learners are identical. 

We assume that each transaction carries a timestamp:
$$
timestamp(T : Transaction) : Timestamp
$$
We assume that these timestamps have an *unknown* total order, and that Consensus and the Mempool can update Shards' knowledge of this total order. 
In particular, we assume that Consensus informs shards of an ever-growing prefix of this total order. 
- One way to accomplish this is simply to have each timestamp be the hash of the transaction, and have consensus stream a totally ordered list of all hashes included in the chain to all Shards. This may not be very efficient. 
- We could instead consider one timestamp to be definitely *after* another if it is a descendent in the Narwhal DAG. Narwhal workers could transmit DAG information to Shards, and shards would learn some partial ordering information before hearing from Consensus. Consensus could then transmit only the Narwhal blocks it decides on, and shards could determine a total ordering from there. 

The Mempool transmits each transaction to its executor as soon as possible, using network primitives. 
The for each transaction $T$ that reads or writes state on shard $S$, the Mempool *also* transmits to shard $S$:
$$
shardSummary(T) := \left\langle
\begin{array}{l}
 \textrm{the Hash of }T
\\ timestamp(T)
\\ \textrm{the sub-space of keys on }S\textrm{ that }T\textrm{ reads}
\\ \textrm{the sub-space of keys on }S\textrm{ that }T\textrm{ writes}
\end{array}
\right\rangle
$$


We assume that each Shard maintains Timestamps bound below which it will no longer receive new transactions.
Specifically, a timestamp below which it will no longer receive new transactions that read from its state, and a timestamp below which it will no longer receive new transactions that write to its state. 
$$
heardAllRead(S : Shard) : Timestamp
$$
$$
heardAllWrite(S : Shard) : Timestamp
$$
Generally, we expect that $heardAllWrite(S) > heardAllRead(S)$, but I don't know that we require this to be true. 
It should update this bound based on information from the Mempool. 
For example, it could maintain partial bounds from each mempool worker (updated whenever that mempool worker sends the Shard a message), and implement $heardAllRead$ and $heardAllWrite$ as the greatest lower bound of all the partial bounds. 


## Consensus Interface
Consensus needs to update each Shard's knowledge of the total order of timestamps. 
In particular, we assume that Consensus informs shards of an ever-growing prefix of this total order. 
- One way to accomplish this is simply to have each timestamp be the hash of the transaction, and have consensus stream a totally ordered list of all hashes included in the chain to all Shards. This may not be very efficient. 
- We could instead consider one timestamp to be definitely *after* another if it is a descendent in the Narwhal DAG. Narwhal workers could transmit DAG information to Shards, and shards would learn some partial ordering information before hearing from Consensus. Consensus could then transmit only the Narwhal blocks it decides on, and shards could determine a total ordering from there. 

## Execution
For each learner $L$, for each Transaction $T$, executors wait to receive values for all keys in $read(L, T)$, then compute the transaction, and transmit to each shard $S$ any value stored on $S$ in $write(L, T)$.

Generally, transactions do not have side effects outside of state writes. However, we could in principle encode client reads as read-only transactions whose side-effect is sending a message, or allow for VMs with other side effects. 

Executors can save themselves some communication if they're co-located with Shards. 
As an optimization, we can save on communication by combining messages for multiple learners if their content is identical and their shards are co-located. 
Likewise, we can save on computation by using one process to execute for multiple learners so long as they are identical. 

## State Updates
For each key in its state, each shard $S$ needs to establish a total order of all writes between $heardAllRead(S)$ and $heardAllWrite(S)$. 
Reads to each key need to be ordered with respect to writes to that key. 

To accomplish this, each Shard $S$ maintains a *Dependency Multi-Graph* of all Shard Summaries they have received, where Summary $T_1$ *depends on* Summary $T_2$ if the Shard doesn't know that $timestamp(T_1) < timestamp(T_2)$, and $T_1$ can read from a key to which $T_2$ can write. 
Specifically, if the Shard doesn't know that $timestamp(T_1) < timestamp(T_2)$, then for each key $K$ that $T_2$ can write to and $T_1$ can read or write, create an edge labeled with $\langle T_2, K \rangle$.
There can be cycles in the dependency multi-graph, but these will resolve as the Shard learns more about the total order from consensus. 

Concurrently, for any Summary $T$ that no longer depends on any other Summary, if $timestamp(T) < heardAllWrite(S)$:
- transmit the values written most recently before $timestamp(T)$ for any key on $S$ in $read(learner(S), T)$ to $executor(learner(S), T)$
- upon receiving the values for any key $K$ on $S$ in $write(learner(S), T)$ from $executor(learner(S), T)$:
  - record that that value is written to key $K$ at $timestamp(T)$.
  - delete edges labeled $\langle T, K\rangle$ from the dependency graph.
  - As an optimization, we may want a compact "don't change this value" message. 
- When every value in $write(learner(S), T)$ has been updated, delete $T$ from the dependency graph. 

Note that read-only transactions can arrive with timestamps before $heardAllWrite(S)$. 
These need to be added to the dependency graph and processed just like all other transactions. 

## Garbage Collection
Each Shard can delete all but the most recent value written to each key before $heardAllRead(S)$. 

Once all of a transaction's Executors (for all learners) have executed the transaction, we can garbage collect it. 
We no longer need to store that transaction anywhere. 

## Client Reads
Read-only transactions can, in principle, bypass Mempool and Consensus altogether: they only need to arrive at each of the relevant shards $S$, and have a timestamp greater than $heardAllRead(S)$. 
They could also be executed with a side effect, like sending a message to a client. 

We can use these read-only transactions to construct checkpoints: Merkle roots of portions of state, building up to a Merkle root of the entire state. 

Light client reads only need some kind of signed message produced by an executor from each of a weak quorum of validators. 
They do not, technically, need a Merkle root of the entire state at all.
However, it may be more efficient to get a single signed message with a Merkle root of state, and then only one Validator needs to do the read-only transaction. 
To support this kind of thing, we may want $heardAllRead$ to lag well behind $heardAllWrite$, so we can do reads on recent checkpoints. 
