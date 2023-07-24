<p><a target="_blank" href="https://app.eraser.io/workspace/aFhSNLG5RbOf8Usr4PvB" id="edit-in-eraser-github-link"><img alt="Edit in Eraser" src="https://firebasestorage.googleapis.com/v0/b/second-petal-295822.appspot.com/o/images%2Fgithub%2FOpen%20in%20Eraser.svg?alt=media&amp;token=968381c8-a7e7-472a-8ed6-4a6626da5501"></a></p>

# Applications
Applications consist of a set of related resource logics. The state of any particular application is sharded across the system, and may be under many different controllers. Applications, of course, can restrict themselves to specific sets or paths of controllers with appropriate checks in the predicates, but by default Anoma's architecture is designed to provide a clean separation of application design and security choices, such that application developers can choose the data model and predicate logic but users can choose the security assumptions.

It is important to note that the abstraction of an "Application" is _virtual_ - applications are not deployed or tracked in any sort of global registry - rather, they are content-addressed by the specific logics involved. An "Application" can be said to exist by virtue of the existence resources referencing it, and if those resources are completely consumed it no longer exists (except in history). In order to interact with applications, users must know the relevant logics, which could be distributed to them through any communications channel (including the Anoma P2P network). Applications are also _composable_, in that state transitions for multiple applications can be combined (atomically, if desired). Interfaces may support any combination of applications, and no interface need have any special permissioning.

In contrast to many blockchain systems which have separate software packages for interfaces (wallets) and node software, Anoma is designed as a unified system, which all nodes run - validators, gossip nodes, solvers, edge clients, etc. - just with separate configurations to enable or disable processing, storage, signing, etc. The Anoma node software internally handles P2P network connections, fetching & caching state, verifying signatures (e.g. of validators, running light clients), etc. - no interface should need to implement these, they should just use the local API provided by the node software package.

The applications section in this specification document describes a set of common primitives and classes of example applications suitable for different kinds of coordination. This section is neither exhaustive nor intended to describe particular applications in exact detail, but rather to provide an overview and guidance for how to think about developing applications on Anoma.

- [﻿Primitives](./applications/primitives.md#primitives) 
- [﻿Kudos](./applications/kudos.md#kudos) 
- [﻿Proof-of-stake](./applications/proof-of-stake.md#proof-of-stake) 
- [﻿Bartering](./applications/bartering.md#bartering) 
- [﻿Auctions](./applications/auctions.md#auctions) 
- [﻿Public goods funding](./applications/public-goods-funding.md#public-goods-funding) 
- [﻿Schelling tests](./applications/schelling-tests.md#schelling-tests) 
- [﻿Mesh messaging](./applications/mesh-messaging.md#mesh-messaging) 
- [﻿Physical logistics](./applications/physical-logistics.md#physical-logistics) 



<!--- Eraser file: https://app.eraser.io/workspace/aFhSNLG5RbOf8Usr4PvB --->