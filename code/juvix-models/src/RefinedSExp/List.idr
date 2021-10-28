module RefinedSExp.List

import Library.FunctionsAndRelations
import public Data.List

%default total

public export
ListPred : Type -> Type
ListPred atom = !- (List atom)

public export
ListPi : {atom : Type} -> ListPred atom -> Type
ListPi {atom} lp = List atom ~> lp

public export
record ListEliminatorSig {atom : Type} (lp : ListPred atom) where
  constructor ListEliminatorArgs
  nilElim : lp []
  consElim : (a : atom) -> (l : List atom) -> lp l -> lp (a :: l)

public export
listEliminator :
  {0 atom : Type} -> {0 lp : ListPred atom} ->
  (signature : ListEliminatorSig lp) ->
  ListPi lp
listEliminator signature [] =
  nilElim signature
listEliminator signature (a :: l) =
  consElim signature a l (listEliminator signature l)

public export
ListMetaPred : {atom : Type} -> ListPred atom -> Type
ListMetaPred {atom} lp = (l : List atom) -> lp l -> Type

public export
ListMetaPredToPred : {atom : Type} -> {lp : ListPred atom} ->
  ListMetaPred lp -> ListPred atom
ListMetaPredToPred {lp} lmp = \l => lp l ~> lmp l

public export
ListMetaPi : {atom : Type} -> {lp : ListPred atom} ->
  ListMetaPred lp -> Type
ListMetaPi {atom} {lp} lmp = (l : List atom) -> (lpl : lp l) -> lmp l lpl

public export
ListSigToMetaPred : {atom : Type} -> {lp : ListPred atom} ->
  ListEliminatorSig lp -> ListMetaPred lp -> ListPred atom
ListSigToMetaPred signature lmp = \l => lmp l (listEliminator signature l)

public export
ListSigPi : {atom : Type} -> {lp : ListPred atom} ->
  ListEliminatorSig lp -> ListMetaPred lp -> Type
ListSigPi signature lmp = ListPi (ListSigToMetaPred signature lmp)

public export
ListSigEliminatorSig : {atom : Type} -> {lp : ListPred atom} ->
  ListEliminatorSig lp -> ListMetaPred lp -> Type
ListSigEliminatorSig signature lmp =
  ListEliminatorSig (ListSigToMetaPred signature lmp)

public export
record ListMetaEliminatorSig
  {0 atom : Type} {0 lp : ListPred atom}
  (signature : ListEliminatorSig lp)
  (lmp : ListMetaPred lp)
  where
    constructor ListMetaEliminatorArgs
    metaNilElim : lmp [] (nilElim signature)
    metaConsElim :
      (a : atom) -> (l : List atom) ->
      (lmpl : lmp l (listEliminator signature l)) ->
      lmp (a :: l) (consElim signature a l (listEliminator signature l))

public export
ListMetaEliminatorSigToEliminatorSig :
  {0 atom : Type} -> {0 lp : ListPred atom} ->
  {signature : ListEliminatorSig lp} ->
  {0 lmp : ListMetaPred lp} ->
  ListMetaEliminatorSig signature lmp ->
  ListSigEliminatorSig signature lmp
ListMetaEliminatorSigToEliminatorSig metaSig =
  ListEliminatorArgs (metaNilElim metaSig) (metaConsElim metaSig)

public export
listMetaEliminator :
  {0 atom : Type} -> {0 lp : ListPred atom} ->
  {signature : ListEliminatorSig lp} ->
  {0 lmp : ListMetaPred lp} ->
  ListMetaEliminatorSig signature lmp ->
  ListSigPi signature lmp
listMetaEliminator = listEliminator . ListMetaEliminatorSigToEliminatorSig

public export
ListForAll : {atom : Type} -> (ap : atom -> Type) -> List atom -> Type
ListForAll ap = listEliminator (ListEliminatorArgs () (const . Pair . ap))

public export
ListExists : {atom : Type} -> (ap : atom -> Type) -> List atom -> Type
ListExists ap = listEliminator (ListEliminatorArgs Void (const . Either . ap))

public export
data IsSublist : {atom : Type} -> (lsub, lsuper: List atom) -> Type where
  NilSublist : {atom : Type} -> (lsuper : List atom) -> IsSublist [] lsuper
  ExclusiveSublist : {atom : Type} -> (a : atom) ->
    (lsub, lsuper : List atom) -> IsSublist lsub lsuper ->
    IsSublist lsub (a :: lsuper)
  InclusiveSublist : {atom : Type} -> (a : atom) ->
    (lsub, lsuper : List atom) -> IsSublist lsub lsuper ->
    IsSublist (a :: lsub) (a :: lsuper)

public export
IsNonEmptySublist : {atom : Type} -> (lsub, lsuper: List atom) -> Type
IsNonEmptySublist lsub lsuper = (NonEmpty lsub, IsSublist lsub lsuper)

public export
EitherList : (types : List Type) -> Type
EitherList [] = Void
EitherList (t :: ts) = Either t (EitherList ts)

public export
eitherListElim : {types : List Type} -> (el : EitherList types) ->
  {out : Type} -> ListForAll (\t => t -> out) types -> out
eitherListElim {types=[]} v _ = void v
eitherListElim {types=(t :: ts)} (Left x) (f, _) = f x
eitherListElim {types=(t :: ts)} (Right el) (_, fl) = eitherListElim el fl

public export
eitherListInject : {types : List Type} -> (n : Nat) ->
  {auto ok : InBounds n types} -> index n types {ok} ->
  EitherList types
eitherListInject {types=(_ :: _)} Z {ok=InFirst} x =
  Left x
eitherListInject {types=(_ :: _)} (S n) {ok=(InLater ok)} x =
  Right (eitherListInject n {ok} x)
