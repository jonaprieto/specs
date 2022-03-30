# Web Wallet

## Persistence of User Wallet

The state of the user's wallet, consisting of their master seed, along with any accounts derived from that seed, should be stored locally in a safe manner. As this requires the use of `localStorage`, all data should be encrypted.

Presently, this challenge is being addressed by using the user's password (specified when creating their master seed) to encrypt/decrypt the mnemonic seed, as well as unlocking the state of their wallet. The accounts in the state are being persisted via `redux-persist`, with an ecryption transform that handles the encrypting and decrypting of all data stored in `localStorage`.

The mnemonic is stored separately from the accounts data. In `anoma-apps/packages/anoma-lib/lib/types/mnemonic.rs` implementation of `Mnemonic`, we provide the ability to specify a password allowing us to retrieve a storage value of the mnemonic, which is encrypted before saving to `localStorage`. When the wallet is locked, the user must provide a password, which is validated by attempting to decrypt the stored mnemonic. If successful, the password is used to either generate an encrypted Redux persistence layer, or decrypt the existing one, restoring the user's wallet state.

`redux-persist` gives us the ability to specify which sub-sections of the state should be persisted. Presently, this is only enabled for any derived account data. From the persisted store, we can establish a `persistor`, which can be passed into a `PersistGate` component that will only display its children once the state is retrieved and decrypted from storage.

If we wanted to export the state of the user's accounts, this would be trivial, and simply a matter of exporting a JSON file containing the `JSON.stringify`ed version of their accounts state. Some work would need to be done in order to restore the data into Redux, however.

The `localStorage` state is stored in one of three places, depending on your environment:

- `persist:anoma-wallet` - Production
- `persist:anoma-wallet-dev` - Devnet
- `persist:anoma-wallet-local` - Local ledger

## Challenges

As a secret is required to unlock the persisted store, this store must be instantiated dynamically once a password is entered and validated. In the current implementation of the wallet, any routes that will make use of the Redux store are loaded asynchronously. When they are loaded, the store is initialized with the user's password (which is passed in through the Context API in React, separate from the Redux state).

## Resources

- [redux-persist](https://github.com/rt2zz/redux-persist) - Redux store persistence
- [redux-persist-transform-encrypt](https://github.com/maxdeviant/redux-persist-transform-encrypt) - Transform to encrypt persisted state
