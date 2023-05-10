# Dynamic distribution

# Network

Agents can send messages to each other by `send(identity, msg)` where `identity` is an external identity, and they can handle received messages with some `onRecv(msg)` (to which messages addressed to them will be sent). We assume an asynchronous physical network in the general case, where liveness with regard to some message set and some agents will require eventual receipt of all messages in the set by the agents in question.

Note that sending to multiple identities can be accomplished by composition of identity by disjunction as defined previously, and blind broadcast can be accomplished by using the "all" identity. Messages (particularly those to the "all" identity) may also be prefixed with a topic (bytestring) such that agents can receive messages only for topics which they are interested.

A separate physical network abstraction layer is responsible for keeping appropriate routing tables to map external identities (including compositions thereof) to known IP addresses and route messages around. This physical layer has many specific optimisation concerns which are out of scope of the abstract specification.

> TODO: Link to part of Typhon networking spec. Also, clearly define (somewhere) what entanglement data should be provided to / used by the physical network layer, this is probably important.

```haskell
class Monad m => AgentContext m where
    send :: ExternalIdentity -> ByteString -> m ()
    onRecv :: (ByteString -> m ()) -> m ()
```

## Messages

A `Message` is the lowest layer type, sent around between agents over the network using `send` and received with `onRecv`. A message consists of a set of payloads, which are self-describing in the sense that the receiver can recognize payloads which they care about upon receipt of the message. The set of payloads is strictly a set (there is no information implied about ordering). A message may include any number of payloads with the same type, and payloads of any combination of types. In general, receiving one message with multiple payloads `{p1, p2, p3...}` is equivalent to receiving many individual messages with payloads `{p1}`, `{p2}`, `{p3}`, etc.; i.e., including multiple payloads is simply a convenient batching technique.

Payload types include, but are not limited to:
- `Network` P2P metadata requests and responses for [physical network abstraction](./dynamic-distribution/distributed-routing.md)
- `Storage` read/write requests and responses for the [distributed content-addressed data storage layer](./dynamic-distribution/distributed-storage.md)
- `Compute` requests and responses for the [distributed content-addressed compute cache layer](./dynamic-distribution/distributed-compute.md)
- `Observation`s, which capture partial ordering information used to craft the physical DAG.

Messages may also include an optional external identity and signature, both referenced by hash, where the signature is over the Merkle root of all the payloads. 

```

&nbsp;

The protocol orthogonalises correctness (verification) and efficiency concerns, such that `Network`, `Storage`, and `Compute` payloads are independent of the actual ordering of data (physical DAG) and relations in question (logical DAG).

```
```

See next:
- [Network abstraction layer](./network/network-abstraction-layer.md)
- [Distributed content-addressed storage](./network/distributed-content-addressed-storage.md)
- [Distributed content-addressed compute](./network/distributed-content-addressed-compute.md)