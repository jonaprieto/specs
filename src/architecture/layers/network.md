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

A `Message` is the lowest layer type, sent around between agents over the network using `send` and received with `onRecv`. There are four `Message` subtypes:

- `Network` P2P metadata requests and responses for [physical network abstraction](./network/physical-network-abstraction.md)
- `Storage` read/write requests and responses for the [distributed content-addressed data storage layer](./network/distributed-content-addressed-storage.md)
- `Compute` requests and responses for the [distributed content-addressed compute cache layer](./network/distributed-content-addressed-compute.md)
- `Observation` messages, which capture partial ordering information used to craft the [physical DAG](./physical-dag.md)

Messages may also be bundled together into a multi-message, which may carry specific semantics (e.g. a storage request could be bundled with payment). 

```haskell
data Message
  = NM NetworkMessage
  | SM StorageMessage
  | CM ComputeMessage
  | OM ObservationMessage
  | MM [Message]
```

&nbsp;

The protocol orthogonalises correctness (verification) and efficiency concerns, such that `Network`, `Storage`, and `Compute` messages are independent of the actual ordering of data (physical DAG) and relations in question (logical DAG).

```
```

See next:
- [Physical network abstraction](./network/physical-network-abstraction.md)
- [Distributed content-addressed storage](./network/distributed-content-addressed-storage.md)
- [Distributed content-addressed compute](./network/distributed-content-addressed-compute.md)