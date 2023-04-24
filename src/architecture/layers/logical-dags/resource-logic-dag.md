# Resource logic DAG

> DISCLAIMER: This section now contains redundancies with the `Resources` section, as well as being outdated. A refactoring is in progress to reconcile both sections.

The resource logic DAG provides an abstraction of a _linear resource logic_ with which distributed applications can model finite objects. This logic is based on a concept of a _resource_, which is a unique datum created at a particular point in logical time and possibly consumed later in logical time. Each resource is an instance of a particular _resource logic_, which specifies how (under what conditions) resources of that type can be created and consumed. The resource logic DAG tracks when resources are created and when they are consumed. Resources are only allowed to be consumed after they have been created.  At any point in logical time, the resource logic DAG has a state consisting of all resources which have been created but not consumed. 

The resource logic DAG also tracks linear logic violations (duplicate consumptions of the same resource, or "double spends"). Each resource has an ordered list of controller identities, where a valid signature from the last identity in the list is required to consume the resource. At any point in logical time, the latest (right-most) controller of a resource is responsible for ordering possibly conflicting transactions. Resources can be transferred to a new controller (modulo additional validation in the predicates) by appending to the list, or as a special case, they can be transferred to the previous controller (dropping an item from the end of the list). In the case of a double-spend of a resource - namely, a non-total order of two conflicting transactions both signed by the current controller - the conflict is resolved by the controller one element earlier in the list when the resource is eventually transferred back, and in the case of multiple double-spends recursively until the originator (at which point, if they also double-spend, linearity is violated, but as if the originator had just issued more resources, and in any case there is no in-system recovery possible at this point). Controller identies can be defined in particular ways which encode bespoke conflict resolution logic. Recovery from linearity violations does not require any reversal or reordering of transactions, as we keep this explicit "chain of promises" of controllers, so if some controller `I` double-spends, subsequent resources with `I` in the controller list may simply no longer be redeemable back along the original path. By accepting resources with a particular path of controllers, an application or user accepts the double-spend risk of any of the controllers, which can be mitigated by waiting for those controllers to sign over the transaction (which finalises it and guarantees future redemption from their perspective).

## Resource logics

Resource types are defined by a particular `ResourceLogic`, which specifies under what conditions resources of that type can be created and consumed. The `creationPredicate` describes under which conditions a resource can be created. For a fungible token, for example, new tokens may be created with a valid signature from the issuing identity. The `consumptionPredicate` describes under which conditions a resource can be consumed. For a fungible token, for example, tokens may be spent with a valid signature from the identity which currently owns the tokens.

These predicates have access only to data in the transaction itself. The transaction may include arbitrary data in the extradata field such as proofs or signatures, to which the predicates have access, but they do not have access to the physical DAG in which the transaction is included. 

```haskell=
data ResourceLogic = ResourceLogic {
  creationPredicate :: TxData -> Bool,
  consumptionPredicate :: TxData -> Bool,
}
```

> TODO: It should be possible to simplify this to just one predicate (which could be split into two for optimisation or privacy reasons as an implementation choice).

## Resources

A `Resource` is a unique datum controlled by a particular resource logic. Resources include a reference to their `logic`, an application-defined `suffix` field, a list of `controllers` (external identities), an arbitrary `data` field, and a `value` natural number used to model relative weight for fungible resources.

- The `logic` is a hash commitment to the pair of creation and consumption predicates (as above) defining under what conditions the resource can be created and under what conditions the resource can be consumed.
- The `controllers` is the ordered list of resource controllers, with the originator first and most recent controller last. This list must be non-empty, except in the case of an internal resource, in which case it must be empty.
- The `suffix` is a key suffix used to distinguish between distinct-but-equal resources (e.g. same logic, same prefix, same value, but distinct suffix). Semantics of the `suffix` semantics are enforced by the resource logic (e.g. for application internal prefixing by resource controllers, with suffixes addressing individual resources).
- The `data` is an arbitrary bytestring which can be interpreted by the predicates (it could itself contain other predicates, identities, etc.).
- The `value` is a natural number (non-negative integer). This resource logic model builds in a notion of fungibility, i.e. two resources with the same logic `l` and controllers `[cs]`, different suffixes, and values `a` and `b` are treated as equivalent to one resource with logic `l`, controllers `[cs]` and value `c` iff. `c = a + b`.

```haskell=
data Resource = Resource {
  logic :: Hash,
  controllers :: [ExternalIdentity],
  suffix :: ByteString,
  data :: ByteString,
  value :: Natural
}

type Key = ByteString

key :: Resource -> Key
key r = logic r <> domainSeparator <> controllers r <> domainSeparator <> suffix r
```

The `key` of a resource is computable from the logic, controllers, and suffix. As we will see later, the _state_ of the resource logic DAG at a point in logical time can be represented as a mapping from `key` to `(data, value)` of all resources which have been created but not consumed at that point in logical time.

## Transactions

A _transaction_ in a resource logic DAG consumes a (possibly empty) set of existing resources and creates a (possibly empty) set of new resources. Transactions are atomic, in that either the whole transaction is valid (and can be appended to / part of a valid resource logic DAG), or the transaction is not valid and cannot be appended to / included in the resource logic DAG. Transactions include:

Transactions have the following fields:

- The set of `created` resources are resources which this transaction creates.
- The set of `consumed` resources are hashes of resources which this transaction consumes.
- The sets of `createdInternal` and `consumedInternal` resources are resources for partial application and constraint forwarding.
- The `extradata` field is for additional data which may be meaningful to predicates in resource logics (e.g. signatures). It is not otherwise processed by the resource logic DAG itself.

Internal resources are used as they are in Taiga, for constraint forwarding.

> TODO: Describe this in detail, particularly the structural correspondence (should be) to partially applied functions.

```haskell
data Transaction
  = Transaction {
    created :: Set Resource,
    consumed :: Set Hash,
    createdInternal :: Set Resource,
    consumedInternal :: Set Hash
    extradata :: Map ByteString ByteString
  }
```

A transaction is _balanced_ if and only if:
- the sum of values of all input resources with key `k` equals the sum of values of all output resources with key `k`, for each unique `k` in the union of the keys of input and output resources, for both permanent resources and internal resources

A transaction is _valid_ if and only if:
- the consumption predicates of all the resources consumed by the transaction are satisfied (both internal and permanent)
- the creation predicates of all the resources created by the transaction are satisfied (both internal and permanent)

A transaction is _consistent_ w.r.t. a physical DAG `D` if and only if:
- all consumed resources were previously created by a transaction in the history, which was itself (recursively) consistent and final

A transaction is _final_ w.r.t. a physical DAG `D` if and only if:
- it is balanced and valid
- it is consistent w.r.t. `D`
- the latest owners of all consumed resources have signed over it in `D`
- all consumed resources have not been consumed by another antecedent transaction in `D` which was itself final

In the case of two _conflicting_ transactions, where the rightmost controller(s) `c` did not totally order them, resolution is defined as
- the transaction ordered first by the rightmost controller after dropping the last element of the list, or in case of another conflict (by them), drop the last element of the list and repeat. if the end of the list is reached, both transactions are valid (this may violate linearity guarantees), and we rely on some sort of out-of-band fault resolution

Agents, then, have _safe finality_ under the assumption of correct behaviour of the leftmost controller from whom they have obtained a signature.

## Delayed execution transactions

Transactions may want to choose their exact input and output resources on the basis of the state just prior to application of the transaction to the state (when it is "executed", or so to speak), in order to, for example, read the most current resource at a particular (known) key and thus avoid conflicts. To facilitate this, transactions in the resource logic DAG can also be modeled as functions which _produce_ transactions, possibly taking into account the latest resource at a particular key. This entails an ordering with respect to the keys read, so the transaction must include all keys which it might read (for which the transaction author does not necessarily know the values and/or wishes ordering to be delegated). The transaction then receives the values of those keys at the logical time of execution and can use them to compute the input and output resources. 

> TODO: Strict ordering is required here, so if all keys do not have the same identity, we will need to create a joint identity (chimera-chain-on-demand) to try to order w.r.t. all involved resources.

> TODO: I think we can/should combine this with executable transaction so in-between states are possible.

```haskell
data DelayedTx
  = DelayedTx {
    keys :: Set Key,
    exec :: Set (Key, Resource) -> Transaction
  }
```

## DAG

```haskell
type Transaction = ResourceLogicTx

type State = Set Resource
```

A resource logic DAG is valid if and only if:
- all transactions are valid by the conditions as above
- all transactions are included in the same order as their data in the physical DAG (i.e. if `a` happens no later than `b` in the physical DAG, `a` happens no later than `b` in the logical DAG)
  - within ordering determined by the physical DAG, creations and consumptions determine ordering within the logical DAG, i.e. a transaction `b` which consumes a resource created by `a` happens after `a`

From a particular resource logic DAG, an observer can calculate a _state_ as a key-value mapping by taking `key(resource)` and `(data resource, value resource)` for all resources created but not yet consumed (by final transactions) in the history of that DAG.

---

> TODO: This section is notes, readers please ignore.

Outstanding topics:
- What exactly is the desired logic of a finality predicate? I think, from the intent layer, it is: "among the transactions which consume my intent and are valid, pick this one". It should not be more general than that because other constraints could have been encoded into the predicates already - finality predicate is only for _ranking_ in information uncertainty, and it is an _ordering_ which should also reference a _logical time_ (w.r.t. some identity). Then the question becoems how ranking functions are _combined_ across intents - we should be able to retain the guarantee that between two transactions with the same intents, where all intent authors prefer the latter, the former is not accepted. Given a set of intents included in a set of transactions, the ranking functions give a partial order to the transactions.  -- then these should _not_ be first-class, rather they are part of the definition of an identity, since ordering/ranking is concerned. So instead we should contemplate ways of encoding this into consensus providers'
- Previously we had this concept of a "virtual resource" for modelling non-linear (infinitely consumable) things. However, since often these were physical-DAG-dependent, I think identity is the right abstraction here instead, maybe it would be good to come up with some motivating examples.
- Spell out how nullifiers and commitments can be used to track linearity efficiently here.