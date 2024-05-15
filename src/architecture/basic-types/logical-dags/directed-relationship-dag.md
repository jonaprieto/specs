<p><a target="_blank" href="https://app.eraser.io/workspace/XyPDR2tNd90CsGy0WZ8x" id="edit-in-eraser-github-link"><img alt="Edit in Eraser" src="https://firebasestorage.googleapis.com/v0/b/second-petal-295822.appspot.com/o/images%2Fgithub%2FOpen%20in%20Eraser.svg?alt=media&amp;token=968381c8-a7e7-472a-8ed6-4a6626da5501"></a></p>

# Directed relationship DAG
The directed relationship DAG tracks directed relationships between pairs of identities, where the first identity can establish or unestablish the relationship at will. The "following" relationship on social media, for example, typically has this structure. The state of the directed relationship DAG at any point in logical time is the set of relationships created more recently than they were destroyed (if at all), i.e. the set of outstanding relationships most recently consented to by the first identity.

```haskell
data Tx
  = Create Identity Identity
  | Destroy Identity Identity

type DirectedRelationshipDAG = DAG Tx
type State = Set (Identity, Identity)

validTx :: Tx -> Bool
validTx (Create a b) = verify a (1, b)
validTx (Destroy a b) = verify a (0, b)

validDAG :: PhysicalDAG -> DirectedRelationshipDAG -> Bool
validDAG = all validTx . subDAGBy isTx

validState :: DirectedRelationshipDAG -> State -> Bool
validState = (==) . filter createdAfterLastDestroy
```
We can also define an entanglement measure between _a_ and _b_ as `1`, if _a_ follows _b_, or else the mean entanglement between all identities which _a_ follows and _b_, parameterised by some `k` which denotes how much entanglement falls off with following distance (`k` ranges from 0 to 1):

```haskell
entanglement :: State -> Identity -> Identity -> Real
entanglement s a b = if (following s a b) then 1
                        else k * mean (map (flip entanglement) (allFollowers s a))
```
Partial ordering should be sufficient for this DAG, as no transactions can conflict, so no consensus is required.


<!--- Eraser file: https://app.eraser.io/workspace/XyPDR2tNd90CsGy0WZ8x --->