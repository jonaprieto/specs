module RefinedSExp.AlgebraicSExpInterpretation

import public RefinedSExp.AlgebraicSExp

%default total

public export
Contract : {domain, codomain : Type} -> (f : domain -> codomain) -> Type
Contract {domain} {codomain} f =
  (P : domain -> Type ** Q : codomain -> Type ** (x : domain) -> P x -> Q (f x))

mutual
  public export
  interpretRefinedObject :
    {representation : RefinedSExp} -> RefinedObject representation -> Type
  interpretRefinedObject RefinedVoid = Void
  interpretRefinedObject RefinedUnit = ()

  public export
  interpretRefinedMorphism :
    {representation, domainRep, codomainRep : RefinedSExp} ->
    {domain : RefinedObject domainRep} ->
    {codomain : RefinedObject codomainRep} ->
    RefinedMorphism representation domainRep codomainRep ->
    (interpretRefinedObject domain -> interpretRefinedObject codomain)
  interpretRefinedMorphism {domain} (RefinedFromVoid _) =
    case domain of
      RefinedVoid => \v : Void => void v
      RefinedUnit impossible
  interpretRefinedMorphism {codomain} (RefinedToUnit _) =
    case codomain of
      RefinedVoid impossible
      RefinedUnit => \v => ()

  public export
  interpretRefinedContract :
    {representation, domainRep, codomainRep, subjectMorphismRep :
      RefinedSExp} ->
    {domain : RefinedObject domainRep} ->
    {codomain : RefinedObject codomainRep} ->
    {subjectMorphism :
      RefinedMorphism subjectMorphismRep domainRep codomainRep} ->
    RefinedContract representation domainRep codomainRep subjectMorphismRep ->
    Contract (interpretRefinedMorphism {domain} {codomain} subjectMorphism)
  interpretRefinedContract _ impossible
