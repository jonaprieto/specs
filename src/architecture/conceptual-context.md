# Conceptual context

The Anoma architecture operates on the basis of *[agents](../glossary.md#agents) in a [world](../glossary.md#world)*. 

0. An Agent is ...

1. _Agents_ are assumed to have the ability to:
   - generate local randomness, 
   - locally store and retrieve data, 
   - perform arbitrary classical computations, and
   - send and receive [messages](../glossary.md#message) over an arbitrary, asynchronous physical network.

2. Agents _may_ have local input (e.g. human user input) and/or local randomness (e.g. from a hardware random number generator).

3. Agents can _join_ and _leave_ the world at any time.

4. The world is message-passing transparent, meaning that any agent has access to the list of messages sent and received by any other agent. 

<!-- This paragraph is quite confusing to me. -->
The architecture does not presume any sort of global view or global time. It also does not presume any particular _motivations_ of agents, but rather describes the state of the system as a function of the decisions taken by agents over (partially ordered) time. 
<!-- I dont' understand this sentence, what's the main intention of it. -->
Knowledge of all decisions taken by agents in a subset of history determines the state of that subset of the system at the point of conclusion of that history.

> Note: The concept of _agent_ is similar to that of _process_ as used in the distributed systems literature. We use "agent" to emphasize non-determinism (local randomness and/or external user choice input) and possible agency (in the sense of decision-making which impacts the state of the system). The latter is especially important as causal accounting requires correspondence between the state of the system and state of the world, a correspondence which can only be maintained as a product of individual data inputs by agents which themselves correspond in local ways, as the protocol itself has no knowledge of the state of the world.

```haskell
type Agent

class Monad m => AgentContext m where
    random :: Finite a => m a

    set :: ByteString -> ByteString -> m ()
    get :: ByteString -> m (Maybe ByteString)
```

The rest of this specification defines the _Anoma protocol_, which is specific logic that agents run to read, create, and process messages. For convenience, the Anoma protocol shall be referred to henceforth as just _the protocol_.

```
type Protocol
```
