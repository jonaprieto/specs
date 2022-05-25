# Ethereum bridge

The Namada - Ethereum bridge exists to mint wrapped ETH and ERC20 tokens on Namada 
which naturally can be redeemed on Ethereum at a later time. Furthermore, it allows the
minting of wrapped tokens on Ethereum backed by escrowed assets on Namada.

The Namada Ethereum bridge system consists of:
* Ethereum state inclusion onto Namada.
* A set of validity predicates on Namada which roughly implements [ICS20](https://docs.cosmos.network/v0.42/modules/ibc/) fungible token transfers.
* A set of Ethereum smart contracts.
* A Namada bridge process

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

## Ethereum State Inclusion
We want to store data identifying which Ethereum blocks have been seen
and validated by at least 2/3 of the staking validators in the blockchain storage.
The data stored from each Ethereum block will be:
* The block header
* The block hash
* Messages from the Ethereum smart contracts relevant
  to the bridge.
  We may also we to include Merkle proofs of inclusion of
  these messages in the relevant blocks. We might also implement policies to
  prune old/irrelevant data or do checkpointing.

Each piece of block data should have a list of the validators that have seen
this block and the current amount of stake associated with it. This
will need to be appropriately adjusted across epoch boundaries. However,
once a block has been seen by 2/3 of the staking validators, it is locked into a
`seen` state. Thus, even if after an epoch that block has no longer been
reported as seen by 2/3 of the new staking validators set, it is still
considered as `seen`.

To make this easy, we take the approach of always overwriting the state with
the new state rather than applying state diffs. The storage keys involved
are:
```
/eth_block/$block_hash/header : Vec<u8>
/eth_block/$block_hash/messages : Vec<Vec<u8>>
/eth_block/$block_hash/seen_by : Vec<Address>
/eth_block/$block_hash/voting_power: u64
/eth_block/$block_hash/seen: bool
/eth_block/$block_hash/? : [u8; 32]
# not yet decided
/eth_block/$block_hash/merkle_proofs : Vec<Vec<u8>>
```

For every Namada block proposal, the vote extension of a validator should include
the headers, hash, & smart contract messages (possibly with Merkle proofs)
of the Ethereum blocks they have seen via their full node such that:

1. Has not been marked as `seen` by Namada
2. The storage value `/eth_block/$block_hash/seen_by` does not include their
   address.
3. Is a descendant of a block they have seen (even if it is not marked `seen`)

After a Namada block is finalized, every validator should apply an internal
transaction making the proposed state change of the above form. The block proposer
for the next block subsequently includes a transaction to that end in their block 
proposal. This aggregated state change needs to be validated by at least 2/3 of
the staking validators as usual.

Changes to `/eth_block` are only ever made by internal transactions crafted by 
validators deterministically from the aggregate of vote extensions for the last Tendermint
round. That is, changes to `/eth_block` are calculated and applied during the `FinalizeBlock` stage 
of ABCI++ for block `n`, and then included (and validated) in a transaction in block `n+1`.
It should not be possible for `/eth_block` storage to be modified by transactions submitted
from outside the ledger.

## Namada Validity Predicates

There will be an internal account - `#EthBridge` - the storage of which will contain:
- a queue of incoming transfers from Ethereum (under a `/queue` storage key)
- ledgers of balances for wrapped Ethereum assets (ETH and ERC20 tokens) structured in a ["multitoken"](https://github.com/anoma/anoma/issues/1102) hierarchy

Another internal account - `#EthBridgeEscrow` - will hold in escrow wrapped Namada tokens which have been sent to Ethereum.
### Transferring assets from Ethereum to Namada

We'll have a `TransferFromEthereum` data type which will look roughly like the following:
```rust
enum AssetFromEthereum {
    Eth,  // Native ETH
    Erc20(EthereumAddress),
    WrappedNamadaToken(NamadaAddress),
}

struct TransferFromEthereum {
    /// Asset to be minted (or released from escrow)
    asset: AssetFromEthereum,
    /// the address on Namada receiving the tokens
    receiver: NamadaAddress,
    /// the amount of wrapped Ethereum token to mint, or wrapped Namada token to release from escrow
    amount: Amount,
    /// minimum number of Ethereum confirmations needed for the transfer to happen
    min_confirmations: u8,
    /// height of the Ethereum block at which the message appeared
    height: u64,
    /// the hash & height of the latest descendant Ethereum block marked as `seen`
    latest_descendant: ([u8; 32], u64)
}
```

The minimum number of confirmations indicated in the outgoing Ethereum message
(maybe defaulting to 25 or 50 if unspecified) specifies the minimum number of
confirmations in Ethereum block depth that must be reached before the assets will be
minted on Namada. This is the purpose of the `/queue` for this validity
predicate.

The internal transaction that includes new Ethereum state into `/eth_block` must 
also update `#EthBridge/queue` based on any newly seen blocks. `/eth_block/$block_hash/seen = true` 
implies that that Ethereum block has been processed by the Ethereum bridge.

Processing of the queue looks as follows:
1. For each existing `TransferFromEthereum` in the `/queue`, update its number of 
   confirmations.
```rust
impl TransferFromEthereum {
    /// Update the hash and height of the block `B` marked as `seen` in Namada
    /// storage such that 
    ///   1. `B` is a descendant of the block containing the original message
    ///   2. `B` has the maximum height of all blocks satisfying 1.
    fn update_latest_descendant(&mut self, hash: [u8; 32], height: u64) {
        if height > self.latest_descendant.1 {
            self.latest_descendant = (hash, height);    
        }
    }
}
```
2. Add new `TransferFromEthereum` messages from the seen Ethereum block into the queue.
3. For each `TransferFromEthereum` that is confirmed, make the transfer for the address 
in the `receiver` field and also remove the `TransferFromEthereum` from the `/queue`.

Step 3 may happen in a separate transaction to steps 1 and 2, as it looks only at `#EthBridge/queue`
and doesn't depend on any state changes to `/eth_block.

```rust
impl TransferFromEthereum {
    /// Check if the number of confirmations for the block containing
    /// the original message exceeds the minimum number required to 
    /// consider the message confirmed.
    pub fn is_confirmed(&self) -> bool {
        self.latest_descendant.1 - self.height >= self.min_confirmations
    }
}
```

Note that this means that a transfer initiated on Ethereum will automatically
be seen and acted upon by Namada. The appropriate transfers of tokens to the
given user will be included on chain free of charge and requires no
additional actions from the end user.

#### Wrapped ETH or ERC20
The protocol transaction mints the appropriate amount to the corresponding multitoken balance key for the receiver.

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
- stores `MintWrappedNam` on chain somewhere?
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
