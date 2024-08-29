/-
Copyright (c) 2024 Quang Dao. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Quang Dao
-/

import Mathlib.Data.Set.Basic
import VCVio

/-!
  # (Oracle) Relations

  This file contains definitions related to NP (oracle) relations. An oracle relation $R$ consists of tuples $(x,w,o)$, where $x$ is called a statement, $w$ is called a witness, and $o$ specifies how the witness may be queried. The validity of a tuple $(x,w,o)$ is determined by the result of an oracle computation, which takes in $x$ and may query the oracle $o$ before returning a boolean value.

  Relations can be parametrized by additional data (public parameters) such as the choice of a field. We do not explicitly mention these public parameters in the definition of the relation; instead, they are assumed to be implicit variables in each instantiation.

  We define the corresponding language `L_R` to be the set of all `stmt`s such that there exists some `wit` with `(stmt, wit) ∈ R`.
-/


/-- An oracle relation -/
structure OracleRelation where
  Statement : Type
  Witness : Type
  enumOracle : Type
  oracle : Witness → OracleSpec enumOracle
  isValid : Statement → (wit : Witness) → OracleComp (oracle wit) Bool

/-- A non-oracle relation -/
structure Relation where
  Statement : Type
  Witness : Type
  isValid : Statement → Witness → Prop

/-- Alternate form where the statement and witness are in a tuple -/
def Relation.isValid' (R : Relation) : R.Statement × R.Witness → Prop := fun ⟨stmt, wit⟩ => R.isValid stmt wit

-- def Relation.isValidBool (R : Relation) : R.Statement × R.Witness → Bool := fun ⟨stmt, wit⟩ => R.isValid stmt wit

/-- A relation family indexed by `Index` -/
structure RelationFamily where
  Index : Type
  Relation : Index → Relation

/-- The trivial Boolean relation -/
def boolRel (AnyWitness : Type) : Relation where
  Statement := Bool
  Witness := AnyWitness
  isValid := fun stmt _ => stmt

namespace Relation

/-- The corresponding language (as a set) for a relation -/
def language (R : Relation) : Set R.Statement :=
  { stmt : R.Statement | ∃ wit : R.Witness, R.isValid stmt wit }

/-- If the witness type is empty, the language is empty -/
def boolRelEmpty : Relation := boolRel Empty

theorem boolRelEmpty_language : boolRelEmpty.language = ∅ := by
  unfold language boolRelEmpty boolRel
  simp

/-- If the witness type is nonempty, the language is just `true` -/
theorem boolRel_language (AnyWitness : Type _) [Nonempty AnyWitness] : (boolRel AnyWitness).language = { true } := by
  unfold language boolRel
  simp

end Relation