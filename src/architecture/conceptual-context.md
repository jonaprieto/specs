# Conceptual context

The Anoma architecture operates on the basis of
*[agents](../glossary.md#agents)*. The architecture does not presume any sort of
global view or global time. It also does not presume any particular
_motivations_ of agents, but rather describes the state of the
[system](../glossary.md#system) as a function of the decisions taken by agents
over (partially ordered) time. 

1. *Agent* is a primary notion in the Anoma protocol that aims to extend/replace
   the notion of _process_ in the Distributed Systems literature.

2. _Agents_ are assumed to have the ability to:
   - generate local randomness, 
   - locally store and retrieve data, 
   - perform arbitrary classical computations, 
   - create, send, receive and read [messages](../glossary.md#message) over an
     arbitrary, asynchronous physical network.
   

2. Agents _may_ have local input (e.g. human user input) and/or local randomness
   (e.g. from a hardware random number generator).

3. Agents can _join_ and _leave_ the [system](./../glossary.md#system) at any
   time.

4. Knowledge of all *actions* committed by agents are recorded in the *history.
   The *state* of the system at any point in time is a function of the history
    of actions committed by agents up to that point in time.

<!-- 
We can use Juvix syntax instead of Haskell syntax for the following snippets. I'm commenting
this out as I don't see they add much clarity to the spec, (at least not now)

```juvix

```haskell
type Agent

class Monad m => AgentContext m where
    random :: Finite a => m a

    set :: ByteString -> ByteString -> m ()
    get :: ByteString -> m (Maybe ByteString)
```

 -->

The rest of this specification defines the _Anoma protocol_, which is specific logic that agents run to read, create, and process messages. For convenience, the Anoma protocol shall be referred to henceforth as just _the protocol_.

<!-- 

```haskell
type Protocol
```

 -->
