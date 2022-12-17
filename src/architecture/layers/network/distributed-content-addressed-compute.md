# Distributed content-addressed compute


## Compute

The distributed content-addressed compute layer is responsible for providing a simple API for delegating computation: nodes, voluntarily, elect to perform computations for other nodes, content-addressed by a hash of the data being computed over and a predicate relation which must be satisfied over the data and computational result. 

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

```=haskell
data ComputeRead = ComputeRead {
  address :: Hash,
  predicate :: Hash -> ByteString -> Bool
}
```

```=haskell
data ComputeWrite = ComputeWrite {
  result :: Hash,
  proof :: ByteString
}
```

Compute read and write requests are optionally signed - the signature is not required for compute integrity (except as in the proof), but it may be useful for anti-DoS and proof-of-retrievability.

Upon retrieving a result with a `ComputeRead` call, a node can check that they received the correct result by checking that `verify(address, result, predicate, proof)` is true. If the underlying scheme is succinct, this check is constant-time in the complexity of the predicate - and we further assume that the input and output data of the computation can be addressed by hash, then specific elements of the result could be retrieved & verified later with Merkle proofs or similar. 

Computation can be cached in the storage layer at `hash(scheme, address, predicate)`, by storing `result` and `proof`, and nodes interested in the same computation verifiable with the same scheme can just fetch previously computed results and call `verify` as above. Many computations are expected to be incremental, in that a `proof` and `result` from a computation on a previous part of an append-only data structure can be reused to create a `proof` and `result` valid for the same computation performed on an extended version of this data structure. In general, the version of the compute read API exposed to higher level layers can be expected to check the cache first, and only then request computation from the network.

We expect that trusted delegation (with a honesty assumption, without verifiable compute) will be used only between highly-entangled nodes - but there it can be very useful (e.g. for automatic delegation of compute from an edge device to a trusted server). For now, this layer does not deal with incentives for performating delegated verifiable computation for untrusted nodes - this can be added by including credit payment conditional on provision of a correct computational result - but the basic interface from the perspective of other layers should be able to remain consistent with this simple model.

Computation is generally unordered and observations of computations performed are mostly not expected to be included in the physical DAG, although they can occaisionally be if certain nodes wish to track metadata.
