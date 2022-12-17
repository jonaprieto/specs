# Physical DAG

## Observations & Physical DAG

The _physical DAG_ is the layer directly on top of the lowest-layer network, responsible for providing local partial ordering information. This DAG is singular, in that any message can reference any other message created at this layer. Different observers may see and perform computations on different sub-physical-DAGs (just in accordance with which messages they have actually received) - but any observer in possession of any particular message can check whether or not it has received all transitively referenced messages, guaranteeing that two observers treating the same message as the current state and performing the same computations on parts of the past physical DAG (w.r.t. that message) will end up with the same results. The physical DAG has no knowledge of linearity, consensus, or validity semantics - those are the responsibility of higher layers.

### Definitions

- An `Observation` is a type of message which attests to witnessing some data (possibly other messages), and provides a signature along with an external identity.

```haskell=
data Observation = Observation {
  witnesses :: Set Hash,
  identity :: ExternalIdentity,
  signature :: ByteString
  }
```

We also define `commitment(observation) = hash(witnesses, identity)`.

`Observation`s can be verified by running `identity.verify(commitment(observation), signature) => true | false`. Observers can generate valid signatures by running `sign(commitment(observation))` with their internal identity as above.

The witnesses in an observation can include any other observation `o` (just `commitment(o)`) or any arbitrary data `d` (`hash(d)`). Arbitrary data could include transactions, other network-layer messages, or anything else, but observers inspecting other observations will only care about (and be able to parse) certain formats of data.

> Anti-DoS note: We do not want observers downstream of a particular observation to need to do any processing of witnessed events in the past history of that observation which they do not care about.

> Anti-DoS note 2: Although there is a singular physical DAG, nodes still choose who to receive messages from and whether or not to witness them, and will likely refuse to accept & include other messages carrying a high computational load unless they are specifically paid to process them, incentives are aligned a-priori, or similar.

### Properties

The physical DAG provides local partial ordering information, in that an observation by identity `I` of witness set `{w}` proves that `I` knew about all witnesses in `{w}` no later than the creation of this observation, which itself can then be referenced in later observations by that observer and by others (assuming non-invertability of hash functions).

Nodes will have local rules around when to create & send an observation at all (creating an observation without sending it is equivalent to not creating an observation at all, since it could have been equivalently created later whenever a node sends something).

Examples of rules:
- Send an observation every second (or every time tick `t` based on a internal clock)
- Send an observation on a particular condition (e.g. some other messages from my fellow consensus provider nodes)
- Send an observation when requested by some other node

More frequent observations provide higher-granularity partial ordering information.

 Honest nodes behave as following:
- When sending an observation, include in the witness set all observations which they have seen since the last observation they sent.
    - Thus, all data the observer has ever seen will be included in the transitive backreference graph of their observations
    - This is unenforceable and undetectable, since we can never prove that a node received a message until they have witnessed it (by adding receipts of some sort, we could have a method of detection, but observations are effectively a receipt already so these seems redundant).
- From the perspective of certain consensus algorithms, honest nodes also provide a total order in their witnesses: they issue observations in an order, and each observation includes the previous observation in its witness set (thus all future observations transitively reference all past observations, in a total order).
    - This is unenforceable, but detectable: two observations from the same identity, neither of which includes the other in its transitive witness set, constitute a violation of total transmission order, and these violations can be processed in some fashion by higher-layer logical DAGs (e.g. slashing).
    - Higher layers processing the physical DAG may or may not care about this, but the physical DAG layer should provide sufficient structure to detect such violations of total transmission order efficiently. This could be done by keeping a witness set in each message, which must be correctly updated to include all of the witnesses in the message's transitive witness history. Two observations from the same identity, neither of which includes the other in its witness set, consitute a violation of total transmission order (this can be checked in `O(log n)`).

> Note: There is no notion of linearity at this layer, only total transmission order.

