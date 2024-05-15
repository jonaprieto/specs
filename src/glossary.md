<p><a target="_blank" href="https://app.eraser.io/workspace/9J7P2Ag5BMMkvmTKhWkl" id="edit-in-eraser-github-link"><img alt="Edit in Eraser" src="https://firebasestorage.googleapis.com/v0/b/second-petal-295822.appspot.com/o/images%2Fgithub%2FOpen%20in%20Eraser.svg?alt=media&amp;token=968381c8-a7e7-472a-8ed6-4a6626da5501"></a></p>

# Glossary
## How to use this Glossary
Since this specification is (for now at least) a work in progress, many sections are still in flux.
To make it easier to understand, as well as preserve flexibility for refactoring, we strive to maintain this glossary as described below:

### Introducing New Terminology
1. When introduction a new term, we list it here and link to the section of the spec containing its definition.
2. Once a section has become reasonably stable we add short explanations to the terms used in them.
### Using Existing Terminology
1. When using a term that has been defined elsewhere, we list it here and link to an external reference, which should captures the sense of our usage.
2. Once a section has become reasonably stable we add short excerpts to the citations.
An existing term should be included in the following cases (incomplete list):

- If it is central to the understanding of concepts in the spec.
- If it is hard to look up, e.g. different subfields have different definitions.
- If it is likely that the intended audience of the containing sections is unfamiliar with it.
## Collaborative Glossary Maintenance
To get the glossary into shape, its maintenance will have the following phases:

1. Section authors add terms introduced and used in their sections.
2. Reviewers point out omissions (e.g. in the [﻿glossary wishlist](https://github.com/anoma/specs/issues/148) ).
After a first pass of populating the glossary, the two phases will continue to happen in parallel for a while.

Since the decision whether to include an existing term or not will be more of a soft question,
reviewer and reader feedback will be especially important.

# Definitions
## Anoma protocol
The Anoma protocol is the logical framework which [﻿agents](#agent) use to read,
create, and process [﻿messages](#message).

## Agent
An _agent_ is a non-deterministic, stateful entity which can send and receive
messages.

The term "agent" is similar to "process" used in distributed systems. However,
"agent" is used to highlight the possibility of non-deterministic behaviour,
such as random events or choices made by external users. The term also
emphasizes the idea of decision-making that can affect the state of the system.
This is important for ensuring that the state of the system accurately reflects
the state of the world. To achieve this, individual agents must provide data
inputs that correspond in local ways, as the system protocol itself does not
have direct knowledge of the state of the world.

Read more about agents in the [﻿conceptual context](scope/conceptual-context.md#conceptual-context).

## Canonical serialization
A _canonical serialization_ refers to a standardized way of representing data or
functions as a series of bytes that can be transmitted across a network.

Canonical serialization are fully discussed in [﻿Prerequisites Primitives](architecture/prerequisite-primitives.html#canonical-serialization) 

## Turing-equivalent
"Turing-equivalent" means that the functions and data being transmitted can be
computed by a Turing machine, a well-known theoretical model of computation.

## Message
A _message_ is any datum sent between agents.

## State
A _state_ may refer to the state of an agent, the state of the world, or the state of the system.

- The _state of an agent_ is the set of all data stored by the agent.
- The _state of the system_ is a function of the decisions taken by agents
over (partially ordered) time.
- The _state of the world_ is the set of
data related to the "real world" that is observed by and of interest to the agents.
## System
A _system_ is a virtual environment which
consists of a set of agents interacting with each other.

Read more about the world in the [﻿conceptual context](scope/conceptual-context.md).


<!--- Eraser file: https://app.eraser.io/workspace/9J7P2Ag5BMMkvmTKhWkl --->