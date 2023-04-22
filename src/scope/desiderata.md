
- talk about sub-network part
- scaling
- separation of syntax and (identity) semantics
- observer-dependence
- information locality


...


given these requirements and assumptions, the anoma protocol herein described is unique up to isomorphism.



# Desiderata

In this context, with the specified primitives, the protocol should provide to an agent the ability to:

- Create cryptographically-content-addressed history
    - e.g. issue messages from a private/public keypair that they create from local randomness
- Validate cryptographically-content-addressed history that they learn about from elsewhere
    - Validation covers correct instantiation (cryptographically-content-addressed), linear consumption from instantiation, and validity of predicates (state transition rules)
    - Privacy provisions allow for any arbitrary part of this history known by another agent to be revealed by that agent to this agent while retaining all of these validity guarantees
        - e.g. that agent can reveal to this agent a message at the end of some chain of history and prove that the history is valid and terminated in that message - this message (if desired) can then be built upon by the agent who now knows it
        - knowledge of a message is a necessary but not sufficient condition in order to consume and/or create history on top of it
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