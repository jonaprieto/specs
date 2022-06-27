# Ethereum bridge

The Namada - Ethereum bridge exists to mint wrapped ETH and ERC20 tokens on Namada 
which naturally can be redeemed on Ethereum at a later time. Furthermore, it allows the
minting of wrapped tokens on Ethereum backed by escrowed assets on Namada.

The Namada Ethereum bridge system consists of:
* An Ethereum full node run by each Namada validator, for including relevant 
  Ethereum events into Namada.
* A set of validity predicates on Namada which roughly implements 
  [ICS20](https://docs.cosmos.network/v0.42/modules/ibc/) fungible token 
  transfers.
* A set of Ethereum smart contracts.
* A relayer for submitting transactions to Ethereum

This basic bridge architecture should provide for almost-Namada consensus
security for the bridge and free Ethereum state reads on Namada, plus
bidirectional message passing with reasonably low gas costs on the
Ethereum side.

## Security
On Namada, the validators are full nodes of Ethereum and their stake is also
accounting for security of the bridge. If they carry out a forking attack
on Namada to steal locked tokens of Ethereum their stake will be slashed on Namada.
On the Ethereum side, we will add a limit to the amount of ETH that can be
locked to limit the damage a forking attack on Namada can do. To make an attack
more cumbersome we will also add a limit on how fast wrapped ETH can be
redeemed. This will not add more security, but rather make the attack more
inconvenient.

## Ethereum Events Attestation
We want to store events from the smart contracts of our bridge onto Namada.
We need to have consensus on these events, we will only include those that 
have been seen and validated by at least 2/3 of the staking validators in
the blockchain storage.

A valid message should roughly correspond to the ICS20 fungible token packet. 
That is to say it should be of the form:
```rust
struct EthEvent {
    denom: String,
    amount: u256,
    sender: String,
    receiver: String,
    nonce: u64,
}
```
The specification of the `denom` field will be custom to this bridge and not
directly conform with the ICS20 specification. The nonce should just be an 
increasing value. This helps keep message hashes unique. Validators should
ignore improperly formatted events.

Each event should have a list of the validators that have seen
this event and the current amount of stake associated with it. This
will need to be appropriately adjusted across epoch boundaries. However,
once an event has been seen by 2/3 of the voting power, it is locked into a
`seen` state. Thus, even if after an epoch that event has no longer been
reported as seen by 2/3 of the new staking validators voting power, it is still
considered as `seen`.

Each event from Ethereum should include the minimum number of confirmations
necessary to be considered seen. Validators should not vote to include events
that have not met the required number of confirmations. Furthermore, validators
should not look at events that have not reached protocol specified minimum
number of confirmations (regardless of what is specified in an event). This 
constant may be changeable via governance. Voting on unconfirmed events is
considered a slashable offence.

### Storage
To make including new events easy, we take the approach of always overwriting the state with
the new state rather than applying state diffs. The storage keys involved
are:
```
# all values are Borsh-serialized
/eth_msgs/$msg_hash/body : EthEvent
/eth_msgs/$msg_hash/seen_by : Vec<Address>
/eth_msgs/$msg_hash/voting_power: (u64, u64)  # reduced fraction < 1 e.g. (2, 3)
/eth_msgs/$msg_hash/seen: bool
```

Changes to this `/eth_msgs` storage subspace are only ever made by internal transactions crafted 
and applied by all nodes based on the aggregate of vote extensions for the last Tendermint round. That is, changes to `/eth_msgs` happen 
in block `n+1` in a deterministic manner based on the vote extensions of the Tendermint 
round for block `n`.

The `/eth_msgs` storage subspace does not belong to any account and cannot be 
modified by transactions submitted from outside of the ledger via Tendermint. 
The storage will be guarded by a special validity predicate - `EthSentinel` - 
that is part of the verifier set by default for every transaction, but will be 
removed by the ledger code for the specific permitted transactions that are 
allowed to update `/eth_msgs`.

### Including events into storage
For every Namada block proposal, the vote extension of a validator should include
the events of the Ethereum blocks they have seen via their full node such that:
1. The storage value `/eth_msgs/$msg_hash/seen_by` does not include their
   address.
2. It's correctly formatted.
3. It's reached the required number of confirmations on the Ethereum chain

Each event that a validator is voting to include must be individually signed by them. The vote extension data field will be a Borsh-serialization of something like the following.
```rust
pub struct VoteExtension(Vec<Signed<EthEvent>>);
```

These vote extensions will be given to the next block proposer who will
aggregate those that it can verify and will inject a protocol transaction
(the "vote extensions" transaction) with a `tx.data` field containing a vector
of something like a `MultiSignedEthEvent`.

```rust
pub struct MultiSigned<T: BorshSerialize + BorshDeserialize> {
    /// Arbitrary data to be signed
    pub data: T,
    /// The signature of the data
    pub sigs: Vec<common::Signature>,
}

pub struct MultiSignedEthEvent {
    /// Address and voting power of the signing validators
    pub signers: Vec<(Address, u64)>,
    /// Events along with a nonce, as signed by validators
    pub event: MultiSigned<(EthereumEvent, u64)>,
}
```

This vote extensions transaction will be signed by the block proposer. 
Validators will check this transaction and the validity of the new votes as 
part of `ProcessProposal`, this includes checking:
- signatures
- that votes are really from active validators
- the calculation of backed voting power

In `FinalizeBlock`, we derive a second transaction (the "state update" 
transaction) from the vote extensions transaction that:
- calculates the required changes to `/eth_msgs` storage and applies it
- acts on any `/eth_msgs/$msg_hash` where `seen` is going from `false` to `true`
  (e.g. appropriately minting wrapped Ethereum assets)

This state update transaction will not be recorded on chain but will be 
deterministically derived from the vote extensions transaction. All ledger 
nodes will derive and apply this transaction to their own local blockchain 
state, whenever they receive a block with a vote extensions transaction. No 
signature is required.

The value of `/eth_msgs/$msg_hash/seen` will also indicate if the event 
has been acted on on the Namada side. The appropriate transfers of tokens to the
given user will be included on chain free of charge and requires no
additional actions from the end user.

## Namada Validity Predicates

There will be three internal accounts with associated native validity predicates:
- `#EthSentinel` - whose validity predicate will verify the inclusion of events from Ethereum. This validity predicate will control the `/eth_msgs` storage subspace.
- `#EthBridge` - the storage of which will contain ledgers of balances for wrapped Ethereum assets (ETH and ERC20 tokens) structured in a ["multitoken"](https://github.com/anoma/anoma/issues/1102) hierarchy
- `#EthBridgeEscrow` which will hold in escrow wrapped Namada tokens which have been sent to Ethereum.

### Transferring assets from Ethereum to Namada

#### Wrapped ETH or ERC20
The "transfer" transaction mints the appropriate amount to the corresponding multitoken balance key for the receiver, based on the specifics of the `EthEvent`.


##### Examples
For 2 wETH to `atest1v4ehgw36xue5xvf5xvuyzvpjx5un2v3k8qeyvd3cxdqns32p89rrxd6xx9zngvpegccnzs699rdnnt`
```
#EthBridge
    /eth
        /balances
            /atest1v4ehgw36xue5xvf5xvuyzvpjx5un2v3k8qeyvd3cxdqns32p89rrxd6xx9zngvpegccnzs699rdnnt 
            += 2
```

For 10 DAI i.e. ERC20([0x6b175474e89094c44da98b954eedeac495271d0f](https://etherscan.io/token/0x6b175474e89094c44da98b954eedeac495271d0f)) to `atest1v4ehgw36xue5xvf5xvuyzvpjx5un2v3k8qeyvd3cxdqns32p89rrxd6xx9zngvpegccnzs699rdnnt`
```
#EthBridge
    /erc20
        /0x6b175474e89094c44da98b954eedeac495271d0f
            /balances
                /atest1v4ehgw36xue5xvf5xvuyzvpjx5un2v3k8qeyvd3cxdqns32p89rrxd6xx9zngvpegccnzs699rdnnt 
                += 10
```

#### Namada tokens
Any wrapped Namada tokens being redeemed from Ethereum must have an equivalent amount of the native token held in escrow by `#EthBridgeEscrow`.
The protocol transaction should simply make a transfer from `#EthBridgeEscrow` to the `receiver` for the appropriate amount and asset.

### Transferring from Namada to Ethereum

#### Wrapped ETH or ERC20
To redeem wrapped ETH/ERC20, a user should make a transaction to burn their 
wrapped ETH or ERC20 tokens, which the `#EthBridge` validity 
predicate will accept.

Once this burn is done, it is incumbent on the end user to
request an appropriate "proof" of the transaction. This proof must be
submitted to the appropriate Ethereum smart contract by the user to
redeem their ETH. This also means all Ethereum gas costs are the
responsibility of the end user.

The proofs to be used will be custom bridge headers that are calculated
deterministically from the block contents, including messages sent by Namada and
possibly validator set updates. They will be designed for maximally
efficient Ethereum decoding and verification.

For each block on Namada, validators must submit the corresponding bridge
header signed with a special secp256k1 key as part of their vote extension.
Validators must reject votes which do not contain correctly signed bridge
headers. The finalized bridge header with aggregated signatures will appear in the
next block as a protocol transaction. Aggregation of signatures is the
responsibility of the next block proposer.

The bridge headers need only be produced when the proposed block contains
requests to transfer value over the bridge to Ethereum. The exception is
when validator sets change.  Since the Ethereum smart contract should
accept any header signed by bridge header signed by 2 / 3 of the staking
validators, it needs up-to-date knowledge of:
- The current validators' public keys
- The current stake of each validator

This means the at the end of every Namada epoch, a special transaction must be
sent to the Ethereum contract detailing the new public keys and stake of the
new validator set. This message must also be signed by at least 2 / 3 of the
current validators as a "transfer of power". It is to be included in validators
vote extensions as part of the bridge header. Signing an invalid validator
transition set will be consider a slashable offense.

Due to asynchronicity concerns, this message should be submitted well in
advance of the actual epoch change, perhaps even at the beginning of each
new epoch. Bridge headers to ethereum should include the current Namada epoch
so that the smart contract knows how to verify the headers. In short, there
is a pipelining mechanism in the smart contract.

Such a message is not prompted by any user transaction and thus will have
to be carried out by a _bridge relayer_. Once the transfer of power
message is on chain, any time afterwards a Namada bridge process may take
it to craft the appropriate message to the Ethereum smart contracts.

The details on bridge relayers are below in the corresponding section.

Signing incorrect headers is considered a slashable offense. Anyone witnessing
an incorrect header that is signed may submit a complaint (a type of transaction)
to initiate slashing of the validator who made the signature.

#### Namada tokens

Mints of a wrapped Namada token on Ethereum (including NAM, Namada's native token)
will be represented by a data type like:

```rust
struct MintWrappedNam {
    /// The Namada address owning the token
    owner: NamadaAddress,
    /// The address on Ethereum receiving the wrapped tokens
    receiver: EthereumAddress,
    /// The address of the token to be wrapped 
    token: NamadaAddress,
    /// The number of wrapped Namada tokens to mint on Ethereum
    amount: Amount,
}
```

If a user wishes to mint a wrapped Namada token on Ethereum, they must submit a transaction on Namada that:
- stores `MintWrappedNam` on chain somewhere - TBD
- sends the correct amount of Namada token to `#EthBridgeEscrow`

Just as in redeeming ETH/ERC20 above, it is incumbent on the end user to
request an appropriate proof of the transaction. This proof must be
submitted to the appropriate Ethereum smart contract by the user.
The corresponding amount of wrapped NAM tokens will be transferred to the
`receiver` on Ethereum by the smart contract.

## Namada Bridge Relayers

Validator changes must be turned into a message that can be communicated to
smart contracts on Ethereum. These smart contracts need this information
to verify proofs of actions taken on Namada.

Since this is protocol level information, it is not user prompted and thus
should not be the responsibility of any user to submit such a transaction.
However, any user may choose to submit this transaction anyway.

This necessitates a Namada node whose job it is to submit these transactions on
Ethereum at the conclusion of each Namada epoch. This node is called the
__Designated Relayer__. In theory, since this message is publicly available on the blockchain,
anyone can submit this transaction, but only the Designated Relayer will be
directly compensated by Namada.

All Namada validators will have an option to serve as bridge relayer and
the Namada ledger will include a process that does the relaying. Since all
Namada validators are running Ethereum full nodes, they can monitor
that the message was relayed correctly by the Designated Relayer.

During the `FinalizeBlock` call in the ledger, if the epoch changes, a
flag should be set alerting the next block proposer that they are the
Designated Relayer for this epoch. If their message gets accepted by the
Ethereum state inclusion onto Namada, new NAM tokens will be minted to reward
them. The reward amount shall be a protocol parameter that can be changed
via governance. It should be high enough to cover necessary gas fees.

## Ethereum Smart Contracts
The set of Ethereum contracts should perform the following functions:
- Verify bridge header proofs from Namada so that Namada messages can
  be submitted to the contract.
- Verify and maintain evolving validator sets with corresponding stake
  and public keys.
- Emit log messages readable by Namada
- Handle ICS20-style token transfer messages appropriately with escrow &
  unescrow on the Ethereum side
- Allow for message batching

Furthermore, the Ethereum contracts will whitelist ETH and tokens that
flow across the bridge as well as ensure limits on transfer volume per epoch.

An Ethereum smart contract should perform the following steps to verify
a proof from Namada:
1. Check the epoch included in the proof.
2. Look up the validator set corresponding to said epoch.
3. Verify that the signatures included amount to at least 2 / 3 of the
   total stake.
4. Check the validity of each signature.

If all the above verifications succeed, the contract may affect the
appropriate state change, emit logs, etc.

## Starting the bridge

Before the bridge can start running, some storage will need to be initialized in Namada. For example, the `#EthBridge/queue` storage key should be initialized to an empty `Vec<TransferFromEthereum>`. TBD.

## Resources which may be helpful:
- [Gravity Bridge Solidity contracts](https://github.com/Gravity-Bridge/Gravity-Bridge/tree/main/solidity)
- [ICS20](https://github.com/cosmos/ibc/tree/master/spec/app/ics-020-fungible-token-transfer)
- [Rainbow Bridge contracts](https://github.com/aurora-is-near/rainbow-bridge/tree/master/contracts)
- [IBC in Solidity](https://github.com/hyperledger-labs/yui-ibc-solidity)

Operational notes:
1. We should bundle the Ethereum full node with the `namada` daemon executable.
