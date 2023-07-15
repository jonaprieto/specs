# Identity

The base abstraction of the protocol is a knowledge-based identity interface, where the identity of an agent is defined entirely on the basis of whether or not they know some secret information.

Agents can use private information (likely randomness) to create an internal identity, from which they can derive an external identity to which it corresponds. The external identity is a name which can be shared with other parties. The agent who knows the internal identity can sign messages, which any agent who knows the external identity can verify, and any agent who knows the external identity can encrypt messages which the agent with knowledge of the internal identity can decrypt. This identity interface is independent of the particular cryptographic mechanisms, which may vary.

An _identity_ is defined by two pairs of functions which are inverse to each other:

- `sign` and `verify`, where `sign` takes a string to sign and produces a signature such that any `sign`-ed message is accepted by `verify`
- `encrypt` and `decrypt`, where `encrypt` takes a string to encrypt such that any `encrypt`-ed message is opened by `decrypt`

```haskell
data Identity where
    sign :: ByteString -> ByteString
    verify :: ByteString -> ByteString -> Bool

    verify m (sign m) = 1

    encrypt :: ByteString -> ByteString
    decrypt :: ByteString -> Maybe ByteString

    decrypt . encrypt = pure
```

The `verify` and `encrypt` functions together form the _external identity_, while the `sign` and `decrypt` operations together form the _internal identity_. In general, the external identity can be derived from the internal identity, but not vice-versa. The internal identity is a self-contained name which can be used to send messages from and decrypt messages sent by another agent to the corresponding external identity, while the external identity is a self-contained name which can be used to verify messages from and encrypt messages to any agent with knowledge of the internal identity.

For example, an identity can be the signature generation and decryption functions in a standard asymmetric public-key encryption scheme with secret key `secret` and public key `key`, where:
- `sign` and `decrypt` are curried with the secret as `sign'(secret)` and `decrypt'(secret)`
- `verify` and `encrypt` are curried with the key as `verify'(key)` and `encrypt'(key)`

The canonical representation of an external identity is defined as `hash(verify, encrypt)`.

> NOTE: Consider requiring ZKP that someone knows internal identity s.t. for some (a random?) `m` they can sign and decrypt it. This would go in the external identity in order to provide a guarantee that there is _an_ agent with knowledge of the internal identity. Unclear yet if necessary.

## Composition

Identities can be composed both internally and externally, by both conjunction and disjunction. Conjunction (`&&`) and disjunction (`||`) refer here to the secret information, such that to compose external identities by conjunction creates an external identity such that `sign`ed messages can be decrypted only by an agent with knowledge of _both_ internal identities and `verify` will return true only if a valid signature from each composed identity is provided, while to compose external identities by disjunction creates an external identity such that `sign`ed messages can be decrypted with knowledge of _either_ internal identity and `verify` will return true if a valid signature from either composed identity is provided.

### Transparent Example

Any agent with knowledge of two external identities `a` and `b` can transparently compose them as follows, without requiring interaction of the constituent identities:
- Under conjunction, `verify(msg, sig) := a.verify(msg, sig.0) && b.verify(msg, sig.1)` and `encrypt(msg) := a.encrypt(b.encrypt(msg))`
- Under disjunction, `verify(msg, sig) : a.verify(msg, sig) || b.verify(msg, sig)` and `encrypt(msg) := (a.encrypt(msg), b.encrypt(msg))`

The canonical representation of composed external identities is defined the same as above, just with the new `verify` and `encrypt` functions.

Compositions can be chained to create arbitrary combinations. For example, "threshold" identities, e.g. a 2-of-3 between `a`, `b`, and `c`, can be obtained with `(a && c) || (a && b) || (b && c)`. Composition of identities is used throughout the protocol and implementations may substitute more efficient operational representations (e.g. different cryptographic schemes) where appropriate.

In this transparent, non-interactive example (de-)composition information is available by construction.

> TODO: Do more efficient operational representations require different canonical serialisations? Can we make this nicely abstract still? 
> Note: Operators (`&&`, `||`) can be implemented by different cryptographic operations. Which one is to be used should be encoded in an Identity or as side information for it.

### Opaque Example

A group of agents can also compose an opaque identity interactively, s.t. composition information is not available to the outside.

One example would be a using distributed key generation and a threshold cryptosystem [e.g. Threshold RSA](https://iacr.org/archive/eurocrypt2001/20450151.pdf).

Here the agents compute _one_ RSA keypair together, with only shares of the private key being generated by each agent. Decryption of messages encrypted to the single public key then requires cooperation of a subset of agents holding key shares, fulfilling the threshold requirements.

Observers outside of this group will only see a single `External Identity` based on a regular RSA public key.

#### Side Information
The group has the option to (selectively) supply side information to enable decomposition. For example, identities which control shares of keys and details on the cryptographic scheme which are semantically relevant for decomposition. In the above example, that could be a threshold definition of the form `n-out-of-k`, with values `n`, `k` being given.

## Special identities

To illustrate the generality we can come up with the following special identities:

#### "True / All"

Anyone can sign and decrypt (`verify` returns true and `encrypt` returns the plaintext). No secret knowledge is required, so all agents can take on this identity.

The true identity preserves structure under conjunction (`x && true == x`) and forgets structure under disjunction (`x || true == true`).

#### "False / None"

No one can sign or decrypt (`verify` returns false and `encrypt` returns empty string). No secret knowledge exists that fulfills these requirements, so no agent can take on this identity.

The false identity forgets structure under disjunction (`x && false == false`) and preserves structure under disjunction (`x || false == x`).

## Observer-dependence

The basic interface of an identity is stateless, but identities may also be _stateful_, where an identity is defined with respect to a logical DAG (described later). In that case, the logical DAG is taken as an additional parameter to `encrypt` and `verify`, and the external identity commits to the predicate function of the logical DAG and the `verify` function at the logical time of instantiation (such that from any later version of the identity there will exist a valid chain of signatures back to the origin point).

```
```

## Identity Engine

Side information about opaque Identities, as well as routing information, etc. are stored in the [commitment engine](../engines/commitment.md).
