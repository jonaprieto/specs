module Executable.Test.Main

import RefinedSExp.Test.TestLibrary
import RefinedSExp.Test.ListTest
import RefinedSExp.Test.SExpTest
import RefinedSExp.Test.SExpApplicativesTest
import RefinedSExp.Test.RefinedSExpTest
import RefinedSExp.Test.AlgebraicTypesTest
import RefinedSExp.Test.DatatypesTest
import RefinedSExp.Test.InductiveDatatypesTest
import RefinedSExp.Test.DependentAlgebraicTypesTest
import RefinedSExp.Test.DependentInductiveDatatypesTest
import RefinedSExp.Old.Test.TestLibrary
import RefinedSExp.Old.Test.ListTest
import RefinedSExp.Old.Test.RefinedListTest
import RefinedSExp.Old.Test.SExpTest
import RefinedSExp.Old.Test.RefinedSExpTest
import RefinedSExp.Old.Test.OldSExpTest
import RefinedSExp.Old.Test.ADTTest
import RefinedSExp.ListVariant.Test.TestLibrary
import RefinedSExp.ListVariant.Test.ListTest
import RefinedSExp.ListVariant.Test.RefinedListTest
import RefinedSExp.ListVariant.Test.SExpTest
import RefinedSExp.ListVariant.Test.RefinedSExpTest

%default total

main : IO ()
main = do
  RefinedSExp.Test.ListTest.listTests
  RefinedSExp.Test.SExpTest.sExpTests
  RefinedSExp.Test.SExpApplicativesTest.sExpApplicativesTests
  RefinedSExp.Test.RefinedSExpTest.refinedSExpTests
  RefinedSExp.Test.AlgebraicTypesTest.algebraicTypesTests
  RefinedSExp.Test.DatatypesTest.datatypesTests
  RefinedSExp.Test.InductiveDatatypesTest.inductiveDatatypesTests
  RefinedSExp.Test.DependentAlgebraicTypesTest.dependentAlgebraicTypesTests
  RefinedSExp.Test.DependentInductiveDatatypesTest.dependentInductiveDatatypesTests
  RefinedSExp.Old.Test.ListTest.listTests
  RefinedSExp.Old.Test.RefinedListTest.refinedListTests
  RefinedSExp.Old.Test.SExpTest.sExpTests
  RefinedSExp.Old.Test.RefinedSExpTest.refinedSExpTests
  RefinedSExp.ListVariant.Test.ListTest.listTests
  RefinedSExp.ListVariant.Test.RefinedListTest.refinedListTests
  RefinedSExp.ListVariant.Test.SExpTest.sExpTests
  RefinedSExp.ListVariant.Test.RefinedSExpTest.refinedSExpTests
