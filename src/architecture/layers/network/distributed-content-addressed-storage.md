# Distributed content-addressed storage

## Storage

The distributed content-addressed data storage layer is responsible for providing a very simple read/write storage API: nodes, voluntarily, elect to store data blobs, content-addressed by hash. Nodes can ask other nodes to retrieve data with a `StorageRead` call, providing the hash, and nodes can ask other nodes to store data with a `StorageWrite` call, providing the data as a binary blob, where the address at which to store the data is calculated with the standard `hash`. Upon retrieving data with a `StorageRead` call, nodes can check that they received the correct data by checking that `hash(data)` is equal to the address they requested data for.

```=haskell
data StorageRead = StorageRead {
  address :: Hash
}
```

```=haskell
data StorageWrite = StorageWrite {
  data :: ByteString
}
```

Storage read and write requests are optionally signed - the signature is not required for data integrity, but it may be useful for anti-DoS and proof-of-retrievability.

For now, this layer does not deal with erasure coding, data storage incentives, or other sharding/scaling schemes. The entanglement graph information may be sufficient for highly entangled nodes to safely store a certain amount of data for each other for free (and this is very efficient as compared to more complex schemes). Future versions of the storage layer can support erasure coding schemes "under the hood" of this basic interface, allow nodes to automatically store data for untrusted nodes who pay them some sufficiently valuable credit, and perform more complex operations under the hood, but the basic interface from the perspective of other layers should be able to remain roughly consistent with this very simple model. 

This data storage layer intentionally does not feature any sort of access control or privacy semantics - data which is expected to be kept private should be encrypted before it is stored on the storage layer, and we rely on the encryption to provide privacy to the appropriate parties. It may sometimes be helpful for data to be automatically deleted "by default" after awhile - this can be achieved in the incentive case by ceasing payment, and in the high-entanglement case by internally tracking who requested data to be stored and deleting it at their request.

Storage is generally unordered and observations of storage operations performed are mostly not expected to be included in the physical DAG, although they can occaisionally be if certain nodes wish to track metadata.

