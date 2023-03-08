# Glossary

# Anoma protocol

The Anoma protocol (*the* protocol for short) is the logic framework which
[agents](#agents) use to read, create, and process [messages](#message).

# Agents

An *agent* is a non-deterministic, stateful entity which can send and receive messages.

The concept of _agent_ is similar to that of _process_ as used in the distributed systems literature. We use "agent" to emphasize non-determinism (local randomness and/or external user choice input) and possible agency (in the sense of decision-making which impacts the state of the system).

The latter is especially important as *causal accounting* requires correspondence between the state of the system and state of the world, a correspondence which can only be maintained as a product of individual data inputs by agents which themselves correspond in local ways, as the protocol itself has no knowledge of the state of the world.

Read more about agents in the [conceptual context](../architecture/conceptual-context.md).

# Message

A *message* is any data sent between agents.

# World

A *word* is a virtual environment which
consists of a set of agents interacting with each other.

Read more about the world in the [conceptual context](../architecture/conceptual-context.md).


# State

A *state* may refer to the state of an agent, the state of the world, or the state of the system.

- The *state of an agent* is the set of all data stored by the agent.

- The *state of the world* is ... (not clear yet)

- The *state of the system* is a function of the decisions taken by agents
over (partially ordered) time.

# System

A *system* is ..