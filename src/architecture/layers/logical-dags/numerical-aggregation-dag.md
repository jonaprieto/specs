# Numerical aggregation DAG

As a simple logical DAG, consider a numerical aggregation DAG: transactions are non-negative integers, state is computed by adding, and there are no conflicts.

```haskell
type TxType = Integer

type State = Integer

validState :: NumAggDAG -> State -> Bool
validState = (==) . foldBy (+)
```