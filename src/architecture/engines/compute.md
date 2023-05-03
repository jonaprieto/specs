# Compute

The _compute engine_ is responsible for performing expensive computation, i.e. searching for witnesses to computation which are (in general) in the complexity class NP. Frequently, however, more efficient search algorithms will be known for particular predicates.

## State

```haskell
data ComputeEngineState = ComputeEngineState {
    predicate :: hash
}
```

## Input messages

```haskell
data ComputeRequest = ComputeRequest {

}
```

## Output messages

```haskell
data ComputeResult = ComputeResult {
    predicate :: Hash,
    result :: Hash
}
```

- State type: local cache
- Input: compute requests ("find input satisfying this predicate")
- Output: compute solutions ("input satisfying this predicate")
- Preferences: whether/how to share compute resources over the network
- Accounting: how much compute was actually shared

Input: Compute requests
Output: Compute solutions
Preferences: Whether to share compute resources over the network
Accounting: Compute actually shared

The _compute_ engine is responsible for 