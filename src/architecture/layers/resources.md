# Resource Management

This section specifies the building blocks of the Resource Management System that constitutes the contents of Messages and the substrate on which higher layers (e.g. logical DAGs representing some kind of State) are built.

## Components

### Resource Types
The Type of a Resource and its fungibility, is determined by the Resource Logic, Static Resource Data and its Prefix.

### Resources
Resources are the atomic units of the system. Each one carries a unique Suffix, providing a partially ordered history of the immutable Resources that inhabited a type can be derived this way.
Non-Linear Resources are ordering invariant and can be reused, for Linear Resources, only the last version of an inhabitant is valid and they can not be reused.

#### Resource Name
The Name of a Resource is the concatenation of Prefix and Suffix.

#### Resource Key
The `key` of a resource is computed via `hash(resource)`.

### Predicates
A Predicate encodes constraints for `Transactions` . We differentiate between Predicates that encode `Resource Logic`s, and all other predicates, which we call `dynamic Predicates`. They only differ in the semantics we ascribe to them: `Resource Logic`s describe constraints that are static across transactions for the `Resources` that carry them, `dynamic Predicates` can do that as well, but it is not required. The interfaces to them, and constraints they can describe should be equivalent.

#### Resource Logic
The Resource Logic of a Resource is defined via a static Predicate. Its address is computed via `hash(Predicate)`.
The Resource Logic is tied to a specific Proof System for shielded `ptx`s, since it influences fungibility of the Resources. Evaluating plaintext circuits for Transparent `ptx`s should always be possible.

The Resource Logic specifies under what conditions `Resources` of that type can be created and consumed. For a fungible token, for example, new tokens may be created with a valid signature from the issuing identity and they may be spent/consumed with a valid signature from the identity which currently owns them.

**Note:** The only semantic differentiation between Predicates relevant to Applications is between ones that are static and influence fungibility and ones that are dynamic and don't influence fungibility.

### Partial Transaction (ptx)
A shielded `ptx` has _k_ (currently _k_ = 2) input and _k_ output resources. Shielded `ptx`s can be cascaded, if larger input and output sets are needed.

A transparent `ptx` can have arbitrary size input and output sets, but for some use-cases where proofs and nullifiers are needed it might need to be decomposed into compatible cascaded shielded `ptx`s.

A similar approach can be used to compute a set of shielded `ptx`s simultaneously, for some potential efficiency gain.

A `ptx` is also the scope for a `Predicate`. 

A partial transaction is _valid_ if and only if the predicates of all the resources consumed and created are valid.

```haskell=
data PartialTx = PartialTx {
  input_resources :: [Resource],
  output_resources :: [Resource],
  executable :: Executable,
}
```

```haskell=
valid_ptx :: PartialTx -> Boolean
valid_ptx (PartialTx inr outr) = all (map (\r -> logic r inr outr) (inr <> outr))
```

> TODO: Write out details about commitment and nullifier handling in the shielded case. 

#### Differences between Shielded and Transparent Partial Transactions
Transparent `ptx`s are shielded `ptx`s for which we preserve the plaintext input and output Resources (or pointers to it). This way, validation of Predicates can happen at any time against the plaintext Resources.

They can still be encrypted for specific recipients.

We still compute commitments, proofs and nullifiers, to preserve composability of Transparent and Shielded Partial Transactions downstream.

### Transactions (tx)
Transactions provide the notion of balance for a set of `ptx`s, as well as validity for all their Predicates.

A transaction is _balanced_ if and only if the input and output sets of each Resource Type are of the same size.

A transaction is _valid_ if and only if the `ptx`s it contains are valid and it is balanced.

```haskell=
data Tx = Tx {
  partial_txs :: [PartialTx],
  executable :: Executable,
}
```

```haskell=
denomination :: Resource -> ByteString
denomination r = serialize (logic r) <> static_data r

balance :: Resource -> Balance
balance r = Balance [(denomination r, quantity r)]

balance_delta :: PartialTx -> Balance
balance_delta (PartialTx inr outr) = sum (map balance inr) - sum (map balance outr)

check_transaction :: Set PartialTx -> Boolean
check_transaction ptxs = all (map valid_ptx ptxs) && sum (map balance_delta ptxs) == 0
```

> TODO: Write out details about commitment and nullifier handling in the shielded case. 

### Proof System
The Proof System of a resource is defined via the proof and functional commitment schemes used. It is encoded (amongst other things relevant to the resource logic, e.g. public keys etc.) statically in `resource_data_static` to increase legibility for differences between Resource Logics, by separating Predicate from Proof System differences.

### Controllers
Controllers are the Identities (e.g. consensus providers) that determine the order of (p)txs including the given Resource. The first controller in the list is known as the resource originator.
By signing a message, a Controller promises to not sign another message committing to an equivocation of the signed message. 
It is recommended to assume finality only after checking Controller Signatures on (p)txs.

Precedence of Controller signatures is ordered by their position in the list, i.e. a signature from the first Controller can override signatures of all downstream Controllers.
Because of this, the list positions should correspond to Trust, from most trusted in the front, to least trusted at the end.

This way we gain the following options by using signatures of upstream Controllers:
- Resolving conflicts created by defecting Controllers.
- Updating the Controller list, when the most downstream Controller is offline or defected.

> TODO: Revise and concretise this section.

### Transaction Execution Logic
The TEL contains the machinery to compute candidate (partial) transactions which are then checked against the constraints encoded in the Predicates. It is up to the computing parties whether they use the `Executables` from the TEL, unless required by the Predicates, or choose other ways of coming up with transactions.
Application Developers are encouraged to Provide a TEL, but it is optional in principle.

A TEL can contain multiple `Executables`, e.g. for Wallets (shielded and transparent `(p)tx`s), Solvers (shielded and transparent `(p)tx`s) or Execution Engines (transparent `(p)tx`s only), or just a single one.

> TODO: Specify what exactly no-op's should look like for Wallets, Solvers and EE. 
> TODO: Do we want to pass around the whole TEL through ptxs over txs, or have explicit interfaces to supply single executables? If so, where should they get called from?

## Relationship between Notes and Resources

There is a conceptual 1:1 correspondence between a Resource and a Note. 
TODO: These names/objects should be unified and we need to do a thorough examination of what is left to do to move it into practice.

### Resource Upgrades
If we want to upgrade the proof system used for a Resource type (determined by it's Resource Logic), we instantiate a new Resource Logic that is backwards compatible by supporting `ptx`s which take old Resources as inputs. Upgraded Resources should not be allowed to be moved back to the old proof system, once upgraded.

TODO: How to order proof systems, to prevent downgrades?

## Data Structures

TODO: Explain that usually, we want to send around Headers containing only ContentHash in place for all data fields, and Bodies which contain the explicit Data.

```haskell=
data Resource = Resource {
  resource_logic :: ResourceLogic,
  resource_data_static :: ResourceDataStatic,
  resource_data_dynamic :: ResourceDataDynamic,
}
```
    
### resource_logic
This field contains all Predicate components that are relevant to the fungibility of a Resource it encodes. It can optionally call external predicates which are stored in `resource_data_dynamic` or other `Resource`s.

```haskell=
data ResourceLogic = ResourceLogic {
   predicate :: TxData -> Bool,
}
```

### resource_data_static
This struct contains everything that is relevant to fungibility of the _Resource_, which is not a Predicate.

Everything relevant to fungibility and Transaction balance needs to be in specific, named fields. Everything else is only relevant to Predicate validity and can be stored in a ContentHash indexed map of ByteStrings. The same is true for resource_data_dynamic.

Mandatory fields:
- The resource `Prefix`, encoded as a List of ContentHashes.
- Any information about the proof- and commitment system that is relevant for fungibility of the _Resource_.

Examples of optional data:
- Any additional static data that is required, e.g. External Identities.

```haskell=
data ResourceDataStatic = ResourceDataStatic {
  prefix :: [ContentHash],
  proof_system :: ByteString,  
  extra_data :: Map ContentHash ByteString,
}
```
> TODO: Taiga: Is this a good name and datatype for proof_system?

### resource_data_dynamic
This struct contains everything which _is not_ relevant to the fungibility of the _Resource_, including Predicates.

Mandatory fields:
- The dynamic `Suffix` identifying the version of the `Value` of the Resource. Should always be a nonce.
- The list of `Controllers`for the Resource.
- The `Value` of the encoded `Resource` represented by a ByteString (i.e. the current content of the Memory behind the address).
- An integer valued `Quantity`, to determine balance in `tx`s using fungible `Resources`.

Examples of optional data:
- Dynamic (components of) Predicates, such as:
    - Optional Predicates to determine ownership of the resource being encoded.
    - Predicates derived from user Intents, used as side constraints for solvers or the Execution Engine.
    - **Note: Do we want to move these to a separate field, e.g. dynamic_predicate(s)?**
- All dynamic information relevant to Taiga verification. TODO: Add example for that.
- The Transaction Execution Logic (TODO: Are there cases where we might want this in resource_data_static?)

```haskell=
data ResourceDataDynamic = ResourceDataDynamic {
  suffix :: ContentHash,
  controllers :: [ExternalIdentity],
  value :: ByteString,
  quantity :: Natural,
  extra_data :: Map ContentHash ByteString,
}
```

// TODO: What exactly should the suffix be? Should it always be a the output of a hash function, or just a bytestring of equivalent size? Should it be only one Hash size wide, or potentially a list as well?

## Intent
Intent is encoded in two ways:
1. In an unbalanced `ptx`, it is expressed as am (Ephemeral) Resource Logic of an Ephemeral Resource.
2. As side information e.g. for a solver. In this case it should reside as a Predicate in `resource_data_dynamic`.

Both of these should be derived from a user facing Intent frontend, s.t. the user only needs to specify a Predicate for the `tx`s they want to perform.

The above two approaches to encode unbalanced `ptx`s, as well as side constraints, can also be used to implement other concepts beyond intent.

## Ownership
Knowledge of the nullifier key of a Resource (i.e. owning the Resource) is necessary, but not necessarily sufficient to own a resource. Ownership might further be constrained via the Predicate which can call on Predicates in `resource_dynamic_data` or external resources.

## Lifecycle of a Transaction

(*Actions in italic*, States in regular font)

### Partial Candidate Transaction (optionally created using Executable from TEL)
A candidate partial transaction is created, optionally using an Executable from the TEL. It is unbalanced.

### *Solving* (optionally using Executable from TEL)
It gets balanced either by a solver node, or directly in the user wallet, optionally using an executable from the TEL.

### Candidate Transaction
Once a set of partial candidate transactions are balanced, it becomes a Candidate Transaction.
**Note**: At this point, any predicates which are not dependent on state-after-ordering can be checked and proved.
### *Ordering*
Candidate Transactions then get ordered by Typhon, or any other consensus provider determined by the controller list in a Resource.

### Ordered Candidate Transaction
Once a `tx` has been ordered, it becomes an Ordered Candidate Transaction. It is now known which Input Resources are still available.

### *Validation*
Then Taiga 1) validates the Proofs (shielded case) / aggregates input and output resources (transparent case) and 2) validates all Predicates for all `Resources` in a `tx`.

### *Optional Execution* (optionally using Executable from the TEL)
Optional Step: The Executables from the TEL for the Execution Engine are run. E.g. executables that depend on all relevant Resources being known.

### (Validated Ordered Candidate) Transaction
Once Validation and Optional Execution are done, the last remaining step is to:

### *Apply Transaction*
The Transaction gets applied by Typhon: Resources and Nullifiers are added to their respective trees.

### Executed/Applied Transaction
The Transaction has been applied.
