module ReflectiveLanguages.Substitutive

import Library.FunctionsAndRelations
import Library.Decidability
import RefinedSExp.List
import public Datatypes.DependentAlgebraicTypes
import public Data.Nat

%default total

prefix 11 *^
prefix 11 *|
infixl 7 *~

mutual
  -- | An S-expression whose only atoms are de Bruijn indices.
  -- | The "C" prefix is for "Context"; de Bruijn indices are references
  -- | to variables in a context.
  -- |
  -- | An S-expression may be either an atom or a list of S-expressions.
  public export
  data CSExp : (contextSize : Nat) -> Type where
    -- | An atom, which is a de Bruijn index.
    (*^) : {contextSize : Nat} -> (index : Nat) ->
      {auto indexValid : index `LT` contextSize} -> CSExp contextSize
    -- | A list of S-expressions.
    (*|) : {contextSize : Nat} -> CSList contextSize -> CSExp contextSize

  -- | The list form of S-expressions whose only atoms are de Bruijn indices.
  public export
  data CSList : (contextSize : Nat) -> Type where
    -- | The empty list, which may be formed in any context.
    (*-) : {contextSize : Nat} -> CSList contextSize
    -- | A non-empty list whose tail's context includes the head.
    -- | This is a dependent list, also known as a telescope.
    (*~) : {contextSize : Nat} ->
      CSExp contextSize -> CSList (S contextSize) -> CSList contextSize

mutual
  public export
  -- | Introduce an unused variable into the context of an S-expression.
  csIntroOne : {origContextSize : Nat} -> CSExp origContextSize ->
    CSExp (S origContextSize)
  csIntroOne ((*^) index {indexValid}) =
    (*^) index {indexValid=(lteSuccRight indexValid)}
  csIntroOne (*| l) = *| (cslIntroOne l)

  public export
  -- | Introduce an unused variable into the context of an S-list.
  cslIntroOne : {origContextSize : Nat} -> CSList origContextSize ->
    CSList (S origContextSize)
  cslIntroOne (*-) = (*-)
  cslIntroOne (hd *~ tl) = csIntroOne hd *~ cslIntroOne tl

-- | Introduce unused variables into the context of an S-expression.
public export
csIntro : {newVars, origContextSize : Nat} ->
  CSExp origContextSize -> CSExp (newVars + origContextSize)
csIntro {newVars=Z} x = x
csIntro {newVars=(S Z)} x = csIntroOne x
csIntro {newVars=(S (S n))} x = csIntroOne (csIntro {newVars=(S n)} x)

-- | Introduce unused variables into the context of an S-list.
public export
cslIntro : {newVars, origContextSize : Nat} ->
  CSList origContextSize -> CSList (newVars + origContextSize)
cslIntro {newVars=Z} x = x
cslIntro {newVars=(S Z)} x = cslIntroOne x
cslIntro {newVars=(S (S n))} x = cslIntroOne (cslIntro {newVars=(S n)} x)

-- | A non-empty list whose tail's context does not include the head.
-- | This is a non-dependent cons.
infixr 7 *:
public export
(*:) : {contextSize : Nat} ->
  CSExp contextSize -> CSList contextSize -> CSList contextSize
hd *: tl = hd *~ (cslIntro {newVars=1} tl)

-- | A non-dependent list.
public export
csList : {contextSize : Nat} -> List (CSExp contextSize) -> CSList contextSize
csList [] = (*-)
csList (x :: xs) = x *: (csList xs)

-- | Decide whether all members of a list of indices are in bounds.
public export
isValidIndexList : (contextSize : Nat) -> List Nat -> Bool
isValidIndexList contextSize [] = True
isValidIndexList contextSize (index :: indices) =
  index < contextSize && isValidIndexList contextSize indices

-- | A proof that all members of a list of indices are in bounds.
public export
IsValidIndexList : (contextSize : Nat) -> List Nat -> Type
IsValidIndexList contextSize indices =
  IsTrue (isValidIndexList contextSize indices)

public export
CSNPred : Nat -> Type
CSNPred contextSize = CSExp contextSize -> Bool

public export
CSPred : Type
CSPred = (contextSize : Nat) -> CSNPred contextSize

public export
CSLNPred : Nat -> Type
CSLNPred contextSize = CSList contextSize -> Bool

public export
CSLPred : Type
CSLPred = (contextSize : Nat) -> CSLNPred contextSize

-- | Keyword atoms of S-expressions which represent refinements.
public export
data Keyword : Type where
  -- | The initial refinement.
  KVoid : Keyword
  -- | The terminal refinement.
  KUnit : Keyword
  -- | A primitive expression in a particular refined S-expression language.
  KPrimitive : Keyword

-- | Atoms of S-expressions which represent refinements.
public export
data RAtom : (symbol : Type) -> Type where
  -- | A keyword atom.
  RKeyword : {symbol : Type} -> Keyword -> RAtom symbol
  -- | A symbol specific to a particular language.
  RSymbol : {symbol : Type} -> symbol -> RAtom symbol

-- | Shorthand for the initial refinement in a particular refined S-expression
-- | language.
public export
RKVoid : {symbol : Type} -> RAtom symbol
RKVoid = RKeyword KVoid

-- | Shorthand for the terminal refinement in a particular refined S-expression
-- | language.
public export
RKUnit : {symbol : Type} -> RAtom symbol
RKUnit = RKeyword KUnit

-- | Shorthand for a primitive expression in a particular refined S-expression
-- | language.
public export
RKPrimitive : {symbol : Type} -> RAtom symbol
RKPrimitive = RKeyword KPrimitive

-- | S-expressions using the symbols of a particular refined S-expression
-- | language, along with keywords, as atoms.
public export
RExp : (symbol : Type) -> Type
RExp = SExp . RAtom

-- | S-lists using the symbols of a particular refined S-expression
-- | language, along with keywords, as atoms.
public export
RList : (symbol : Type) -> Type
RList = SList . RAtom

-- | The definition of a particular refined S-expression language.
public export
record RefinementLanguage where
  constructor RefinementLanguageArgs
  rlApplicative : Type -> Type
  rlIsApplicative : Applicative rlApplicative
  rlContext : Type
  rlPrimitive : Type
  rlBadPrimitive : rlContext -> rlPrimitive -> Type
  rlPrimitiveType : (context : rlContext) -> (primitive : rlPrimitive) ->
    rlApplicative $ Either (RExp rlPrimitive) (rlBadPrimitive context primitive)

-- | The atoms of a particular S-expression language.
public export
RLAtom : RefinementLanguage -> Type
RLAtom = RAtom . rlPrimitive

-- | The S-expressions of a particular language.
public export
RLExp : RefinementLanguage -> Type
RLExp = RExp . rlPrimitive

-- | The S-lists of a particular language.
public export
RLList : RefinementLanguage -> Type
RLList = RList . rlPrimitive

mutual
  -- | An individual typecheck error for a particular refined S-expression
  -- | language.
  public export
  data TypecheckError : (rl : RefinementLanguage) ->
    (context : rl.rlContext) -> (x : RLExp rl) -> Type where
      BadPrimitive : rl.rlBadPrimitive context primitive ->
        TypecheckError rl context $ RKPrimitive $:^ RSymbol primitive

  -- | The result of a successful typecheck of @x, returning type @type.
  public export
  data TypecheckSuccess : (rl : RefinementLanguage) ->
    (context : rl.rlContext) -> (type : RLExp rl) -> (x : RLExp rl) ->
    Type where
      SymbolSuccess :
        (rl : RefinementLanguage) -> (context : rl.rlContext) ->
        (type : RLExp rl) -> (a : RLAtom rl) ->
        TypecheckSuccess rl context type ($^ a)

  -- | The result of a failed typecheck of @x, which contains one or more
  -- | @TypecheckError terms.  It may also contain successful typechecks
  -- | of sub-expressions of the failed original expression.
  data TypecheckFailure : (rl : RefinementLanguage) ->
    (context : rl.rlContext) -> (x : RLExp rl) -> Type where
      TypecheckAtomFailed : (rl : RefinementLanguage) ->
        (context : rl.rlContext) -> (a : RLAtom rl) ->
        TypecheckError rl context ($^ a) ->
        TypecheckFailure rl context ($^ a)
      TypecheckListFailed : (rl : RefinementLanguage) ->
        (context : rl.rlContext) -> (a : RLAtom rl) ->
        TypecheckError rl context ($^ a) ->
        TypecheckFailure rl context ($^ a)
      TypecheckNilFailed : (rl : RefinementLanguage) ->
        (context : rl.rlContext) -> TypecheckError rl context ($-) ->
        TypecheckFailure rl context ($-)

  -- | The result of attempting to typecheck an S-expression as a word
  -- | of a particular refined S-expression language.
  public export
  data TypecheckResult : (rl : RefinementLanguage) ->
    (context : rl.rlContext) -> (x : RLExp rl) -> Type where
      TypecheckSucceeded : (rl : RefinementLanguage) ->
        (context : rl.rlContext) -> (x : RLExp rl) -> (type : RLExp rl) ->
        TypecheckSuccess rl context type x -> TypecheckResult rl context x
      TypecheckFailed : (rl : RefinementLanguage) ->
        (context : rl.rlContext) -> (x : RLExp rl) -> (type : RLExp rl) ->
        TypecheckFailure rl context x -> TypecheckResult rl context x

  -- | A witness that a typecheck result is a success.
  public export
  data IsTypecheckSuccess : {rl : RefinementLanguage} ->
    {context : rl.rlContext} -> {x : RLExp rl} ->
    TypecheckResult rl context x -> Type where
      ResultIsSuccessful : (success : TypecheckSuccess rl context x type) ->
        (success : TypecheckSuccess rl context type x) ->
        IsTypecheckSuccess (TypecheckSucceeded rl context x type success)
