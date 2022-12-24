# Network

Agents can send messages to each other by `send(identity, msg)` where `identity` is an external identity, and they can handle received messages with some `onRecv(msg)` (to which messages addressed to them will be sent). We assume an asynchronous physical network in the general case, where liveness with regard to some message set and some agents will require eventual receipt of all messages in the set by the agents in question.

Note that sending to multiple identities can be accomplished by composition of identity by disjunction as defined previously, and blind broadcast can be accomplished by using the "all" identity.

A separate physical network abstraction layer is responsible for keeping appropriate routing tables to map external identities (including compositions thereof) to known IP addresses and route messages around. This physical layer has many specific optimisation concerns which are out of scope of the abstract specification.

> TODO: Link to part of Typhon networking spec. Also, clearly define (somewhere) what entanglement data should be provided to / used by the physical network layer, this is probably important.

## Messages

A `Message` is the lowest layer type, sent around between nodes. `Message` subtypes include `Observation`s, which capture partial ordering information used to craft the physical DAG, `Storage` read/write requests and responses for the distributed content-addressed data storage layer, `Compute` requests and responses for the distributed content-addressed compute cache layer, and `Network` P2P metadata requests and responses for gossiping external identity / IP associations, routing information, uptime information, etc. (full details TBD).