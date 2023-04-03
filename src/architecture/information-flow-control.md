# Information flow control

- Information flow control _between identities_, and _over time_ (possibly subject to assumptions)

- In general, privacy can be provided for any kind of verification of part of the logical DAG if the verifiable computation scheme in use is zero-knowledge.
- Consensus providers can use distributed key generation, where the shared key becomes part of their `encrypt` function, alongside internal programmable threshold decryption in order to provide transaction submission privacy, batch fairness (when used along with guarantees about how they internally process transactions). 
- Fully homomorphically encrypted state does not require any special treatment from the architectural perspective (since state lives in only one location), just predicates which encode the FHE evaluation functions. FHE can also be combined with distributed key generation and threshold decryption for threshold FHE.
- It should be possible to select the cryptographic technique required on the basis of (a) acceptable assumptions (are BFT assumptions OK for privacy?) and (b) shared ordering requirements (if no shared ordering requirement, ZKPs will suffice, if yes, FHE or threshold FHE is required).

> TODO: Spell out these combinations in more detail.

> TODO: For dynamic provisioning, it seems like we'd need a sort of "Ferveo on-demand" where everyone generates key shares, but those are combined into public keys on-demand (compositionally) instead of as part of the DKG protocol. Is this feasible?

> TODO: Clearly describe how commitments & nullifiers can work in the linear resource logic DAG.
