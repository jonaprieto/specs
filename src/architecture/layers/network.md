# Network


# Network

Observers can send messages to each other by `send(identity, msg)` where `identity` is an external identity, and they can handle received messages with some `onRecv(msg)` (to which messages addressed to them will be sent). We assume an asynchronous physical network in the general case, where liveness w.r.t. some message set and some observers will require eventual receipt of all messages in the set by the observers in question.

## Messages

A `Message` is the lowest layer type, sent around between nodes. `Message` subtypes include `Observation`s, which capture partial ordering information used to craft the physical DAG, `Storage` read/write requests and responses for the distributed content-addressed data storage layer, `Compute` requests and responses for the distributed content-addressed compute cache layer, and `Network` P2P metadata requests and responses for gossiping external identity / IP associations, routing information, uptime information, etc. (full details TBD).

