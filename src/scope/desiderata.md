Anoma aims to allow _agents_ to:

- Create, validate, and merge cryptographically content-addressed histories.
    Cryptographically content-addressed histories are histories issued by an agent with private information, such that only an agent with that private information could create history addressed in that way. Validation covers correct instantiation, correct execution since instantiation (state transition rules), and applicable constraints (e.g. linearity).
- In any arbitrary sub-network with compatible trust assumptions, come to consensus on mutually preferred state changes without relying on any agent outside the sub-network, in a way which can be proved to a third party.
- Reason about the information flow which results from sending a particular message subject to trust assumptions that the agent is willing to make.

_Scaling_ 

- Agents should not need compute/storage more than a constant factor w.r.t the transactions they are directly involved with in order to process history with which they want to interact.

> Note: What is the minimal set of cryptographic assumptions needed to satisfy these desiderata? Should be just one-way hash functions ~ i.e. P /= NP.

> TODO: Prove that Anoma is unique up to isomorphism in some appropriate class (given these requirements and assumptions).


---

Suppose that program $P$ instantiates the Anoma protocol, and that an observer $O$ can interact with $P$ by sending and receiving messages (locally, in the sense that the interface is trusted). 

Assume that:
- The observer $O$ makes some _trust assumptions_ about how other agents $A_1, A_2, ... A_n$ will behave. These trust assumptions, for an agent $A$, are always of the form of a predicate over messages which $A$ is expected to send, possibly in response to messages they have received. For example, an assumption could be of the form that $A$ will never send two messages $M_1$ and $M_2$ such that, for some predicate $P$, $P(M_1, M_2) = 1$ (safety-related), or of the form that in response to receiving message $M$, $A$ will eventually respond with message $M'$, where, for some predicate $P$, $P(M, M') = 1$ (liveness-related). 

A valid implementation of Anoma must guarantee:
- _Consistency_: if _in fact_ $O$ is _correct_ about their trust assumptions, i.e. for each $A_n$ about which $O$ makes a trust assumption, $A_n$ does _in fact_ behave in the way in which $O$ assumes that they will, then for any other observer $O'$, if $O$ and $O'$ are both running program $P$, in response to an arbitrary query message $Q$, $P$ will respond to $O$ and $O'$ with the same response $R$.
- _Liveness_: if _in fact_ $O$ is _correct_ about their liveness-related trust assumptions, i.e. for each $A_n$ about which $O$ makes a trust assumption, $A_n$ does _in fact_ behave in the way in which $O$ assumes that they will, then for any other observer $O'$, if $O$ and $O'$ are both running program $P$, in response to an arbitrary input message $M$, $P$ will eventually respond to $O$ and $O'$. (note: $P$ needs to have the same private information)

imagine that we had an oracle?

---

BRAINSTORMING
- compositionality? interactions should compose
- heterogeneous trust
    - agents trust other agents to enforce predicate P on their executions?
- agents can make commitments
    - commitments govern relations between messages
    - for example, could be a commitment never to issue messages which do not reference each other (total order violation)
    - could be commitment to respond to storage request with storage response (perhaps within some time)
    - could be commitment to not send a message unless some predicate P is true of contents referenced by it (optimistic execution)
- agents can trust other agents (or not) to adhere to their commitments
- WHAT ANOMA SHOULD GUARANTEE
    - if IN FACT the trust assumptions are correct, and the commitments are adhered to, the invariants should hold
    - something about observers... if in fact ... then ANY observer will see ... (consensus) ~ a sort of perspective-independence

---

OLD PART


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
