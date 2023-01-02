# Conceptual context

The Anoma architecture operates on the basis of _agents_ in a _world_. _Agents_ are assumed to have the ability to generate local randomness, locally store and retrieve data, perform arbitrary classical (Turing-equivalent) compute, and send and receive messages over an arbitrary, asynchronous physical network. Agents _may_ have local (e.g. human user) input. Agents operate in a _world_, which consists of other agents of the same (abstract) capacities, with whom they may be able to communicate. The _world_ is open, in that agents can join and leave at any time -- from the architectural perspective, we can only speak of and reason about the perspective of a particular agent, i.e. which messages they have sent and received, and in what (local) order.

The architecture does not presume any sort of global view or global time. It also does not presume any particular _motivations_ of agents, but rather describes the state of the system as a function of the decisions taken by agents over (partially ordered) time. Knowledge of all decisions taken by agents in a subset of history determines the state of that subset of the system at the point of conclusion of that history.

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
