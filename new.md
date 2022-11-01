# Anoma Architecture Scope and Draft



## Abstract

The protocol in this document describes the functioning of a distributed, privacy-preserving (DEFINE + Link) state machine with scale-free fractal consensus. Participating nodes can cheaply verify that their local view of global history is consistent and correct, but must make choices about which other nodes to rely upon for data storage and consensus provisioning (DEFINE + Link). The primary expected application of this protocol is the provisioning of a scale-free (DEFINE + Link) cryptographic credit (DEFINE + Link) system, which provides a local, quantifiable view of entanglement (DEFINE + Link), a measure of incentive-alignment as well as gains from cooperation (or, correspondingly, loss to defection) (TODO: Quantify). This measure can be fed back into these local choices made by participating nodes, allowing the gestalt system to use high entanglement to reduce computational resource expedeniture in interactions.

Our approach provides:

- partition tolerance
- resource usage that scales with the required level of validation
- privacy that scales with the inverse of trust
- robustness towards heterogenous networking conditions

The credit layer provides:

- incentive compatibility (tbd on credit layer)

Considered relative to existing protocols, in this proposed architecture we unify several notions previously considered to be separate, such that distinctions in kind become instead distinctions in particular content, with a scale-free architectural topology. Specifically,

- We unify the concepts of "[message](#Message-Representation)" and "block (DEFINE)" - all messages are cryptographically hash-chained, and blocks are simply a particular type (content) of message
- We unify the privacy-preserving double-spend prevention technique of Zerocash/Zexe/Taiga - nullifiers, uniquely binding to note commitments, unlinkable and calculable with secret information - with the double-spend prevention required of distributed database systems / blockchains (preventing multiple valid conflicting descendents of the same block), recasting the mechanism as a distributed enforcement system for a linear resource logic.
    - Relatedly, we unify the concepts of "note" (from Taiga), "UTXO" (from Bitcoin / parallel VMs), and "message"/"block" (as above).
- We unify various concepts of state-machine-level cryptographic identity -- public-key-based accounts, smart-contract accounts, BFT light clients, threshold keys -- and network-level cryptographic identity into a singular information-theoretic duality of _external identity_ and _internal identity_, the fundamental abstraction on top of which the protocol is built.
- We unify the concepts of _message_ and _state_, in that each message commits to its own history, and that there is no state other than can be computed from a set of messages at a particular point in partially-ordered logical time.

This unification requires a protocol construction with primitive operations which may seem expensive - e.g. sending a message requires creating a ZKP - but performance can be recovered (trading off for privacy or scaling in particular cases) by using trivial implementations of the primitives (e.g. non-ZK non-succinct proof which is just like a regular message).

## Scope

This document describes:
- the state/message model
- properties and validation of state logs
- higher order ad-hoc consensus by merging state logs
- how scale freeness works (no semantic breakage)
- privacy properties at different scales
- the graduated guarantees the protocol provides
    
Maybe:
- BGP(-ish) routing via consensus providers

This document specifies interfaces and properties for, but _does not_ describe in detail: 

- data availability layer 
- base physically-addressed gossip network
- recursive ZKP scheme
- heterogenous bft consensus (can we use homogenous?)
- anonymization of network traffic (e.g. mixnet)

# TODO

- Interface Definitions
- Properties of Interfaces
- Rough Protocol
- Properties of the Protocol
- What does a Node do with these Interfaces

- Cryptography: Robust Random Peer Sampling 

# Naming Suggestions / Glossary

Credit:  TODO, better term
Topology: TODO, better term
Message; Candidates: Event, Transaction, Minimal Atomic State Transition 
Linearity Violation: TODO, is this term overloaded already?

## Abbreviations

IF = Ideal Functionality
LL = Linear Logic
CP = Consensus Provider



# Ideal Functionality

## Functions

Observers are assumed to have the ability to store data (privately via locality), perform compute, and send and receive messages over an arbitrary, asynchronous physical network (~ Turing machine with a network).

This protocol provides to an observer the ability to:
- Create cryptographically-content-addressed history
    - e.g. issue messages from a private/public keypair that they create from nothing (LL: initial object)
    - send messages to the terminal identity, after which they can never be used again (LL: terminal object)
- Validate cryptographically-content-addressed history that the observer learns about from elsewhere
    - Validation covers correct instantiation (cryptographically-content-addressed), linear consumption from instantiation, and validity of predicates (state transition rules)
    - Privacy provisions allow for any arbitrary part of this history known by another party to be revealed by that party to this observer while retaining all of these validity guarantees
        - e.g. the party can reveal to the observer a message at the end of some chain of history and prove that the history is valid and terminated in that message - this message (if desired) can then be built upon by the observer who now knows it
        - knowledge of a message is a necessary but not sufficient condition in order to consume / create history on top of it
- Merge two cryptographically-content-addressed histories and ensure that the linearity condition is not violated in the output
    - Checks that no message was consumed to create different descendents in both histories (and as descendents commit to their ancestors, also checks that no message was consumed alongside different other messages in both histories) 
    - Can create a message which witnesses many prior histories (but does not consume them), and restricts its descendents to never witness conflicting histories from ones already witnessed.
        - e.g. used for block production by consensus providers


These functions are scale-free, in that the compute costs do not depend on the complexity of the particular histories in question. Implementation choices for particular primitives (identity, proof systems) can be made in order to trade between different computational and communication costs and who bears them.

> Note: what is the minimal set of cryptographic assumptions needed to instantiate this protocol? I think it is just one-way hash functions ~ i.e. P /= NP.

## Constraints

### Scaling

1) Nodes who want to only participate as transaction parties should not process something more than a constant size in respect to the transactions they are a part of: e.g. do reads and writes w/o the need to process data (compute/bandwidthw/memory) worse than linear in the size of the reads and writes.
2) Consensus providers should only need to perform computation linear in the number of messages (size of the histories) they want to provide history linearity validation, or ordering for, independent of message structure and size. 
3) The "prune bad branches" strategy of merging after linearity violation should not be more expensive than linear in the length of histories.

### Topology

1) Processes should be locality favoring, unless explicitly specified: Nodes in a subnetwork should not need to communicate outside of it by default.

### Privacy

1) Any node with write permission to a namespace suffix can produce a change in it, without revealing it to anyone outside the subnetwork, but produce a zk validity proof which they can verify.
2) Nodes need to be able to prove that they did not violate linearity, while preserving data and function privacy.

# Protocol 

The protocol is defined as a function `update`, run locally, which takes the current local state & a received message, and returns an updated state and a possibly empty set of messages to send. We assume that nodes receive messages in a total order (parallelism in implementation for parallel receives is possible as an optimisation).

```haskell
update :: State -> Msg -> (State, {Msg})
```

where `State` is the local state, comprised of a set of previously seen and validated messages.

The protocol also defines an initial state $s_{0}$, which is the empty set.

The protocol defines this `update` function on top of a layered set of abstractions, which we describe henceforth, starting with identity.

# Identity Layer

The base abstraction of the protocol is knowledge-based identity, where identity of observers is defined on the basis of whether or not they know some secret information (to derive the Internal Identity).

## Basic assumptions & definitions

- `hash` is a collision-resistant one-way function
- We assume a shared execution semantics, such that functions have a canonical serialisation. (We do not assume that equivalent functions have the same serialisation, only that functions have a serialisation which is understood and can be executed by participating observers)

## Identity

Identity in the protocol is defined by a cryptographic interface. Observers can use private information (likely randomness) to create an internal identity, from which they can derive an external identity to which it corresponds. The external identity is a name which can be shared with other parties. The observer who knows the internal identity can sign messages, which anyone who knows the external identity can verify, and anyone who knows the external identity can encrypt messages which the observer can decrypt. This identity interface is independent of the particular cryptographic mechanisms, which may vary.

### External Identity

Each External Identity has the canonical representation:

`hash(verify', encrypt')` with: 
- `verify'(msg) -> bool` to verify the originator of a message
- `encrypt'(msg) -> cyphertext` to encrypt a message which any recipient who knows the internal identity can decrypt


For example, `key` can be a public key in a standard asymmetric public-key encryption scheme, where `verify'` and `encrypt'` are curried with the key as `verify(key)` and `encrypt(key)`.

> Note: consider requiring ZKP that someone knows internal identity s.t. for some (a random?) `m` they can sign and decrypt it. (TODO - cryptographers)

### Internal Identity 

The Internal Identity is constituted by knowledge of the following functions:

- `sign'(data) -> signed data`
- `decrypt'(cyphertext) -> plaintext`

such that any `sign'`-ed message is accepted by `verify'` and any `encrypt'`-ed message is opened by `decrypt'`.

For example, these can be the signature generation and decryption functions in a standard asymmetric public-key encryption scheme, where `sign'` and `decrypt'` are curried with the secret as `sign(secret)` and `decrypt(secret)`.

### Special Identities

To illustrate the generality we can come up with the following special keys (~ LL: initial and terminal objects with respect to information).

#### "True / All"

Anyone can sign and decrypt (`verify'` returns true and `encrypt'` returns the plaintext). No secret knowledge is required, so all observers can take on this identity.

#### "False / None"

No one can sign or decrypt (`verify'` returns false and `encrypt'` returns empty string). No secret knowledge exists that fulfills these requirements, so no observer can take on this identity.

# Network

Observers can send messages to each other by `send(identity, msg)` where `identity` is an external identity, and they can handle received messages with some `onRecv(msg)` (to which messages addressed to them will be sent). We assume an asynchronous physical network in the general case, where liveness w.r.t. some message set and some observers will require eventual receipt of all messages in the set by the observers in question.

# Messages / State

## TODO
TODO^: Explain how messages propagate locally through gossip


## Message Representation
For a new message in the chain to be generated, the previous message has to be consumed (e.g. it can not be reused to send a new message in the chain)

Any observer can create a message. Messages consist of the following fields:
- key ([]bytes)
- value (bytes)
- predicate (function)
- ancestors (hash set) (possibly empty set)
- witnesses (hash set) (possibly empty set)
- nullifier secret commitment

From these fields a unique commitment and unique but unlinkable nullifier can be derived, as:
- commit(msg) = hash({all fields})
- nullifier(msg) = hash(secret, hash({all fields except nullifier}))

By way of brief explanation,
- `key` contains the message namespace
- `value` contains arbitrary data
- `predicate` defines the conditions under which a message can be consumed, which may include arbitrary data (no data/code separation)
- `ancestors` includes the messages consumed to create this message
- `witnesses` includes the messages (histories) witnessed by this message (choice of message creator)

Each node locally keeps a totally ordered log of messages it sends, as well as messages from other nodes which it derived messages from.

The content of an initial message must be created at a key derived from a PRF of the value (`{external_identity}/prf(value, predicate)`), such that two initial messages created at the same key necessarily have the same value & predicate (and thus are just the same message, with same commitment/nullifier/etc.). Initial messages must provide a signature valid for the external identity in the prefix of the key.

> Option: There must be only one initial message with a fixed value (nonce) of 0, which all subsequent messages must witness. This ~is the external identity and can optionally constrain future messages to be ordered or not. (useful for: consensus providers). Identity = Message = State, QED.

> Note: this is just like a default first predicate which checks the PRF, should be possible to explain more clearly.

> TODO_: In which cases do we want to permit initial messages to be created from nothing, or require to branch from bootstrapping state? (related to possible history-compressing optimisations)

Given a valid set of messages on the frontier (locally current "time"), we define the _state_ with respect to said messages as the mapping from keys to values, defined by this set (where the keys are guaranteed by the linearity validation to be unique). 

A _namespace_ is a partitioning of the keyspace by external identity as defined above, such that only an observer who knows an internal identity can create messages in the namespace owned by that external identity. Messages without any ancestors must be created in the root namespace for a particular external identity, and knowledge of the corresponding internal identity is required to create such messages. Messages not in the root namespace for a particular external identity must be created by consuming other messages, whose predicates are checked as part of the validity check.

Messages can be kept locally or sent over the network. When sending messages over the network, they are encrypted to the recipient using `encrypt'`. Local state transitions are modelled as messages from an identity to itself. 

Each participant keeps a (partially ordered) log of messages they created or interacted with. This way they can produce proofs to attest to their view of the state of the global namespace.

Considering the definition of state above, messages can be understood to encode `(key, value)` pairs, setting `key` to `value`, with the validity of the particular transition checked by the particular predicate.

Message validity rules ensure that the namespace fulfills the following properties:
- External Identities form the prefix set for the namespace.
- Ownership of suffixes is transferred by updating the predicate associated to them, allowing another idenity to consume the message and "write" to the suffix.
- Complete identity ownership transfers can be performed by a special kind of message (requires consent of recipient by signature), which for anyone who is aware of it causes them to update their local validity rules such that the old identity and new identity prefixes are collapsed to a single one (identified based on the old identity, or possibly based on locally unique enumeration - future work)
- Disjoint suffixes (e.g. via protocol specified PRFs) are used to enable asynchronous, distinguishable writes, where necessary. These can be enforced by predicates (e.g. one can mint a message with a predicate which allows another to consume it and write to their namespace, but only at a deterministically random and non-conflicting location)

## Linear Resources

Since we are interested in tracking ownership and uniqueness of (some) state transitions, we model their behavior similar to a (simplified) linear logic. Write operations (implication) are assumed to be potentially non-local, while read operations are local and "infinite/free". Message validity checks uniqueness of nullifier spends in order to ensure linear consumption of resources in write implications.

Some state transitions, e.g. `write` operations, consume their inputs (LL: they output an additive conjunction), while others, like `read` do not  (LL: they output a multiplicative conjunction), which is expressed in their type (TODO: do we want to call this type?).

Resources can be created from nothing in this cryptographically content-addressed way, and destroyed into nothing by sending them to the False Identity (terminal object).

### Borrow Checker / R/W Permissions

If any node gives permission to other nodes to operate on some state in it's namespace the following must hold:
- There can be any number of `read permissions`
- There can only be one outstanding `write permission` for any piece of state at a time.

Permissions can be given bilaterally between identities, or application specific; e.g. every identity running an application can write in the namespace of everyone else who runs it, under their own prefix, preventing collisions.

## Validity

To validate messages with respect to some known set of valid messages the following need to be checked (in order of importance):

1) Are all the predicates in the message chain valid?
2) Does the chain of backreferences point back to valid initial messages?
3) Are there any conflicts between the nullifier set of this history and the nullifier set of my known valid messages?
    (Are linearity requirements, e.g. state consumed by additive operators is not reused, fulfilled?)
    (Also checks that there are no double spends in this message's history)
    (deals with disjoint histories only, so no nullifiers can be spent twice)
    Check that either:
    1) histories are disjoint, there are no nullifiers in common (spent twice)
    2) message includes proof that if nullifiers were spent in both histories, they created the same messages.
        In order to compose this proof, the sender of the message must know a recent witness set of mine so that they create the proof (e.g. a block produced by a consensus provider) and they must have DA on the nullifier set for that witness set.

If the validity check passes, this message is added to my set of known valid messages. If the validity check fails, this message is rejected. 

> Note: TODO+: double spend announcement / (local) conflict resolution

The state transition from the message is then `applied` by appending it to the local chain.

> LangSec Note: Parsers for predicates should be determined per application and be ones of the least computational power possible. Make predicates content addressed for permissioning.

> **Progress Note: Second pass has happened up to here.**

## Validity proofs

If a node sends a message, it produces a proof for the validity of the previous state transitions, as well as a comittment for the current one + a proof for the correctness of the commitment.
The validity proofs for the previous and the validity of the commitment can be unified into one proof.

It also produces a nullifier for every commitment that was consumed to produce the current commitment, and sends along the nullifier set. 
By checking nullifier sets for overlaps, fulfilment of linear resource constraints and thus can conflict freeness of potential state merges can be verified. 

### Succinctness

## Privacy


Make the validity proofs zero-knowledge

### Nullifiers

At minting a commitment is created, at spending a nullifier is created.

See IF: Privacy

## Merging

### Merging State Histories

In this architecture, ordering is performed only when necessary, i.e. any two non-conflicting histories are either completely independent or already partially ordered with respect to one another, and can be merged without additional ordering.

In the case of a double spend (linearity violation), we must pick which branch of history to take. For this purpose, messages specify how nodes which are aware of conflicting histories involving them to pick which history to accept, which must be one of the following options:

1. Reject both conflicting histories and any descendents (~ slashing for double-spends)
2. Pick according to some other arbitrary but verifiable rule
    - Example 1: best price between conflicting usages submitted before some other message (~ in a block batch, interesting for competing solvers)
    - Example 2: pick according to the results of a specified consensus quorum
        - Including quorums to appeal to in the case that this quorum itself violates linearity 
    - Example 3: select randomly according to some other verifiable random beacon

Messages in an atomic operation must agree on which predicate should be used to pick between conflicting histories involving this operation (this is enforced by a system component of the message consumption predicate). As long as the predicate remains unsatisfied, nodes will refuse to merge conflicting histories (preserving their local order). In order to obtain eventual consistency, a determistic, verifiable predicate must be provided - this ensures that if all participants eventually receive all messages, they would come to the same conclusion.

> LangSec Note: Provide a constrained DSL for describing conflict resolution?

> Note: idea: do PRF iterations on each branch of history in order to rank conflicting ones (completely randomly but deterministically) (proof-of-work in expectation)
> Or: Find a way of (locally in respecto the history in question) robust peer sampling to do random ad-hoc concensus ~ slow Avalanche?
> Or: Figure out how to do "canonical" randomness beacons


#### ZKP Implications

- Need DA for nullifiers in merge proof
- Every message carries the nullifier set for it's consumed inputs
- If any party triggers a merge, it needs to prove that it cut all the branches of it's history which contain any of the "bad nullifiers".

TODO+: Merge with section below or remove
TODO^: plaintext merging trivial 

> Quick note: ZKP merging - after a merge resolution, some nullifiers become blacklisted (pruned history), subsequent merges must prove that those nullifiers have no intersections (as if the other branch was spent)

 
### Invalid State Transistions

Predicate validity is checked by validity proofs, so messages violating predicates of prior messages can be trivially rejected. The only non-trivial case is that of linearity violations, which is handled by history merging.

### Consensus

Consensus algorithms can be incorporated into merge instructions as a specific predicate which checks e.g. a light client verification algorithm, a threshold signature, a simple multi-signature, etc. which forms the basis of an external identity.

## Finality

In this architecture, finality is separate from history merging, as for history merging we have eventual consistency, whereas decisions about finality must be made on the basis of partial information about the state of the system (observers can never know that messages they have not yet received do not exist). Finality is only necessary for making "out-of-system" decisions (such as whether or not to hand over a cup of coffee), since the system itself can resolve history conflicts as they arise.

### Consensus providers

Users can pick one or many consensus providers (where many can be re-composed into one external identity) whose quora they consider sufficient criteria for finality (on a per-message basis). Consensus providers can run any standard BFT consensus algorithm (in which they can reuse the existing message graph if desired, a la Bullshark).

### Example: Lightweight One-Way Finality Check

If no consensus is needed we can


### Consensus providers

(these are the actual consensus algorithms)


### Punishment

E.g. slashing
TODO: elaborate in consensus / merge section



---

# Credit

One of the primary motivations for building this system is to use it as a basis for a scale free credit system, but the credit system also provides us with useful features to organize network topology and compute proxies for trust between peers.

The credit system is be one of the core `applications` being run and credit operations are encoded as message types.

The goal here, is to enable every pubkey to mint credit in it's name and exchange it freely with other parties, which can decide to redeem it with the originator at a later point in time, store it, or barter with it.

## Transfer

If `alice` wants to transfer credit of some type (which she holds and knows charly is willing to accept), she can send a message updating the balance of that type to `charly`.

If she does not hold credit `charly` is willing to accept, there are multiple alternatives:
- She sends an intent message, stating she wants to acquire charly credit, to the gossip layer.
- Nodes who are willing to perform swaps `X to charly` report back to the previous hop (TODO0: and maybe her?), stating `(amount, price)`. If a full swap chain back to alice can be established she can decide to execute it.

- _WIP_: She sends a message stating she is willing to acquire charly credit up to some price. Should a path be found via gossip, it can be resolved in place. Prices will be suboptimal and it will only be considered settled once higher level consensus is established (TODO0: the canonical for that provider needs to be specified).

To be consistent with one write permission per "state at some suffix" / "resource" (TODO+: find a better name) and still enably asynchronous transfers, all credit state updates from some `minter` that get sent to `receiver` (with `minter` and `recevier` being `pubkeys`) gets updated under the namespace `receiver.minter` with each piece of credit having its own suffix.  

TODO+: How to prevent observability of message chains? Can we have (sufficiently) non-colliding PRFs? Make PRF space the size of nullifier space, s.t. collision resistance does not rise. 

### Double Spending
Double spending would constitute a linearity violation in our model. Upon merging two non-disjoint histories, a double spend across histories can be detected.
 
## Incentive Alignment
We assume that nodes who exchange a lot of credit (or often do so TODO+: define metrics/proxies for trust here) are closer to each other economically.
They are also progressively aligning incentives: If `A` holds a lot of credit of `B`, `A` will be interested in `B` doing well. Thus, a node which closer in the credit metric is more trustworthy, because the cost of it defecting is higher.

# Scalefreeness and Scaling
The goal of this protocol is to provide unified semantics for interactions between public keys, whether individuals or group entities are behind them, as well as providing a unified way to scale the size of the subnetwork up, where state validates.

The tradeoffs inherent to the system described here are:
With increasing distance, efficiency of transactions goes down, if reliability is to stay equal.
With increasing distance, privacy goes down, if efficiency is to stay low, but some efficiency can be traded for more privacy.

Since our model has `trust` or `entanglement` as a central notion, we get natural scaling effects. The higher the `entanglement` the better the tradeoffs. Since less `entangled` interaction happens less often, costly interactions are rarer than cheap ones.

## Consensus
TODO^: Update to "nodes pay for consensus provision" model
TODO+: For what are consensus providers paid? 
- Including transactions in blocks
- ...

To cover the spectrum reaching from local/trusted transactions to long range/untrusted transactions, we want to have methods to increase the trustworthyness of message logs progressively.

One phase transition in trustworthyness happens when we involve consensus providers, instead of only relying on messages received from the gossip network.

Since we want permissionless consensus hierarchies, we introduce the notion of ad-hoc consensus:
A consensus provider `CP` consists of some peers which observe message traffic on the gossip layer and run (heterogenous) BFT consensus on messages of one interval to decide on a total order for all intersecting histories. Non-intersecting histories are preserved as a partial order per interval.

`CP` produces a partial order with timestamps (block height) on each message in it.

Double spend protection is linear in the cost of messages, since only emptyness of the union of nullifier sets, or fulfilment of linear resource constraints needs to be checked. (See IF: Scaling)

### Ad-Hoc Consensus Sketch
If nodes `N` and `M` who don't have existing trust relations / paths in the gossip network want to transact, they can do so with the help of consensus providers.

Each consensus provider `C` consists of a set of acceptor nodes `A`, which include transactions of nodes visible to them. `pubkeys` of `A` are revealed. `N` and `C` together can produce proof that `C` has a view of `N`.

`N` can then reveal to `M` a (sub)set of consensus providers for itself, where `M` can chose one that they trust the most, e.g.  where `A` of `C` contains pubkeys trusted by `M`. Other criteria for selection might be density of transactions by `N`, freshness of data compared to other providers, etc.

Using this model, consensus providers can be ad-hoc views of the gossip layer, without requiring separate or distinct gossip networks, which would require some sort of governance or permissioning to delineate the boundaries.

`CP` also performs validity checks on the merged histories, to detect e.g. double spends in the credit application, or more generally, violations of the resource constraints.

Nodes need to pay consensus providers to have their transaction included. If `CPs` want to give free transactions to certain nodes, they can mint and distribute credit for that. 

#### Zero Knowledge Consensus Provision
Every `CP` holds a snapshot of current messages seen by it's constituent nodes.
If any of these messages contain illegal state transitions, they are dropped and the punishment procedure is started locally. 

For each valid message, the following happens every round: 
1) The state transition is included in the validity proof.
2) The nullifier is included in the nullifier set corresponding to the validity proof.

After each round, the `CP` sends out two messages:
1) Contains the current validity proof and a commitment to the nullifier set.
2) Contains a block ID and the nullifier set.

The nullifiers then get recorded by some storage layer, or by the `CP` itself.

#### Merge between ZK Consensus Providers
If two CPs `P` and `Q` want to merge histories, `P` computes the intersection of their nullifier sets. If it is empty, it can just compute the validity proof for the merged history, resulting in a third CP with a shared view `PQ`. (They check each other proofs, but don't need access to messages.)

If the intersection is non-empty the following happens:
1) `P` looks up the earliest block ID with a conflict
2) `P` replays the `(backreference, nullifier)` pairs and perform linearity checks on the merged tree, to detect conflicts
3) `P` drop the branches of its tree which contain conflicts
4) `P` recomputes a chain of validity proofs for the valid (and resolved) branches (and merge), using `(br, nullifier)` pairs.
6) They send the `end of round` messages for the merged tree to `Q`, which can decide to reject, or accept and merge (as well as store the nullifiers).

Since the `CP` that initiates the merge performs the computation, and the one that receives it benefits from a larger subset of consensus validity, incentives are aligned here (TODO+).


### Higher Order Consensus
To scale trust up, we can also run consensus between consensus providers and merge their histories, to extend the "no double spend/no illegal state transitions" guarantee to hold for the set of all the nodes these provide consensus for.

Lower trust transactions can be executed this way, with finalization time and compute complexity rising with the amount of consensus layers which need to be queried.

We assume that nodes of consensus providers have bandwidth, storage and compute capabilities, proportional to their layer height.

# Data Availability Layer

## Interface
The DA Layer provides the following Interface:
`publish(value)` to publish content to the DA Layer.
`retrieve(key)` to retrieve values with a given `key`.
`test(key)` to receive a proof of data availability.

with `key = hash(value)`.

When using erasure coding, s.t. out of a set of `n` nodes, `k` can reconstruct a given blob.

Encryption happens out of band, that is nodes encrypt values before publishing.

## Constraints
Optimize for retrieval latency (by running a query and measuring response time).

## Payment for Storage
Options:
- Store up to N MB for friends for free forever.
- Take M credit of denomination X per MB/hour.

### Continuous Payment
Revokable credit node which enables the holder to perform continuous withdrawal. It gives permission to mint a certain amount of issuer credit per interval, until it is revoked.
DA tests are performed in regular intervals and should they fail, the note is revoked. 

## Choosing DA Nodes
Pick DA layers / node sets according to best approximation of incentive alignment regarding cost in bandwidth, compute, storage vs. benefit of the outcome, per function / application, e.g.:
- `CP` needs to do `DA` for nullifier sets to enable nodes, or other consensus providers who want to merge hisotries, to perform linearity checks. 
- Choose `DA` depending on who is expected to retrieve a given message.
- 

TODO^:
- better anonymity set if publishing to bigger DA layer
- blind TTL
- DA layer has k of n erasure coding
- interactive DA test
- DA shouldn't require consensus
 - sender and recepient should have nodes in an overlap



# Solvers
To match intent for e.g. credit swaps, or state transitions which require resource swaps, some kind of computation which can be verified after the fact needs to be performed.

## Privacy Efficiency Tradeoff
Computation (for now) needs to be in plaintext, which can have a privacy cost, e.g. on rare predicates or preferences, even if the originators of the predicates are unknown.
When aggregating over larger sets of intents, better prices for credit swaps and higher rates for matchings of other state pairs can be achieved, while incurring a higher system wide privacy loss from central visibility. In which cases do nodes benefit from wider broadcasts?

## Local Swaps (Credit Case)
If Alice wants to swap `A` for `E`, she broadcasts this intent, in the form of a limit order (or with a price curve) and a commitment to the network. Nodes who accept `A` forward this to all nodes who accept any credit they are willing to swap to. If any node is willing to swap any of the incoming credit to `E`, it announces path termination to the previous hop (and so forth), with the nodes closest to Alice reporting prices for the paths behind them back to her. She then chooses the best price path.

If route selection is competitive, and nodes have interests to be included in the routes (to claim a spread/reward), pricing for swaps should be roughly incentive compatible. (TODO+: Strengthen argument).

## With Consensus
Swap intents include consensus providers we use to decide finality of the swaps.

Alice wants to swap `A` to `B` credit.
Bob proves (pointing to `CP`) to Alice that he holds enough `B` (limit order or swap curve). 

Alices intent is binding, and if bob submits them to `CP` they are deemed final upon block inclusion.

If Bob wants to offer swaps for more than one path, he can broadcast new messages, with swaps pointing to the same credit. The consensus provider then picks the first message in a path that settles to execute and drops the other paths.

Bob splits up the total amount of credit per block he wants to use for liquidity provision per block.

Also: Any node can stake LPs with a CP. The CP can participate in distributed solving like a (set of) regular node(s), or it can do local solving if it holds compatible LPs for the swap chain. Nodes who staked the LPs can override swaps with the same consensus provider by updating LPs after they do swaps themselves.
The CP can also do local solving and produce whole subpaths for the swap chain.

Swap request with whitelists for nodes could be sent to trusted nodes, if swaps should be solved without revealing them to external parties.

## Computational Power of Intents
TODO+: Should intents be turing complete? Are application specific sublanguages a good approach to bounding solve time?

## Intent Privacy
Out of Scope for now, maybe possible via MPC or FHE at cost of implementation complexity.




# Further Research

- The concurrent state model we describe seems to have a natural formulation in the join-calculus, by expressing merges as a join primitive.
- Linear Logic: Investigate if proofnet representations can help to determine useful equivalences.
- By performing merges + proofs we could save on nullifier set size, but only for disjoint subgraphs. This could be useful for cheap fast forward consensus updates with weaker guarantees.


# Notation

TODO suffixes in order of descending urgency:
TODO^
TODO+
TODO0
TODO-
TODO_

# Call Notes

