# Logical DAGs

A _logical DAG_ is a DAG computed from a view (the partial information an agent has access to) corresponding to a particular message from the physical DAG according to a particular algorithm. To facilitate incremental verification and computation, logical DAGs are uniquely defined by their predicates. Different logical DAG predicates may guarantee additional structural properties (such as linearity, predicate validity, consensus w.r.t. an identity set, etc.) possibly subject to additional assumptions about the behaviour of particular agents. Logical DAG predicates are of type `PhysicalDAG -> t -> Bool` for some logical DAG type `t`, where a valid logical DAG for a particular physical DAG is any inhabitant of `t` such that the predicate holds. Generally, logical DAGs preserve partial ordering information from the physical DAG, in that if an event A occurred before an event B in the physical DAG, A must occur before B in any valid corresponding logical DAG.

> TODO: Specify this property (preservation of ordering structure)

Particular logical DAG algorithms, if their assumptions are met, generally guarantee that any two observers using that algorithm to compute or verify a logical DAG will not accept conflicting logical DAGs even if they have different partial information about the physical DAG (for definitions of "conflicting" which are specific to the logical DAG algorithm in question), and that these two observers will eventually compute isomorphic logical DAGs after receiving each other's physical DAG information (i.e. logical DAGs over the same subsets of a physical DAG are isomorphic w.r.t. to reordering of receipt of those subsets).

> TODO: Specify this property (eventual agreement, isomorphism w.r.t. reordering?)

## Transaction DAG

The most basic concept of a logical DAG is a `Transaction`, which is a blob of data atomically included or not included in a particular physical DAG (witnessed as `hash(tx bytes)`). From a view of the physical DAG which includes transactions, we can compute a logical DAG of those transactions (which are trivially atomically included or not included in the logical DAG) merely by filtering out all other witnesses:

```haskell
type TxDAG = DAG Bytes

validTxDAG :: PhysicalDAG -> TxDAG -> Bool
validTxDAG = subDAGBy isTransaction
```

The transaction DAG for a particular physical DAG is simply the DAG calculated by taking the partial ordering of all transactions referenced by the physical DAG and ignoring other messages (e.g. observations). The representation of the transaction graph as a logical DAG is fully distinct from the execution (interpretation of data within transactions), and is only used to determine which actions are possible, e.g. which resources are available, which paths are invalid because of still unresolved conflicts etc.

There may be many transaction types which do not need to care about each other, which could be identified by different prefix bytes or similar.

```haskell
```