<p><a target="_blank" href="https://app.eraser.io/workspace/p3mzc3UZwfSoGHRV34dp" id="edit-in-eraser-github-link"><img alt="Edit in Eraser" src="https://firebasestorage.googleapis.com/v0/b/second-petal-295822.appspot.com/o/images%2Fgithub%2FOpen%20in%20Eraser.svg?alt=media&amp;token=968381c8-a7e7-472a-8ed6-4a6626da5501"></a></p>

# Tokens
_Tokens_ are transferrable units of accounting.

The resource logic of tokens enforces two properties:

- _Supply conservation_ (implicitly) - in any transaction, tokens must be conserved. This is enforced using the balance check.
- _Ownership_ - any transaction which consumes tokens owned by resource `R`  must be authorized by `R` . This is checked by requiring the presence of a message from `R`  that authorises the consumption of tokens subject to an arbitrary predicate being satisfied in the partial transaction in which the tokens are consumed.
- _Minting_ - tokens may reference a particular resource `R`  which is allowed to mint new tokens of the denomination (ex nihilo).
Tokens can include arbitrary properties (as data), which may be meaningful to other applications. Properties in static data affect fungibility (determine different tokens), while properties in dynamic data do not (and, absent other restrictions, can be altered by the transaction creator, so could be used for some kind of memo).

_Fungible_ tokens are those with a supply of more than 1, while _non-fungible_ tokens have a supply of only 1 (such that there is only 1 valid copy in existence at any point in logical time).


<!--- Eraser file: https://app.eraser.io/workspace/p3mzc3UZwfSoGHRV34dp --->