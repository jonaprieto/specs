module RefinedSExp.AlgebraicSExpInterpretation

import public RefinedSExp.AlgebraicSExp
import Data.Maybe
import Library.List

%default total

----------------------------------------------------------------------
---- Computable functions as (Idris-2) functions on S-expressions ----
----------------------------------------------------------------------

-- | A computable function takes an argument and returns either a result or
-- | fails.

public export
GeneralComputableFunction : Type
GeneralComputableFunction = RefinedSExp -> Maybe RefinedSExp

-- | When composing computable functions, any failure of the computation
-- | of any argument of the first function application must produce a
-- | failure in the computation of the second function application.
infixl 1 #.
public export
(#.) : GeneralComputableFunction -> GeneralComputableFunction ->
  GeneralComputableFunction
(#.) = flip (>=>)

public export
IsTotal : GeneralComputableFunction -> Type
IsTotal f = (x : RefinedSExp) -> IsJust $ f x

public export
TotalComputableFunction : Type
TotalComputableFunction = RefinedSExp -> RefinedSExp

public export
toTotal :
  {f : GeneralComputableFunction} -> IsTotal f -> TotalComputableFunction
toTotal isTotal x = IsJustElim $ isTotal x

-- | Extensional equivalence on computable functions.
infixl 1 #~~
public export
(#~~) : GeneralComputableFunction -> GeneralComputableFunction -> Type
f #~~ g = ((x : RefinedSExp) -> f x = g x)

--------------------------------
---- Computable refinements ----
--------------------------------

-- | A refinement is a characteristic function on S-expressions.  A
-- | refinement specificies a decidable subset of S-expressions.
public export
Refinement : Type
Refinement = RefinedSExp -> Bool

public export
ListRefinement : Type
ListRefinement = RefinedSList -> Bool

public export
Signature : Type
Signature = PairOf Type

-- | A compiler is, like any program that we can execute, a computable
-- | function.  What distinguishes a compiler from arbitrary computable
-- | functions is that if a compiler succeeds at compiling some expression,
-- | then the output expression may itself be interpreted as a computable
-- | function.
-- |
-- | Note that this definition admits the possibility that a single
-- | computable function might be interpreted as a compiler in more than
-- | one way.
public export
Compiler : GeneralComputableFunction -> Type
Compiler f = (x : RefinedSExp) -> IsJust (f x) -> GeneralComputableFunction

-- | A strongly normalizing language is one whose functions all terminate.
-- | To interpret a computable function as a compiler for a strongly
-- | normalizing language therefore means interpreting all successful
-- | outputs as _total_ computable functions.  This could be treated as
-- | an expression of the notion that "well-typed programs never go wrong".
-- |
-- | Note that this definition does not require that the compiler _itself_
-- | be a total computable function.
public export
Normalizing : {c : GeneralComputableFunction} -> Compiler c -> Type
Normalizing {c} interpret =
  (x : RefinedSExp) -> (checked : IsJust (c x)) -> IsTotal (interpret x checked)

-------------------------------------------------------------------
---- Interpretations into the top-level metalanguage (Idris-2) ----
-------------------------------------------------------------------

-- | A typechecker in our top-level metalanguage -- in this case Idris-2 --
-- | is a function which decides whether any given expression represents
-- | a metalanguage function, and if so, of what type.
public export
MetaTypechecker : Type
MetaTypechecker = RefinedSExp -> Maybe Signature

-- | An interpreter in our top-level metalanguage -- in this case Idris-2 --
-- | is a function which, given a typechecker, interprets those expressions
-- | which typecheck as functions of the types that the typechecker returns.
public export
MetaInterpreter : MetaTypechecker -> Type
MetaInterpreter typechecker =
  (x : RefinedSExp) -> (signature : IsJust $ typechecker x) ->
  (fst $ IsJustElim signature) -> (snd $ IsJustElim signature)

public export
TypeFamily : Type
TypeFamily = (indexType : Type ** indexType -> Type)

-----------------------------------------------
---- Extensions to admit error propagation ----
-----------------------------------------------

-- | Extend the notion of computable functions to include error propagation,
-- | to allow arbitrary descriptions of the forms of failures in earlier
-- | steps of chains of composed functions.

public export
Annotation : GeneralComputableFunction -> Type
Annotation f = (x : RefinedSExp) -> IsNothing (f x) -> RefinedSExp

public export
AnnotatedComputableFunction : Type
AnnotatedComputableFunction = DPair GeneralComputableFunction Annotation

public export
AnnotatedIsTotal : AnnotatedComputableFunction -> Type
AnnotatedIsTotal = IsTotal . fst

public export
FailurePropagator : Type
FailurePropagator = Endofunction RefinedSExp

public export
ExtendedComputableFunction : Type
ExtendedComputableFunction = (AnnotatedComputableFunction, FailurePropagator)

public export
ExtendedIsTotal : ExtendedComputableFunction -> Type
ExtendedIsTotal = AnnotatedIsTotal . fst

public export
composeUnannotated :
  ExtendedComputableFunction -> AnnotatedComputableFunction ->
  GeneralComputableFunction
composeUnannotated ((g ** _), _) (f ** _) = g #. f

public export
composedAnnotation :
  (g : ExtendedComputableFunction) -> (f : AnnotatedComputableFunction) ->
  Annotation (composeUnannotated g f)
composedAnnotation ((g ** gAnn), gFail) (f ** fAnn) x failure
  with (f x) proof fxeq
    composedAnnotation ((g ** gAnn), gFail) (f ** fAnn) x failure | Just fx =
      gAnn fx failure
    composedAnnotation ((g ** _), gFail) (f ** fAnn) x failure | Nothing =
      let
        rewriteAnn = replace {p=(\fx' => IsNothing (fx') -> RefinedSExp)} fxeq
      in
      gFail $ rewriteAnn (fAnn x) failure

-- | Compose an extended computable function with an annotated computable
-- | function.  (See "railway-oriented programming"!)
infixl 1 ~.
public export
extendedAfterAnnotated :
  ExtendedComputableFunction -> AnnotatedComputableFunction ->
  AnnotatedComputableFunction
extendedAfterAnnotated g f = (composeUnannotated g f ** composedAnnotation g f)

-- | Composition of extended computable functions according to the rules
-- | described above.  (See "railway-oriented programming" again!)
infixl 1 ##.
public export
(##.) : ExtendedComputableFunction -> ExtendedComputableFunction ->
  ExtendedComputableFunction
g ##. (f, fFail) = (extendedAfterAnnotated g f, snd g . fFail)
