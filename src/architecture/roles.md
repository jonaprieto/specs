# Roles

A _role_ is a rule used by an agent to automatically send certain messages when they receive others or after local time has passed. For example, agents might automatically route messages not destined for them but destined for other agents which they know how to reach upon receipt of those messages, automatically combine partial transactions when they can be matched by a solver algorithm known to the agent, or automatically issue vote messages for a consensus instance of which the agent is part.

```haskell
type Role = LocalState -> [Message]
```

Roles are _not_ part of the correctness, soundness, or consistency semantics of the protocol, but they _are_ part of liveness semantics (in general).

```haskell
```