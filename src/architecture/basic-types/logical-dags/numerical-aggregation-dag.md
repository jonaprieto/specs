<p><a target="_blank" href="https://app.eraser.io/workspace/WRXDACnJVdnucc9SwmaI" id="edit-in-eraser-github-link"><img alt="Edit in Eraser" src="https://firebasestorage.googleapis.com/v0/b/second-petal-295822.appspot.com/o/images%2Fgithub%2FOpen%20in%20Eraser.svg?alt=media&amp;token=968381c8-a7e7-472a-8ed6-4a6626da5501"></a></p>

# Numerical aggregation DAG
As a simple logical DAG, consider a numerical aggregation DAG: transactions are non-negative integers, state is computed by adding, and there are no conflicts.

```haskell
type State = Integer
type Tx = Integer
type NumericalDAG = DAG Integer

validDAG : PhysicalDAG -> NumericalDAG -> Bool
validDAG = subDAGBy isNumber

validState :: NumericalDAG -> State -> Bool
validState = (==) . foldBy (+)
```



<!--- Eraser file: https://app.eraser.io/workspace/WRXDACnJVdnucc9SwmaI --->