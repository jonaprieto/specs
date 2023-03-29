# Network abstraction layer

The network abstraction layer is responsible for mapping topical and logical sends (to topics and external identities, respectively) to physical sends to physical addresses (e.g. IPs). This requires three main layers: topical publish & subscribe, logical send, and physical send, which are explained here in turn. The network abstraction layer is responsible for keeping relevant routing tables (about who is interested in what topic and who has what physical address) up to date, for periodically testing latency to other known external identities and providing this as a measure of physical locality which can be used by higher protocol layers, and for routing messages to and from other agents, including those _not_ destined for this agent, keeping track of routing exchange in a low-overhead fashion which can mitigate denial-of-service.

## Automatic routing

The automatic routing system is responsible for routing messages addressed to an identity other than the agent in question, and/or concerning a topic which the agent in question is not interested in, to other known agents who might be able to contact the destination agent and/or might be interested in the specified topic. The automated routing system is also responsible for tracking routing performed on behalf of other agents, such that accounts can be kept and dishonest behaviour possibly identified.

> TODO: More details here.

## Topical publish & subscribe

The topical publish & subscribe system is responsible for routing messages associated with a particular topic (an opaque bytestring) to other nodes who have expressed interest in the topic. Note that an identity is still provided, as the agent may have privacy preferences - in the case of total broadcast to any agent who has expressed interest in the topic, this may be the "all" identity, but it may also be a smaller, specific set (perhaps nodes above a certain level of entanglement, for example).

```haskell
type Topic = ByteString

topicalSend :: ExternalIdentity -> Topic -> Message -> IO ()
topicalOnRecv :: (ExternalIdentity -> Topic -> Message -> IO ()) -> IO ()
```

The topical routing system must keep a state containing information about which other known nodes have expressed interest in a particular topic. This state is used to inform topical routing, which maps topical sends to (possibly multiple) logical sends. This state is constructed from topical interest announcement messages sent (and signed) by particular external identities. The topical routing algorithm can also consult local agent preferences as to how much bandwidth and compute they're willing to spend on routing, and how (for a particular message) to trade between reliability, minimal bandwidth usage, privacy, etc.

```haskell
type TopicalRoutingState
```

## Logical send

The logical sending layer exposes an interface with which messages can be sent to or received from external identities, which act as a kind of logical address. 

```haskell
logicalSend :: ExternalIdentity -> Message -> IO ()
logicalOnRecv :: (ExternalIdentity -> Message -> IO ()) -> IO ()
```

The logical sending layer must keep a state containing information about known mappings from external identities to physical addresses at which they can be contacted. This state is used to inform logical routing, which maps logical sends to (possibly multiple) physical sends. Logical routing can also take into account compositionality of identities - e.g., if routes to Alice, Bob, and Charlie are known, but a route to (Alice && Bob && Charlie) is not, individual routes can be automatically tried. This state is constructed from physical address announcement messages sent (and signed) by particular external identities. The logical routing algorithm can also consult local agent preferences as to how much bandwidth and compute they're willing to spend, and how (for a particular message) to trade between reliability, minimal bandwidth usage, privacy, etc.

```haskell
type LogicalRoutingState
```

## Physical send

Underlying physical networking layers are expected to expose an opaque type `PhysicalAddress`, to which messages can be sent and from which they might be receieved. Physical networking could be instantiated by a base physical protocol such as TCP/IP or UDP/IP, or a more complex layered one such as Tor or a mixnet. The physical layer need provide only two functions, `send` and `onRecv`, which act as one would expect. Messages are assumed to be delivered either completely or not at all, but the physical layer is not expected to provide any form of authentication, ordering, or reliable delivery - those concerns are handled by higher layers.

> TODO: Work remains to be done to integrate the privacy properties which might be provided by Tor or a mixnet into the privacy preferences and trust graph which the higher-level logical layers might be able to reason about.

```haskell
type PhysicalAddress

send :: PhysicalAddress -> ByteString -> IO ()
onRecv :: (PhysicalAddress -> ByteString -> IO ()) -> IO ()
```

Physical routing also requires an underlying state, but as existing stacks can handle this perfectly well we keep all physical routing state and algorithms out of scope of the Anoma protocols.

&nbsp; 72