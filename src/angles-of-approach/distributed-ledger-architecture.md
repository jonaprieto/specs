# Distributed ledger architecture

Anoma started out of the world of distributed ledger ("blockchain") systems design, and the protocol owes its design to previous blockchain architectures perhaps more than anything else. However, Anoma makes very different design decisions than prior blockchain systems, not only in the specifics of individual components but also in the very definition of the problems the architecture aims to solve. Design goals of many current blockchain systems are often warped by the contours of local incentive space ("wen token"), and it can be difficult to distinguish contingent short-term market structures from necessary long-term ones. To aid in the reader's understanding of what Anoma does and why, we describe here how Anoma compares to Cosmos, Ethereum, and Zcash, the three prior projects from which Anoma draws the most inspiration. If you are not familiar with any of these projects, this section will probably not be helpful.

> Note: The descriptions here are focused exclusively on a comparison between protocol architectures -- they are intended to illuminate similarities and differences, not to criticize -- indeed, Anoma builds upon and incorporates many ideas from the protocols described here, couldn't have come into existence without them, and aims to interoperate with all of them.

- [Anoma vis-a-vis Zcash](./distributed-ledger-architecture/anoma-vis-a-vis-zcash.md)
- [Anoma vis-a-vis Cosmos](./distributed-ledger-architecture/anoma-vis-a-vis-cosmos.md)
- [Anoma vis-a-vis Ethereum](./distributed-ledger-architecture/anoma-vis-a-vis-ethereum.md)