<p><a target="_blank" href="https://app.eraser.io/workspace/uFIT53BcuyXB9kWWZeWT" id="edit-in-eraser-github-link"><img alt="Edit in Eraser" src="https://firebasestorage.googleapis.com/v0/b/second-petal-295822.appspot.com/o/images%2Fgithub%2FOpen%20in%20Eraser.svg?alt=media&amp;token=968381c8-a7e7-472a-8ed6-4a6626da5501"></a></p>

# Taiga
# Introduction
Taiga is a component of Anoma that is used to produce valid state transition proposals. Taiga defines what a valid transaction is and provides the means to produce and verify transactions.

![Figure 1](/.eraser/uFIT53BcuyXB9kWWZeWT___jd3VGfVCpAX6IC30vOqEx6JEtMZ2___---figure---WXkPo6j7wkLa8HN37MkqO---figure---B-YaNqEtewas1LX6DDkk7g.png "Figure 1")

A valid **transaction** is defined as a _balanced_ set of valid **partial transactions**. A partial transaction is valid when:

 [﻿README](https://app.eraser.io/workspace/5dY2OCC7z2mZER16Kway) 

- applications the state of which is being affected by the proposed state transition authorize the state transition
- the proposed state transition doesn't violate the Taiga rules
Actors and agents use Taiga to produce and verify the proofs required to form partial transactions and balanced transactions. The executor function uses Taiga to verify the transactions before applying them to the state.

To support shielded state transitions, the produced proofs are zero-knowledge, currently using the Halo2 proving system. Taiga uses proof recursion to provide function privacy for custom predicates. Taiga is designed in a UTXO model, the notes are distributed and stored in an encrypted form.

Taiga was heavily inspired by [﻿Zcash Orchard](https://github.com/zcash/zips/blob/main/protocol/protocol.pdf) and [﻿ZEXE](https://eprint.iacr.org/2018/962).

>  **Note:** ⚠️ Instantiations and some of the exact formulas are unstable ⚠️ 

>  **Note:** ⚠️ Some of the names in this section are outdated 

>  **Note:** If you want to learn more about Taiga as a standalone component, check [﻿the Taiga repository](https://github.com/anoma/taiga) 

## Functions provided by Taiga
- **create a partial transaction:** users create initial partial transactions to announce what they offer and request, including constraints. These partial transactions are sent to the intent gossip network to be matched with other partial transactions. Solvers create partial transactions to match the intents of the users. 
- **verify a partial transaction:** each partial transaction contains proofs attesting to its correctness. When a solver receives partial transactions from the intent gossip network, they must verify the proofs.
- **combine partial transactions:** solvers combine partial transactions in bundles to build a balanced transaction that satisfies the intents of the involved parties.
- **create a transaction:** when the partial transaction bundle is balanced, it can be turned into an atomic transaction. The balance is proven by the binding signature.
- **verify a transaction:** before applying the transactions to the system state, the executor function verifies them.
The following sections describe the protocol for shielded state transitions.

## 1. Proving system
A proving system is used to produce zero-knowledge proofs for the action and validity predicate circuits. The action circuit is predetermined, validity predicate circuits are custom and require at least two-layer recursion to achieve function privacy. We use Halo2 with IPA FCS and [﻿Pasta curves](https://github.com/zcash/pasta).

### 1.1 Circuits
Let `C(x; w) ⟶ 0/1` be a circuit. A circuit is represented as polynomials over the chosen curve's **scalar field**, following [﻿plonk-ish arithmetization](https://zcash.github.io/halo2/concepts/arithmetization.html). Commitments are generated over the curve's **base field**.

### 1.2 Elliptic curves
Name

Scalar field

Base field

Purpose

Instantiation

$E_I$

Inner curve

$\mathbb{F}_q$

$\mathbb{F}_p$

ECC gadget

[﻿Pallas](https://github.com/zcash/pasta#pallasvesta-supporting-evidence) 

$E_M$

Main curve

$\mathbb{F}_p$

$\mathbb{F}_q$

Action and VP circuits

[﻿Vesta](https://github.com/zcash/pasta#pallasvesta-supporting-evidence) 

$E_O$

Outer curve

$\mathbb{F}_q$

$\mathbb{F}_p$

Accumulation circuit

Pallas

### 1.3 Proving system interfaces
Interface

Description

**Preprocess**

`preproc(C) ⟶ desc_C` 

`C` 

 is turned into a 

_circuit description_

, which is all data the verifier needs to verify a proof. It includes the verifier key 

`C_vk` 

, but not only that.

**Prove**

`P(C, x, w) ⟶ π` 

**Verify**

`V(desc_C, x, π) ⟶ 0/1` 

## 2. Notes
_Note_ is an immutable particle of an application state. The state is updated by destroying or creating notes.

### 2.1 Note structure
Variable

Type/size

Description

`value_base` 

Value base represents the note type

`app_data_dynamic` 

Commitment to the note's extra data

`v` 

${0..2^{64} - 1}$

The quantity of fungible value

`cm_nk` 

Commitment to the nullifier key that will be used to derive the note's nullifier

`ρ` 

$\mathbb{F}_p$

An old nullifier from the same Action description (see Orchard)

`ψ` 

$\mathbb{F}_p$

The prf output of 

`ρ` 

 and 

`rcm_note` 

 (see Orchard)

`is_merkle_checked` 

bool

Dummy note flag. It indicates whether the note's commitment Merkle path should be checked when spending the note.

`rcm_note` 

${0..2^{255} - 1}$

A random commitment trapdoor

>  **Note:** the value size cannot be bigger or close to the curve's scalar field size (to avoid overflowing) but besides that there are no strict reasons for choosing 64. We can use more notes to express a value that doesn't fit in one note (splitting the value into limbs). Having bigger value size requires fewer notes to express such a value and is more efficient. For example, a value size of 128 bits would require two times less notes to express a maximum value 

#### Application-related fields
Each note has three fields that link the note to the application and provide the application context.

Variable

Type/size

Description

`cm_app_vk` 

Contains the application's main VP verifier key. Used to identify the application the note belongs to. As the verifier key itself is large, notes only store a commitment to it.

`app_data_static` 

Contains the application data that affects fungibility of the note. Along with 

`cm_app_vk` 

, it is used to derive note's value base

`app_data_dynamic` 

Contains the application data that doesn't affect the fungibility of the note

#### Value base
Value base is used to distinguish note types. Notes with different value bases have different note types. The value base of a note is derived from two fields: `cm_app_vk` and `app_data_static`.

$VB = PRF^{vb}(cm_{app_vk}, app_data_static)$

#### Value commitment
Used to ensure balance across the notes in an Action.

Compare one-type value commitment computation used in Orchard (Orchard spec p. 93, homomorphic pedersen commitment):

$[v^{in} - v^{out}]VB + [rcv]R$

And multiple types value commitment computation used in Taiga:

$cv = [v^{in}]VB^{in} - [v^{out}]VB^{out} + [rcv]R$

Variable

Type/size

Description

$v^{in}$

${0..2^{64} - 1}$

$v^{out}$

${0..2^{64} - 1}$

$VB^{in}$

outer curve point

Input note's value base

$VB^{out}$

outer curve point

Output note's value base

`R` 

outer curve point

Randomness base, fixed

`rcv` 

${0..2^{255} - 1}$

Value commitment trapdoor

`cv` 

outer curve point

### 2.3 Note commitment
Note commitments are stored in a global commitment tree. The global commitment tree contains commitments to all of the notes ever existed. Adding a note's commitment to the commitment tree announces the creation of the note. The notes are never removed from the tree. Instead, notes are invalidated by revealing their **nullifiers**.

Name

Type/size

Description

`cm` 

outer curve point

$cm = \mathrm{NoteCom}(note, rcm_note)$

### 2.4 Nullifier
Note nullifiers are stored in a global nullifier set. Adding a note's nullifier to the set invalidates the note. Currently, we use the same nullifier derivation algorithm as in Orchard: $\mathrm{DeriveNullifier}_{nk}(ρ, ψ, cm) = \mathrm{Extract}([PRF^{nf}_{nk}(ρ) + ψ \mod{q}]K + cm)$.

Name

Type/size

Description

`nf` 

$\mathbb F_p$

$nf = \mathrm{DeriveNullifier}_{nk}(ρ, ψ, cm)$

`nk` 

$\mathbb F_p$

the nullifier deriving key

`ρ` 

$\mathbb{F}_p$

an old nullifier

`ψ` 

$\mathbb{F}_p$

$PRF_{rcm_note}(ρ)$ -- should it be the same as in zcash?

`cm` 

outer curve point

note commitment

`K` 

outer curve point

a fixed base generator of the inner curve

`Extract` 

$(\mathbb F_p$, $\mathbb F_p) \rightarrow \mathbb F_p$

the $x$ coordinate of an (inner curve) point

$PRF^{nf}_{nk}(\rho)$

$\mathrm{F}_p \times \mathrm{F}_p \rightarrow \mathrm{F}_p$

#### 2.4.1 Nullifier deriving key `nk` 
The nullifier key for the note is derived when the note is created and is only known to the note's owner (or anyone the owner reveals the key to). Knowledge of the note's nullifier key is necessary (but not sufficient) to create the note's nullifier and invalidate the note.

>  **Note:** ⚠️ Not implemented, unstable 

$nk = PRF^{nk}_{r}(\mathrm{PERSONALIZATION_NK})$.

Name

Type/size

Description

`PERSONALIZATION_NK` 

constant-size string

`Taiga_PRF_NK` 

, constant

`r` 

PRF randomness

### 2.5 Verifiable encryption
Encryption is used for in-band distribution of notes. Encrypted notes are stored on the blockchain, the receiver can scan the blockhcain trying to decrypt the notes and this way to find the notes that were sent to them.

We want the encryption to be verifiable to make sure the receiver of the notes can decrypt them. In other systems like Zcash the sender and the creator of the note are the same actor, and it doesn't make sense for the sender to send a corrupted message to the receiver (essentially burning the note), but in Taiga the notes are often created and sent by different parties.

We use the combination of DH key exchange with symmetric encryption.

$sk = DH(pub_{recv}, priv_{send})$

$ce = Encrypt(note, sk)$

Not all of the note fields require to be encrypted (e.g. note commitment), and the encrypted fields may vary depending on the application.

### 2.6 Dummy notes
In Taiga, note's value doesn't define if the note is dummy or not, unlike some other systems. Dummy notes can have non-zero value and are marked explicitly as dummy by setting `is_merkle_checked = false`, meaning that for dummy notes the commitment's Merkle path is not checked when spending the note. Non-zero value dummy notes are handy for carrying additional constraints (e.g. intents) and balancing transactions.

## 3. Circuits
### 3.1 The Action Circuit
The action circuit `ActionCircuit(x; w)` checks that a partial transaction satisfies the Taiga rules. The Action circuit performs checks over `1` input and `1` output note. A partial transaction containing `n` input and `n` output notes requires `n` Action proofs. The circuit is arithmetized over $\mathbb{F}_p$.

#### Inputs
Public inputs (`x`):

1. `rt`  - the root of the commitment Merkle tree
2. `nf`  - input note nullifier
3. `cm_vp_in`  - input note's application VP commitment
4. `cm`  - output note commitment
5. `cm_vp_out`  - output note's application VP commitment
Private inputs (`w`):

1. `in_note = (value_base, v, cm_nk, ρ, ψ, is_merkle_checked, rcm_note)`  - input note opening
2. `(cm_app_vk, rcm_vp)`  - opening of `cm_vp_in` 
3. `out_note = (value_base, v, cm_nk, ρ, ψ, is_merkle_checked, rcm_note)`  - output note opening
4. `(cm_app_vk, rcm_vp)`  - opening of `cm_vp_out` 
>  **Note:** opening of a parameter contains every field used to derive the parameter 

#### Checks
- For input note:
    - If `is_merkle_checked = true` , check that the note is a valid note in `rt` : there is a path in Merkle tree with root `rt`  to a note commitment `cm`  that opens to `note` 
    - Nullifier integrity: $nf = DeriveNullier_{nk}(note)$.
    - Application VP integrity: $cm_{vp} = VPCommit(cm_{app_vk}, rcm_{vp})$
    - Value base integrity: $vb = PRF^{vb}(cm_{app_vk}, app_data_static)$
- For output note:
    - Commitment integrity(output note only): $cm = NoteCom(note, rcm_{note})$
    - Application VP integrity: $cm_{vp} = VPCommit(cm_{app_vk}, rcm_{vp})$
    - Value base integrity: $vb = PRF^{vb}(cm_{app_vk}, app_data_static)$
- Value commitment integrity: $cv = ValueCommit(v_{in}, v_{out}, VB_{in}, VB_{out}, rcv)$
>  **Note:** unlike [﻿MASP](https://github.com/anoma/masp), the value base in Taiga is not used to compute note's commitment and the Action circuit doesn't take `vb` as private input but computes it from the note fields, and it is checked for both input and output notes. 

### 3.2 Validity Predicate (VP) circuits
Validity predicate is a circuit containing the application logic. Validity predicates take `n` input and `n` output notes, are represented as Halo2 circuits `VP(x; w) ⟶ 0/1` and arithmetized over $\mathbb{F}_p$.

#### Inputs
Public inputs (`x`):

- $nf_1, …, nf_n$ - input note nullifiers
- $cm_1, …, cm_n$ - output note commitments
- $ce_1, …, ce_n$ - encrypted output notes
Private inputs (`w`):

- $note^{old}_1, …, note^{old}_m$ - input notes openings
- $note^{new}_1, …, note^{new}_n$ - output notes openings
- custom private inputs
#### Checks
As opening of the notes are private parameters, to make sure that notes that the VP received indeed the ones that correspond to the public parameters, every VP must check:

1. Input note nullifier integrity: for each $i ∈ {1, …, m}, nf_i = DeriveNullifier_{nk}(ρ, ψ, cm)$
2. Output note commitment integrity: for each $i ∈ {1, …, n}, cm_i = NoteCommit(note, rcm_{note})$
3. Encrypted note integrity: for each $i ∈ {1, …, n}, ce_i = Encrypt(note, pub_{recv})$
>  **Note:** encryption can be customized per application. Some applications might encrypt more fields, others - less. The size of the encrypted note does leak some information 

All other constraints enforced by VP circuits are custom.

#### Finding the owned notes
A VP takes all notes from the current `ptx` as input which requires a mechanism to determine which note is the application's note being currently checked. Currently, to determine whether a note belongs to the application or not, Taiga passes the note commitment (for output notes) or the nullifier (for input notes) of the owned note as a tag. The VP identifies the owned note by its tag.

#### VP commitment
In the presense of a VP proof for a certain note, VP commitment is used to make sure the right VP is checked for the note. It makes sure that `vp_vk` the note refers to and `vp_vk` used to validate the VP proof are the same.

VP commitment has a nested structure: `VPCommit(vp, rcm_vp) = Com(cm_vp_vk, rcm_vp), cm_vp_vk = VKCom(vp_vk)`.

The check is done in two parts:

1. The Action circuit checks that the VP commitment `cm_vp`  is derived with `cm_vp_vk`  the note refers to:
`cm_vp = VPCommit(cm_vp_vk, rcm_vp)` 
2. The verifier circuit checks that the VP commitment is computed using the `vp_vk`  that is used to validate the VP proof:
`cm_vp = VPCommit(VKCommit(vp_vk), rcm_vp)` 
As the outer commitment `VPCommit` is verified in both Action and verifier circuit which are arithmetized over different fields, the outer commitment instantiation should be efficient over both fields.

As the inner commitment `VKCommit` is only opened in the verifier circuit, it only needs to be efficient over the outer curve's scalar field.

## 4. Circuit Accumulation
TBD: Halo2 accumulation

### 5. Binding signature
Binding signature is used to make sure the transaction is balanced. Value commitments produced in each partial transaction are accumulated and checked against the commitment to the expected net value change. The value change might be zero, indicating that the whole transaction was done in the schielded space, or non-zero, indicating that some value came from/to the transparent space. We use the same binding signature mechanism as Zcash Orchard.

#### Taiga balance vs Application balance
Taiga transaction is balanced if for each note type: $\sum_i{v_i^{in}} - \sum_j{v_j^{out}} = v^{balance}$, where $v^{balance}$ is the balancing value. Applications have their own definitions of balance that might differ from the Taiga definition. For example, some applications might allow to create more output value from less input value, which makes the total value change $v^{balance}$ non-zero. This application-specific balance is different from the Taiga balance and the application needs to make sure the transaction is balanced in the Taiga sense by adding some non-zero value dummy notes to the transaction.

## 6. Instantiations
Function

Instantiation

Domain/Range

Description

$PRF^{nf}$

Poseidon

$\mathrm{F}_p \times \mathrm{F}_p \rightarrow \mathrm{F}_p$

$PRF^{nf}_{nk}(ρ) = Poseidon(nk, \rho)$

$PRF^{nk}$

Blake2s

$\mathrm{F}_p \rightarrow \mathrm{F}_p$

$PRF^{nk}_{r}(PERSONALIZATION_{NK}) = Blake2s(PERSONALIZATION_{NK}, r)$

$PRF^{vb}$

Poseidon

$\mathrm{F}_p \rightarrow \mathrm{F}_q$

$PRF^{vb} = hash_to_curve(Poseidon(app_vk, app_data_static))$

`NKCommit` 

Poseidon

$\mathrm{F}_p \rightarrow \mathrm{F}_p$

$NKCommit(nk) = Poseidon(nk, user_derived_key)$; used to protect 

`nk` 

 stored in a note. 

`user_derived_key` 

 is currently not used

`NoteCommit` 

[﻿Sincemilla](https://zcash.github.io/halo2/design/gadgets/sinsemilla.html) 

$\mathrm{F}_p \rightarrow \mathrm{F}_p \times \mathrm{F}_p$

`ValueCommit` 

Pedersen with variable value base

$\mathrm{F}_p \rightarrow \mathrm{F}_q$

$cv = [v_i] * VB_i - [v_o] * VB_o + [r]R$

`VPCommit` 

Blake2s

Efficient over both $\mathrm{F}_p$ and $\mathrm{F}_q$

`VKCommit` 

-

Efficient over the outer curve's scalar field

address

Poseidon

$\mathrm{F}_p \rightarrow \mathrm{F}_p$

`address = Poseidon(app_data_dynamic, cm_nk)` 

; compresses the data fields that contain some ownership information

`Encrypt` 

DH + Poseidon

$\mathrm{F}_p \rightarrow \mathrm{F}_p$

$Encrypt(note, pub_{recv}, priv_{send}) = Poseidon(note, DH(pub_{recv}, priv_{send}))$

Binding signature

See Orchard binding signature

## 7. Taiga Execution Model
### Taiga partial transaction
Taiga uses partial transactions to build atomic on-chain transactions. For partial transactions, it is required that all VP proofs are valid but the partial transaction is **not** balanced i.e. $v^{in} - v^{out} \neq v^{balance}$. Later, valid partial transactions are composed in a way that the total set of partial transactions balances, which is proven by the binding signature check. A partial transaction that naturally balances forms a balanced transaction.

Each Taiga `ptx` contains `n` input and `n` output notes. Currently, `n = 2`. Each of the notes requires at least one VP to be satisfied, resulting in at least `2n` VP proofs per `ptx`.

>  **Note:** Right now, each note requires a separate VP proof, even if they belong to the same application. Eventually the VP might be called just once per `ptx`, meaning that if the `ptx` has 2 or more notes belonging to the same application, the total amount of non-dummy proofs is reduced. 

>  **Note:** it is possible that a VP requires checks of other VPs in order to be satisfied. In that case, the total amount of VPs checked could be more than `2n`, but we can count such check as a single check. 

#### Partial transaction fields
Each Taiga `ptx` contains:

- `n`  actions (one action covers one input and one output note):
    - `π_action`  - proof of the action
    - `(rt, nf, cm, cm_vp_input, cm_vp_output, ce)`  - action's public input
- for the input notes:
    - `π_VP`  proof
    - VP's public input
    - `VP_vk` 
    - `extra_VP_vk`  (if the "main" VP requires additional VPs to be checked)
- for the output notes:
    - `π_VP`  proof
    - VP public input
    - `VP_vk` 
    - `extra_VP_vk`  (if the "main" VP requires additional VPs to be checked)
#### Validity of a `ptx` 
A partial transaction `ptx` is valid if:

1. For each $i$-th action:
    - [if `is_merkle_checked = true` ] `rt_i`  is a valid Merkle root from current or past epoch.
    - `Verify(desc_Action, ActionPublicInput, π_action_i) = True` 
2. For each VP:
    - `Verify'(desc_VP, VPPublicInput, π_VP) = True` 
    - Public input consistency: VP's public input `nf`  and `cm`  are the same as in Actions' public input
### Taiga transaction
Taiga transaction is built from a set of partial transactions. Unlike partial transactions, a transaction must balance, which is proven by the attached binding signature.

#### Taiga transaction fields
A Taiga transaction contains:

- a set of `k`  partial transactions: `[ptx_1, …, ptx_k]` 
- a binding signature
#### Validity of a `tx` 
A transaction is valid if:

- each partial transaction in the `tx`  is valid
- the binding signature is correct
### Taiga state
Taiga is stateless in the sense that it doesn't store and update the state, but Taiga produces the state change that assumes a certain state structure.

For each epoch the state consists of:

- Merkle tree, $CMtree$, of note commitments with root `rt` 
    - Supporting add: $CMtree.add(cm, ce)$
    - Only `cm`  is hashed in derivation of `rt` , note encryption `ce`  is simply stored alongside `cm` 
- Set of input note nullifiers, $NF$
    - Supporting add: $NF.add(nf)$
    - Supports memership checks
The state should make past `rt` accessible as well.

#### Produced state change
A valid Taiga transaction `tx` induces a state change as follows:

1. For each `nf` : $NF.add(nf)$
2. For each `cm`  with associated `ce` : $MT.add(cm, ce)$
    - `rt`  is not updated for operation
3. Re-compute `rt`  of $MT$
## 8. Communication between the shielded and transparent pools
State transitions that do not preserve privacy are called _transparent_. Assuming that the system allows both transparent and shielded state transitions, we say that all of the valid notes created as a result of shielded state transitions form a _shielded pool_ and the valid notes created as a result of transparent state transitions form a _transparent pool_. The action of moving data from transparent to shielded pool is called _shielding_, the opposite is called _unshielding_. Shielding (or unshielding) is done by destroying notes in one pool and creating the corresponding notes in the other. _Balancing value_ $v^{balance}$ indicates the data move between the pools:

- $v^{balance} = 0$ if the current transaction doesn't move data between pools
- $v^{balance} < 0$ refers to the value moved from the transparent to the shielded pool
- $v^{balance} > 0$ refers to the value moved from the shielded to the transparent pool
The difference between total input value and total output value of a proposed transaction is checked against the balancing value with the help of the binding signature.


<!--- Eraser file: https://app.eraser.io/workspace/uFIT53BcuyXB9kWWZeWT --->