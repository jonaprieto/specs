module Library.FunctionsAndRelations

%default total

namespace Relations
    infix 20 <|
    export
    interface Relation ty where
        (<|) : ty -> ty -> Type

    export
    interface Relation ty => DecidableRelation ty where
        decide : (x, y : ty) -> Dec (x <| y)

    export
    interface Relation ty => Reflexive ty where
        reflexive : (x : ty) -> x <| x

    export
    interface Relation ty => Symmetric ty where
        symmetric : (x, y : ty) -> x <| y -> y <| x

    export
    interface Relation ty => Transitive ty where
        transitive : (x, y, z : ty) -> x <| y -> y <| z -> x <| z

    export
    interface (Reflexive ty, Transitive ty) => Preorder ty where

    export
    interface (Preorder ty, Symmetric ty) => Equivalence ty where

    infixl 18 ~=
    export
    (~=) : Equivalence ty => ty -> ty -> Type
    (~=) = (<|)

    export
    interface Preorder ty => BoundedLattice ty where
        (&&) : (x, y : ty) -> ty
        meet_lower_left : (x, y : ty) -> (x && y) <| x
        meet_lower_right : (x, y : ty) -> (x && y) <| y
        meet_greatest_lower : (w, x, y : ty) ->
            w <| x -> w <| y -> w <| (x && y)

        (||) : (x, y : ty) -> ty
        join_upper_left : (x, y : ty) -> x <| (x || y)
        join_upper_right : (x, y : ty) -> y <| (x || y)
        join_least_upper : (w, x, y : ty) ->
            x <| w -> y <| w -> (x || y) <| w

        bottom : ty
        bottom_least : (x : ty) -> bottom <| x

        top : ty
        top_greatest : (x : ty) -> x <| top

    export
    interface (BoundedLattice ty, DecidableRelation ty) =>
            DecidableBoundedLattice ty where

namespace DependentRelations
    infixl 21 *<|
    export
    interface Relation ty (depty : ty -> Type) where
        (*<|) : {x : ty} -> depty x -> depty x -> Type

    export
    interface Relation ty depty => Reflexive ty (depty : ty -> Type) where
        reflexive : (x : ty) -> Reflexive (depty x)

    export
    interface Relation ty depty => Symmetric ty (depty : ty -> Type) where
        symmetric : (x : ty) -> Symmetric (depty x)

    export
    interface Relation ty depty => Transitive ty (depty : ty -> Type) where
        transitive : (x : ty) -> Transitive (depty x)

    export
    interface (Reflexive ty depty, Transitive ty depty) =>
            Preorder ty (depty : ty -> Type) where

    export
    interface (Preorder ty depty, Symmetric ty depty) =>
            Equivalence ty (depty : ty -> Type) where

    infixl 19 *~=
    export
    (*~=) : {depty : ty -> Type} -> (Equivalence ty depty) =>
        {x : ty} -> depty x -> depty x -> Type
    (*~=) {depty} = (*<|) {depty}

public export
applyEq : {a, b : Type} ->
  {f, f' : a -> b} -> f = f' ->
  {x, x' : a} -> x = x' ->
  f x = f' x'
applyEq Refl Refl = Refl

public export
consEq : {a : Type} -> {x, x' : a} -> {l, l' : List a} ->
  (x = x') -> (l = l') -> (x :: l) = (x' :: l')
consEq Refl Refl = Refl

public export
mapPair : {a, a', b, b': Type} -> (f: a -> b) -> (f': a' -> b') ->
          (a, a') -> (b, b')
mapPair f f' (x, x') = (f x, f' x')

public export
swap : {a, b, c : Type} -> (a -> b -> c) -> (b -> a -> c)
swap f x y = f y x

pipe : {a, b, c : Type} -> (a -> b) -> (b -> c) -> (a -> c)
pipe = swap (.)

public export
PairFstEq : {a, b : Type} -> {p, p' : (a, b)} -> p = p' -> fst p = fst p'
PairFstEq Refl = Refl

public export
PairSndEq : {a, b : Type} -> {p, p' : (a, b)} -> p = p' -> snd p = snd p'
PairSndEq Refl = Refl

public export
DPairFstEq : {a : Type} -> {b : a -> Type} -> {p, p' : DPair a b} ->
  p = p' -> fst p = fst p'
DPairFstEq Refl = Refl

public export
DPairSndEq : {a : Type} -> {b : a -> Type} -> {p, p' : DPair a b} ->
  (p_eq : p = p') ->
  DPair.snd p ~=~ DPair.snd p'
DPairSndEq Refl = Refl

public export
DPairInjective : {a : Type} -> {b : a -> Type} ->
  {x : a} -> {y, y' : b x} -> y = y' -> MkDPair {p=b} x y = MkDPair x y'
DPairInjective Refl = Refl

public export
DPairHeterogeneousInjective : {a : Type} -> {b : a -> Type} ->
  {p, p' : DPair a b} ->
  fst p = fst p' -> snd p ~=~ snd p' -> p = p'
DPairHeterogeneousInjective {p = (x ** y)} {p' = (x' ** y')} eqa eqb =
    case eqa of Refl => case eqb of Refl => Refl

public export
UniqueDPairInjective : {a : Type} -> {b : a -> Type} ->
  (bUnique : (x : a) -> (y, y' : b x) -> y = y') ->
  {x : a} -> {y, y' : b x} -> MkDPair {p=b} x y = MkDPair x y'
UniqueDPairInjective bUnique = DPairInjective (bUnique _ _ _)

public export
UniqueHeterogeneousDPairInjective : {a : Type} -> {b : a -> Type} ->
  (bUnique : (x : a) -> (y, y' : b x) -> y = y') ->
  {d, d' : DPair a b} -> fst d = fst d' -> d = d'
UniqueHeterogeneousDPairInjective bUnique {d=(x ** y)} {d'=(x' ** y')} xeq =
  case xeq of
    Refl => UniqueDPairInjective bUnique

public export
Endofunction : Type -> Type
Endofunction a = a -> a

public export
PairOf : Type -> Type
PairOf a = (a, a)

public export
BinaryPredicate : Type -> Type
BinaryPredicate a = PairOf a -> Type

public export
ConstructiveRelation : Type -> Type
ConstructiveRelation = BinaryPredicate

public export
EqualityRel : (a: Type) -> ConstructiveRelation a
EqualityRel _ = \p => fst p = snd p

public export
IsReflexive : {a: Type} -> ConstructiveRelation a -> Type
IsReflexive {a} r = (x: a) -> r (x, x)

public export
IsSymmetric : {a: Type} -> ConstructiveRelation a -> Type
IsSymmetric {a} r = {x, y: a} -> r (x, y) -> r (y, x)

public export
IsTransitive : {a: Type} -> ConstructiveRelation a -> Type
IsTransitive {a} r = {x, y, z: a} -> r (x, y) -> r (y, z) -> r (x, z)

public export
IsPreorder : {a: Type} -> ConstructiveRelation a -> Type
IsPreorder r = (IsReflexive r, IsTransitive r)

public export
Preorder : (a: Type) -> Type
Preorder a = DPair (ConstructiveRelation a) IsPreorder

public export
Precedes : {a: Type} ->
  FunctionsAndRelations.Preorder a -> a -> a -> Type
Precedes p x y = fst p (x, y)

public export
preorderIsReflexive : {a: Type} -> {r: ConstructiveRelation a} ->
                      IsPreorder r -> IsReflexive r
preorderIsReflexive = fst

public export
preorderIsTransitive : {a: Type} -> {r: ConstructiveRelation a} ->
                       IsPreorder r -> IsTransitive r
preorderIsTransitive = snd

public export
IsEquivalence : {a: Type} -> ConstructiveRelation a -> Type
IsEquivalence r = (IsSymmetric r, IsPreorder r)

public export
EquivalenceConditions : {a: Type} -> {r: ConstructiveRelation a} ->
                        IsReflexive r ->
                        IsSymmetric r ->
                        IsTransitive r ->
                        IsEquivalence r
EquivalenceConditions refl sym trans = (sym, (refl, trans))

public export
Equivalence : (a: Type) -> Type
Equivalence a = DPair (ConstructiveRelation a) IsEquivalence

public export
Equivalent : {a: Type} -> (equiv: FunctionsAndRelations.Equivalence a) ->
  ConstructiveRelation a
Equivalent = fst

public export
equivalenceIsPreorder : {a: Type} -> {r: ConstructiveRelation a} ->
                        IsEquivalence r -> IsPreorder r
equivalenceIsPreorder = snd

public export
equivalenceIsReflexive : {a: Type} -> {r: ConstructiveRelation a} ->
                         IsEquivalence r -> IsReflexive r
equivalenceIsReflexive {r} isEquiv =
  preorderIsReflexive {r} (equivalenceIsPreorder {r} isEquiv)

public export
equivalenceIsSymmetric : {a: Type} -> {r: ConstructiveRelation a} ->
                         IsEquivalence r -> IsSymmetric r
equivalenceIsSymmetric = fst

public export
equivalenceIsTransitive : {a: Type} -> {r: ConstructiveRelation a} ->
                          IsEquivalence r -> IsTransitive r
equivalenceIsTransitive {r} isEquiv =
  preorderIsTransitive {r} (equivalenceIsPreorder {r} isEquiv)

public export
equalityIsEquivalence : (a: Type) -> IsEquivalence (EqualityRel a)
equalityIsEquivalence a = EquivalenceConditions {r=(EqualityRel a)}
  (\_ => Refl)
  (\eq => case eq of Refl => Refl)
  (\eqxy, eqyz => case eqxy of Refl => case eqyz of Refl => Refl)

public export
Equality : (a: Type) -> FunctionsAndRelations.Equivalence a
Equality a = (EqualityRel a ** equalityIsEquivalence a)

public export
IsIrreflexive : {a: Type} -> (equiv, order: ConstructiveRelation a) -> Type
IsIrreflexive equiv order = {x, x': a} -> equiv (x, x') -> Not (order (x, x'))

public export
IsAntisymmetric : {a: Type} -> (equiv, order: ConstructiveRelation a) -> Type
IsAntisymmetric {a} equiv order =
  {x, y: a} -> order (x, y) -> order (y, x) -> equiv (x, y)

public export
IsStrictlyAntisymmetric : {a: Type} ->
                          (equiv, order: ConstructiveRelation a) -> Type
IsStrictlyAntisymmetric {a} equiv order =
  {x, x', y, y': a} ->
    equiv (x, x') -> equiv (y, y') -> order (x, y) -> Not (order (y', x'))

public export
IsOrderUpToEquiv : {a: Type} -> (equiv, order: ConstructiveRelation a) -> Type
IsOrderUpToEquiv equiv order = (IsAntisymmetric equiv order, IsPreorder order)

public export
SymmetricMeet : {a: Type} -> ConstructiveRelation a -> ConstructiveRelation a
SymmetricMeet r (x, y) = (r (x, y), r (y, x))

public export
SymmetricMeetOfPreorderIsEquiv : {a: Type} -> {r: ConstructiveRelation a} ->
                                 IsPreorder r -> IsEquivalence (SymmetricMeet r)
SymmetricMeetOfPreorderIsEquiv {r} (isRefl, isTrans) =
  EquivalenceConditions {r=(SymmetricMeet r)}
    (\x => (isRefl x, isRefl x))
    (\p => (snd p, fst p))
    (\rxyx, ryzy => (isTrans (fst rxyx) (fst ryzy),
                     isTrans (snd ryzy) (snd rxyx)))

public export
preOrderIsOrderUpToOwnSymmetricMeet : {a: Type} ->
                                      {r: ConstructiveRelation a} ->
                                      IsPreorder r ->
                                      IsOrderUpToEquiv (SymmetricMeet r) r
preOrderIsOrderUpToOwnSymmetricMeet {r} isPreorder = (MkPair, isPreorder)

public export
IsStrictOrderUpToEquiv :
  {a: Type} -> (equiv, order: ConstructiveRelation a) -> Type
IsStrictOrderUpToEquiv equiv order = (IsStrictlyAntisymmetric equiv order,
                                      IsPreorder order)

public export
SubRelationOrder : {a: Type} -> ConstructiveRelation (ConstructiveRelation a)
SubRelationOrder (rSub, rSuper) = {p: (a, a)} -> rSub p -> rSuper p

public export
SubRelationEquivalence : {a: Type} ->
                         ConstructiveRelation (ConstructiveRelation a)
SubRelationEquivalence (r, r') =
  (SubRelationOrder (r, r'), SubRelationOrder (r', r))

public export
subRelationOrderIsOrder : {a: Type} ->
                          IsOrderUpToEquiv {a=(ConstructiveRelation a)}
                            (SubRelationEquivalence {a}) (SubRelationOrder {a})
subRelationOrderIsOrder = (MkPair, (\_ => id, \r, r' => r' . r))

subRelationEquivalenceIsEquivalence : {a: Type} ->
                                      IsEquivalence {a=(ConstructiveRelation a)}
                                        (SubRelationEquivalence {a})
subRelationEquivalenceIsEquivalence {a} =
  EquivalenceConditions {r=(SubRelationEquivalence {a})}
    (\_ => (id, id))
    (\p => (snd p, fst p))
    (\rp, rp' => (fst rp' . fst rp, snd rp . snd rp'))

public export
FunctionInducedRelation : {a: Type} ->
                          Endofunction a ->
                          ConstructiveRelation a
FunctionInducedRelation f (x, y) = f x = y

public export
InputOutputRelated : {a: Type} ->
                     ConstructiveRelation a ->
                     Endofunction a ->
                     Type
InputOutputRelated r f = (x : a) -> r (x, f x)

export
InducedRelationIsInputOutputRelated : {a: Type} ->
                                      (f: Endofunction a) ->
                                      InputOutputRelated
                                        (FunctionInducedRelation f) f
InducedRelationIsInputOutputRelated f x = Refl

export
InducedRelationIsMinimalRelationWithInputOutputRelated :
  {a: Type} -> (r: ConstructiveRelation a) -> (f: Endofunction a) ->
  InputOutputRelated r f ->
  SubRelationOrder ((FunctionInducedRelation f), r)
InducedRelationIsMinimalRelationWithInputOutputRelated
  r f isRelated {p=(x,y)} isFIrelated =
    rewrite (sym isFIrelated) in isRelated x

public export
PreservesRelation : {a: Type} ->
                    ConstructiveRelation a -> Endofunction a -> Type
PreservesRelation r f = {x, x' : a} -> r (x, x') -> r (f x, f x')

public export
IsLeftInverseUpToEquiv : {a, b: Type} ->
                         (equivA : FunctionsAndRelations.Equivalence a) ->
                         (f : a -> b) -> (inv : b -> a) ->
                         Type
IsLeftInverseUpToEquiv equivA f inv =
  InputOutputRelated (Equivalent equivA) (inv . f)

public export
IsRightInverseUpToEquiv : {a, b: Type} ->
                          (equivB : FunctionsAndRelations.Equivalence b) ->
                          (f : a -> b) -> (inv : b -> a) ->
                          Type
IsRightInverseUpToEquiv equivB f inv =
  InputOutputRelated (Equivalent equivB) (f . inv)

public export
IsInverseUpToEquiv : {a, b: Type} ->
                     (equivA : FunctionsAndRelations.Equivalence a) ->
                     (equivB : FunctionsAndRelations.Equivalence b) ->
                     (f : a -> b) -> (inv : b -> a) ->
                     Type
IsInverseUpToEquiv equivA equivB f inv =
  (IsLeftInverseUpToEquiv equivA f inv, IsRightInverseUpToEquiv equivB f inv)

public export
InverseUpToEquiv : {a, b: Type} ->
                   (equivA : FunctionsAndRelations.Equivalence a) ->
                   (equivB : FunctionsAndRelations.Equivalence b) ->
                   (f : a -> b) -> Type
InverseUpToEquiv equivA equivB f =
  DPair (b -> a) (IsInverseUpToEquiv equivA equivB f)

export
leftInversePreservesEquiv : {a, b: Type} ->
                            {equivA : FunctionsAndRelations.Equivalence a} ->
                            {f : a -> b} ->
                            {inv : b -> a} ->
                            IsLeftInverseUpToEquiv equivA f inv ->
                            PreservesRelation (Equivalent equivA) (inv . f)
leftInversePreservesEquiv {equivA=(eqA ** isEq)} isInv eqx =
  equivalenceIsTransitive {r=eqA} isEq
    (equivalenceIsTransitive {r=eqA} isEq
      (equivalenceIsSymmetric {r=eqA} isEq (isInv _)) eqx)
    (isInv _)

export
rightInversePreservesEquiv : {a, b: Type} ->
                             {equivB : FunctionsAndRelations.Equivalence b} ->
                             {f : a -> b} ->
                             {inv : b -> a} ->
                             IsRightInverseUpToEquiv equivB f inv ->
                             PreservesRelation (Equivalent equivB) (f . inv)
rightInversePreservesEquiv {equivB=(eqB ** isEq)} isInv eqx =
  equivalenceIsTransitive {r=eqB} isEq
    (equivalenceIsTransitive {r=eqB} isEq
      (equivalenceIsSymmetric {r=eqB} isEq (isInv _)) eqx)
    (isInv _)

public export
InverseOverEquality : {a, b: Type} -> (a -> b) -> Type
InverseOverEquality = InverseUpToEquiv (Equality a) (Equality b)

ProductRelation : {a, b: Type} ->
                  ConstructiveRelation a -> ConstructiveRelation b ->
                  ConstructiveRelation (a, b)
ProductRelation ra rb = \pp =>
  let
    p = fst pp
    p' = snd pp
    a = fst p
    b = snd p
    a' = fst p'
    b' = snd p'
  in
  (ra (a, a'), rb (b, b'))

reflProductIsRefl : {a, b: Type} ->
                    {ra: ConstructiveRelation a} ->
                    {rb: ConstructiveRelation b} ->
                    IsReflexive ra -> IsReflexive rb ->
                    IsReflexive (ProductRelation ra rb)
reflProductIsRefl raRefl rbRefl (relA, relB) = (raRefl relA, rbRefl relB)

symProductIsSym : {a, b: Type} ->
                  {ra: ConstructiveRelation a} ->
                  {rb: ConstructiveRelation b} ->
                  IsSymmetric ra -> IsSymmetric rb ->
                  IsSymmetric (ProductRelation ra rb)
symProductIsSym raSym rbSym (relA, relB) = (raSym relA, rbSym relB)

transProductIsTrans : {a, b: Type} ->
                      {ra: ConstructiveRelation a} ->
                      {rb: ConstructiveRelation b} ->
                      IsTransitive ra -> IsTransitive rb ->
                      IsTransitive (ProductRelation ra rb)
transProductIsTrans raTrans rbTrans (relA, relB) (relA', relB') =
  (raTrans relA relA', rbTrans relB relB')

productEquivIsEquiv : {a, b: Type} ->
                      {ra: ConstructiveRelation a} ->
                      {rb: ConstructiveRelation b} ->
                      IsEquivalence ra -> IsEquivalence rb ->
                      IsEquivalence (ProductRelation ra rb)
productEquivIsEquiv {ra} {rb} equivA equivB =
  EquivalenceConditions {r=(ProductRelation ra rb)}
    (reflProductIsRefl {ra} {rb}
      (equivalenceIsReflexive {r=ra} equivA)
      (equivalenceIsReflexive {r=rb} equivB))
    (symProductIsSym {ra} {rb}
      (equivalenceIsSymmetric {r=ra} equivA)
      (equivalenceIsSymmetric {r=rb} equivB))
    (transProductIsTrans {ra} {rb}
      (equivalenceIsTransitive {r=ra} equivA)
      (equivalenceIsTransitive {r=rb} equivB))

public export
SymmetricProduct : {a: Type} ->
                   ConstructiveRelation a -> ConstructiveRelation (a, a)
SymmetricProduct r = ProductRelation r r

public export
SymmetricPairEquivalence : {A: Type} -> FunctionsAndRelations.Equivalence A ->
  FunctionsAndRelations.Equivalence (Pair A A)
SymmetricPairEquivalence equiv =
  (SymmetricProduct (fst equiv) **
    productEquivIsEquiv
      {ra=(fst equiv)} {rb=(fst equiv)} (snd equiv) (snd equiv))

public export
PairPredicate : Type -> Type -> Type
PairPredicate a b = BinaryPredicate (a, b)

public export
PairRelation : (a, b: Type) -> Type
PairRelation a b = ConstructiveRelation (a, b)

public export
PairInducedRelationLeft : {a, b: Type} ->
                          PairRelation a b -> ConstructiveRelation a
PairInducedRelationLeft rp (x, y) =
  (pb : (b, b) ** rp ((x, fst pb), (y, snd pb)))

public export
PairInducedRelationRight : {a, b: Type} ->
                           PairRelation a b -> ConstructiveRelation b
PairInducedRelationRight rp (x, y) =
  (pa : (a, a) ** rp ((fst pa, x), (snd pa, y)))

public export
PairRelationRespectsRelationLeft : {a, b: Type} ->
                                   PairRelation a b ->
                                   ConstructiveRelation a ->
                                   Type
PairRelationRespectsRelationLeft pr ra =
  SubRelationOrder (PairInducedRelationLeft pr, ra)

public export
PairRelationRespectsRelationRight : {a, b: Type} ->
                                    PairRelation a b ->
                                    ConstructiveRelation b ->
                                    Type
PairRelationRespectsRelationRight pr rb =
  SubRelationOrder (PairInducedRelationRight pr, rb)

public export
DependentFunctionBetweenRelatedTypes :
  {a: Type} -> (b: a -> Type) -> ConstructiveRelation a -> Type
DependentFunctionBetweenRelatedTypes b r =
  {x, x': a} -> r (x, x') -> b x -> b x'

public export
DPairPredicate : {a: Type} -> (a -> Type) -> Type
DPairPredicate {a} b = BinaryPredicate (DPair a b)

public export
DPairRelation : {a: Type} -> (a -> Type) -> Type
DPairRelation {a} b = ConstructiveRelation (DPair a b)

public export
DPairInducedRelation : {a: Type} -> {b: a -> Type} ->
                       DPairRelation b -> ConstructiveRelation a
DPairInducedRelation dpr pa = (pb : (b (fst pa), b (snd pa)) **
                               dpr ((fst pa ** fst pb), (snd pa ** snd pb)))

public export
DPairRelationRespectsRelation : {a: Type} -> {b: a -> Type} ->
                                DPairRelation b ->
                                ConstructiveRelation a ->
                                Type
DPairRelationRespectsRelation dpr r =
  SubRelationOrder ((DPairInducedRelation dpr), r)

DependentFunctionRespectsDPairRelations :
  {a: Type} -> (r: ConstructiveRelation a) ->
  {b: a -> Type} -> DPairRelation b ->
  DependentFunctionBetweenRelatedTypes b r ->
  Type
DependentFunctionRespectsDPairRelations {a} r {b} dpr f =
  {x, x': a} -> (rx: r (x, x')) -> (y: b x) -> dpr ((x ** y), (x' ** f rx y))

public export
RelationMap : {a: Type} -> (b: a -> Type) -> Type
RelationMap {a} b =
  DPair (ConstructiveRelation a) (DependentFunctionBetweenRelatedTypes b)

public export
DepRelationMap : {a: Type} -> (b: a -> Type) -> Type
DepRelationMap {a} b = (RelationMap {a} b, DPairRelation b)

public export
DepRelationMapIsRespectful : {a: Type} -> {b: a -> Type} ->
                             DepRelationMap b -> Type
DepRelationMapIsRespectful ((r ** f), dpr) =
  (DPairRelationRespectsRelation dpr r,
   DependentFunctionRespectsDPairRelations r dpr f)

public export
DepRelationMorphism : {a: Type} -> (b: a -> Type) -> Type
DepRelationMorphism {a} b = DPair (DepRelationMap b) DepRelationMapIsRespectful

public export
IsDPairEquivalence : {A: Type} -> {B: A -> Type} -> DepRelationMap B -> Type
IsDPairEquivalence m =
  (DepRelationMapIsRespectful m,
   IsEquivalence (fst (fst m)), IsEquivalence (snd m))

public export
DPairEquivalence : {a: Type} -> (b: a -> Type) -> Type
DPairEquivalence b = DPair (DepRelationMap b) IsDPairEquivalence

prefix 11 !-
public export
(!-) : Type -> Type
(!-) a = a -> Type

infixr 7 ~>
public export
(~>) : (a : Type) -> (b : !- a) -> Type
a ~> b = (x : a) -> b x

infixr 7 ~~>
public export
(~~>) : {a : Type} -> (b: !- a) -> (c : (!- a) -> (!- a)) -> Type
(~~>) {a} b c = (x : a) -> b x -> c b x

export
composePi : {a : Type} ->
  (parameterizedPred : ((!- a) -> (!- a))) ->
  {parameter : (!- a)} ->
  (parameter ~~> parameterizedPred) ->
  (a ~> parameter) ->
  a ~> (parameterizedPred parameter)
composePi parameterizedPred parameterizedPi parameterPi x =
  parameterizedPi x (parameterPi x)

prefix 11 !~
public export
(!~) : {a : Type} -> (!- (!- a))
(!~) {a} b = (x : a) -> b x -> Type

infixl 7 .~
public export
(.~) : {a : Type} -> {b : !- a} -> (!~ b) -> (a ~> b) -> !- a
c .~ f = \x => c x (f x)

prefix 11 !~~
public export
(!~~) : {a : Type} -> {b : !- a} -> (!- (!~ b))
(!~~) {a} {b} c = a ~> (\x => b x ~> c x)

infixl 7 .~~
public export
(.~~) : {a : Type} -> {b : !- a} -> {c : !~ b} ->
  (g : !~~ c) -> (f : a ~> b) -> a ~> (c .~ f)
g .~~ f = \x => g x (f x)

infixl 7 **<
public export
(**<) : {a : Type} -> {b : a -> Type} -> (x : a) -> b x -> DPair a b
(**<) = MkDPair

infixl 7 **~
public export
(**~) : {a : Type} -> {b : a -> Type} -> (x : a) -> (f : a ~> b) -> DPair a b
x **~ f = (x ** f x)

infixl 7 .**
public export
(.**) : {a : Type} -> {b : a -> Type} -> (!- (DPair a b)) -> (a ~> b) -> (!- a)
c .** f = (\x => c (x **~ f))

mutual
  prefix 11 |-
  infixl 7 *~
  infixl 7 *-
  prefix 11 :~

  public export
  data Telescope : Type where
    (|-) : Type -> Telescope
    (*-) : Telescope -> Type -> Telescope
    (*~) :
      (telescope : Telescope) -> (type : (|:~) telescope) ->
      Telescope

  prefix 11 |:~
  public export
  (|:~) : Telescope -> Type
  (|:~) telescope = (!-) (:~ telescope)

  public export
  (:~) : Telescope -> Type
  (:~) (|- type) = type
  (:~) (telescope *- type) = Pair (:~ telescope) type
  (:~) (telescope *~ type) = DPair (:~ telescope) type

prefix 11 |~-
public export
(|~-) : (() -> Type) -> Telescope
(|~-) type = |- type ()

infixl 7 *~-
public export
(*~-) : Telescope -> (() -> Type) -> Telescope
telescope *~- type = telescope *- type ()

infixr 7 :~>
public export
(:~>) : (domain : Telescope) -> (codomain : (|:~) domain) -> Type
domain :~> codomain = (:~ domain) ~> codomain

infixr 7 :*~
public export
(:*~) :
  {a : Telescope} -> {b : (|:~) a} ->
  (c : (|:~) (a *~ b)) -> (f : a :~> b) -> |:~ a
c :*~ f = \x => c (x **~ f)

infixl 7 :.~
public export
(:.~) :
  {a : Telescope} -> {b : (|:~) a} -> {c : (|:~) (a *~ b)} ->
  (g : (a *~ b) :~> c) -> (f : a :~> b) -> (a :~> (c .** f))
g :.~ f = \x => g (x **~ f)

infixl 7 .**~
public export
(.**~) :
  {a : Telescope} -> {b : (|:~) a} -> {c : (|:~) (a *~ b)} ->
  (g : (a *~ b) :~> c) -> (f : a :~> b) ->
  ((:~ a) -> DPair ((:~) (a *~ b)) c)
g .**~ f = \x => x **~ f **~ g

infixl 7 *:~
public export
(*:~) :
  {a : Telescope} -> {b : (|:~) a} -> {c : (|:~) (a *~ b)} ->
  (d : (|:~) (a *~ b *~ c)) -> (f : a :~> b) ->
  (|:~) (a *~ ((:*~) {a} c f))
(*:~) d f = \p => case p of (x ** z) => d (x **~ f **< z)

infixl 7 **:~
public export
(**:~) :
  {a : Telescope} -> {b : (|:~) a} -> {c : (|:~) (a *~ b)} ->
  {d : (|:~) (a *~ b *~ c)} ->
  (h : (a *~ b *~ c) :~> d) ->
  (f : a :~> b) ->
  (a *~ ((:*~) {a} c f)) :~> ((*:~) {a} d f)
(**:~) {d} h f = \p => case p of (x ** z) => h (x **~ f **< z)

export
depComposeAssociative :
  {a : Telescope} -> {b : (|:~) a} -> {c : (|:~) (a *~ b)} ->
  {d : (|:~) (a *~ b *~ c)} ->
  (h : (a *~ b *~ c) :~> d) -> (g : (a *~ b) :~> c) -> (f : a :~> b) ->
  (:.~) {a} {b=(c .** f)} {c=((*:~) {a} d f)}
    ((**:~) {a} {b} {c} {d} h f) ((:.~) {a} {b} {c} g f) =
  (:.~) {a} {b} {c=(d .** g)}
    ((:.~) {a=(a *~ b)} {b=c} {c=d} h g) f
depComposeAssociative h g f = Refl
