# Glossary

# Anoma protocol

The Anoma protocol is the logic framework which [agents](#agents) use to read,
create, and process [messages](#message).

# Agent

An *agent* is a non-deterministic, stateful entity which can send and receive messages.

The term "agent" is similar to "process" used in distributed systems. However, "agent" is used to highlight the possibility of non-deterministic behaviour, such as random events or choices made by external users. The term also emphasizes the idea of decision-making that can affect the state of the system. This is important for ensuring that the state of the system accurately reflects the state of the world. To achieve this, individual agents must provide data inputs that correspond in local ways, as the system protocol itself does not have direct knowledge of the state of the world.

<!--
The concept of _agent_ is similar to that of _process_ as used in the distributed systems literature. We use "agent" to emphasize non-determinism (local randomness and/or external user choice input) and possible agency (in the sense of decision-making which impacts the state of the system).

The latter is especially important as *causal accounting* requires correspondence between the state of the system and state of the world, a correspondence which can only be maintained as a product of individual data inputs by agents which themselves correspond in local ways, as the protocol itself has no knowledge of the state of the world.
-->

Read more about agents in the [conceptual context](../architecture/conceptual-context.md).

# Canonical serialization

A *canonical serialization* refers to a standardized way of representing data or
functions as a series of bytes that can be transmitted across a network. 

# Turing-equivalent

"Turing-equivalent" means that the functions and data being transmitted can be
computed by a Turing machine, a well-known theoretical model of computation.

# Message

A *message* is any data sent between agents.


# State

A *state* may refer to the state of an agent, the state of the world, or the state of the system.

- The *state of an agent* is the set of all data stored by the agent.

- The *state of the system* is a function of the decisions taken by agents
over (partially ordered) time.

- The *state of the world* is the set of 
data related to the "real world" that is stored by the agents.

# System


A *system* is a virtual environment which
consists of a set of agents interacting with each other.

Read more about the world in the [conceptual context](../architecture/conceptual-context.md).
