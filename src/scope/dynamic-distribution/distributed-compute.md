# Distributed compute

The distributed content-addressed compute layer is responsible for providing a simple interface for delegating computation: agents, voluntarily, elect to perform computations for other agents, content-addressed by a hash of the data being computed over and a predicate relation which must be satisfied over the data and computational result.

We assume a verifiable computation scheme as defined previously.

```haskell
data ComputeRead
  = ComputeRead {
    scheme :: ProofScheme,
    address :: Hash,
    predicate :: Hash -> Hash -> Bool
  }
```

```haskell
data ComputeWrite
  = ComputeWrite {
    scheme :: ProofScheme,
    address :: Hash,
    predicate :: Hash -> Hash -> Bool,
    result :: Hash,
    proof :: ByteString
  }
```

Note that computational delegation is specified by a _predicate_ which the result must satisfy, not a function to run in order to _compute_ the result from the data. There may be multiple ways to compute a result satisfying the predicate - it is up to the agent querying to ensure that the predicate correctly encodes the relation in which they are interested.

Compute read and write requests are optionally signed - the signature is not required for compute integrity, but it may be useful for anti-DoS and proof-of-retrievability.

Upon retrieving a result with a `ComputeRead` call, an agent can check that they received the correct result by checking that `verify(address, result, predicate, proof)` is true. If the underlying scheme is succinct, this check is constant-time in the complexity of the predicate - and if we further assume that the input and output data of the computation can be addressed by hash, then specific elements of the result could be retrieved & verified later with Merkle proofs or similar. 

Computation can be cached in the storage layer at `hash(scheme, address, predicate)`, by storing `result` and `proof`, and nodes interested in the same computation verifiable with the same scheme can just fetch previously computed results and call `verify` as above. Many computations are expected to be incremental, in that a `proof` and `result` from a computation on a previous part of an append-only data structure can be reused to create a `proof` and `result` valid for the same computation performed on an extended version of this data structure. In general, the version of the compute read interface exposed to higher level layers can be expected to check the cache first, and only then request computation from the network. Adjustments in the amount of caching versus recomputation can be made dynamically on the basis of the relative prices of storage, compute, and bandwidth.

We expect that trusted delegation (with a honesty assumption of the verifiable computation scheme) will be used only between highly-entangled agents - but there it can be very useful (e.g. for automatic delegation of compute from an edge device to a trusted server). For now, this layer does not deal with incentives for performating delegated verifiable computation for untrusted nodes - this can be added by including token payment conditional on provision of a correct computational result - but the basic interface from the perspective of other layers should be able to remain consistent with this simple model.

Computation is generally unordered and observations of computations performed are mostly not expected to be included in the physical DAG, although they can occaisionally be if certain agents wish to track metadata.