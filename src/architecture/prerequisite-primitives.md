# Prerequisite primitives

## 

functions & data have canonical serialisation

## Cryptographic components

### Collision-resistant one-way hash function

- `hash` is a collision-resistant one-way function

### Verifiable computation scheme

We assume a verifiable computation scheme, e.g., subject to cryptographic _or trust_ assumptions, nodes have access to the following interface:

```
type Proof

prove :: a -> b -> (a -> b -> Bool) -> Proof

verify :: a -> b -> (a -> b -> Bool) -> Proof -> Bool
```

s.t. `verify(a, b, predicate, prove(a, b, predicate)) = 1` iff. `predicate a b = 1`, and `verify(_, _, _, _) = 0` otherwise, except with negligible probability (no false positives).

This can be instantiated in different ways:
- Trivially, but without succinctness, as `verify(a, b, predicate, _) = predicate a b`.
- With a honesty assumption, with succinctness, by `verify(a, b, predicate, proof)` checking a signature by a known external identity over `(a, b, predicate)` in `proof` (basically attesting to `predicate a b = 1`). As the computation is still verifiable, a signer of `(a, b, predicate)` where `predicate a b = 0` could be held accountable by anyone else who later performed the computation.
- With a non-interactive succinct proof scheme (e.g. SNARK/STARK), with both verifiability and succinctness subject to the scheme-specific cryptographic assumptions.

Global consensus on the verifiable computation scheme is not required, but nodes must agree on a particular scheme to use for a particular computation operation.
