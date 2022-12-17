# Identity



# Identity Layer

The base abstraction of the protocol is knowledge-based identity, where identity of observers is defined on the basis of whether or not they know some secret information (to derive the Internal Identity).

## Basic assumptions & definitions

- `hash` is a collision-resistant one-way function
- We assume a shared execution semantics, such that functions have a canonical serialisation. (We do not assume that equivalent functions have the same serialisation, only that functions have a serialisation which is understood and can be executed by participating observers)

## Identity

Identity in the protocol is defined by a cryptographic interface. Observers can use private information (likely randomness) to create an internal identity, from which they can derive an external identity to which it corresponds. The external identity is a name which can be shared with other parties. The observer who knows the internal identity can sign messages, which anyone who knows the external identity can verify, and anyone who knows the external identity can encrypt messages which the observer can decrypt. This identity interface is independent of the particular cryptographic mechanisms, which may vary.

### External Identity

Each External Identity has the canonical representation:

`hash(verify', encrypt')` with: 
- `verify'(msg) -> bool` to verify the originator of a message
- `encrypt'(msg) -> cyphertext` to encrypt a message which any recipient who knows the internal identity can decrypt


For example, `key` can be a public key in a standard asymmetric public-key encryption scheme, where `verify'` and `encrypt'` are curried with the key as `verify(key)` and `encrypt(key)`.

> Note: consider requiring ZKP that someone knows internal identity s.t. for some (a random?) `m` they can sign and decrypt it. (TODO - cryptographers)

### Internal Identity 

The Internal Identity is constituted by knowledge of the following functions:

- `sign'(data) -> signed data`
- `decrypt'(cyphertext) -> plaintext`

such that any `sign'`-ed message is accepted by `verify'` and any `encrypt'`-ed message is opened by `decrypt'`.

For example, these can be the signature generation and decryption functions in a standard asymmetric public-key encryption scheme, where `sign'` and `decrypt'` are curried with the secret as `sign(secret)` and `decrypt(secret)`.

### Special Identities

To illustrate the generality we can come up with the following special keys (~ LL: initial and terminal objects with respect to information).

#### "True / All"

Anyone can sign and decrypt (`verify'` returns true and `encrypt'` returns the plaintext). No secret knowledge is required, so all observers can take on this identity.

#### "False / None"

No one can sign or decrypt (`verify'` returns false and `encrypt'` returns empty string). No secret knowledge exists that fulfills these requirements, so no observer can take on this identity.
