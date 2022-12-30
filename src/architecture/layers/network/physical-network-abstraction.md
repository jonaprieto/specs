> TODO: Write this out in more detail. Feel free to skip for now.

# Physical network abstraction

The physical network abstraction layer is responsible for:
- Keeping and continuously updating routing tables mapping external identities and compositions thereof to IP addresses (and compositions thereof)
- Keeping and continuously updating routing tables tracking which agents are interested in which topics
- Efficient pub-sub topic broadcast (particularly for messages to the "all" identity)
- Frequently testing latency to other known external identities and providing this as a measure of physical entanglement which can be used by higher layers
- Routing messages to and from other agents, including those _not_ destined for this agent (this will require some configuration from higher layers for anti-DoS)
    - Also, keeping track of "routing kudos" in some approximate fashion which doesn't incur too much overhead. 