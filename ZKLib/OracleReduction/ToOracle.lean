/-
Copyright (c) 2024 ZKLib Contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Quang Dao
-/

import VCVio
import ZKLib.Data.MvPolynomial.Notation
-- import ZKLib.Data.MlPoly.Basic

/-!
  # Definitions and Instances for `ToOracle`

  We define `ToOracle` and give instances for the following:

  - Univariate and multivariate polynomials. These instances turn polynomials into oracles for which
    one can query at a point, and the response is the evaluation of the polynomial on that point.

  - Vectors. This instance turns vectors into oracles for which one can query specific positions.
-/

open OracleComp

/-- `ToOracleData` is a type class that provides an oracle interface for a type `Message`. It
    consists of a query type `Query`, a response type `Response`, and a function `oracle` that
    transforms a message `m : Message` into a function `Query → Response`. -/
@[ext]
class ToOracle (Message : Type) where
  Query : Type
  Response : Type
  oracle : Message → Query → Response

section ToOracle

variable {Message : Type} [O : ToOracle Message]

end ToOracle

def ToOracle.toOracleSpec {ι : Type} (v : ι → Type) [O : ∀ i, ToOracle (v i)] :
    OracleSpec ι := fun i => ((O i).Query, (O i).Response)

instance {ι : Type} (v : ι → Type) [O : ∀ i, ToOracle (v i)]
    [h : ∀ i, DecidableEq (ToOracle.Query (v i))]
    [h' : ∀ i, DecidableEq (ToOracle.Response (v i))] :
    (ToOracle.toOracleSpec v).DecidableEq where
  domain_decidableEq' := h
  range_decidableEq' := h'

instance {ι : Type} (v : ι → Type) [O : ∀ i, ToOracle (v i)]
    [h : ∀ i, Fintype (ToOracle.Response (v i))]
    [h' : ∀ i, Inhabited (ToOracle.Response (v i))] :
    (ToOracle.toOracleSpec v).FiniteRange where
  range_fintype' := h
  range_inhabited' := h'

notation "[" term "]ₒ" => ToOracle.toOracleSpec term

/-- Combines multiple oracle specifications into a single oracle by routing queries to the
      appropriate underlying oracle. Takes:
    - A base oracle specification `oSpec`
    - An indexed type family `T` with `ToOracle` instances
    - Values of that type family
  Returns a stateless oracle that routes queries to the appropriate underlying oracle. -/
def routeOracles1 {ι : Type} (oSpec : OracleSpec ι) {ι' : Type} {T : ι' → Type}
    [∀ i, ToOracle (T i)] (t : ∀ i, T i) : SimOracle (oSpec ++ₒ [T]ₒ) oSpec Unit :=
  statelessOracle fun q => match q with
    | query (.inl i) q => query i q
    | query (.inr i) q => pure (ToOracle.oracle (t i) q)

/-- Combines multiple oracle specifications into a single oracle by routing queries to the
      appropriate underlying oracle. Takes:
    - A base oracle specification `oSpec`
    - Two indexed type families `T₁` and `T₂` with `ToOracle` instances
    - Values of those type families
  Returns a stateless oracle that routes queries to the appropriate underlying oracle. -/
def routeOracles2 {ι : Type} (oSpec : OracleSpec ι)
    {ι₁ : Type} {T₁ : ι₁ → Type} [∀ i, ToOracle (T₁ i)]
    {ι₂ : Type} {T₂ : ι₂ → Type} [∀ i, ToOracle (T₂ i)]
    (t₁ : ∀ i, T₁ i) (t₂ : ∀ i, T₂ i) : SimOracle (oSpec ++ₒ ([T₁]ₒ ++ₒ [T₂]ₒ)) oSpec Unit :=
  statelessOracle fun q => match q with
    | query (.inl i) q => query i q
    | query (.inr (.inl i)) q => pure (ToOracle.oracle (t₁ i) q)
    | query (.inr (.inr i)) q => pure (ToOracle.oracle (t₂ i) q)

/-! ## `ToOracle` Instances -/
section Polynomial

open Polynomial MvPolynomial

variable {R : Type} [CommSemiring R] [DecidableEq R] [Fintype R] [Inhabited R] {d : ℕ}
  {σ : Type} [DecidableEq σ] [Fintype σ]

/-- Univariate polynomials can be accessed via evaluation queries. -/
@[reducible, inline]
instance instToOraclePolynomial : ToOracle R[X] where
  Query := R
  Response := R
  oracle := fun poly point => poly.eval point

/-- Univariate polynomials with degree at most `d` can be accessed via evaluation queries. -/
@[reducible, inline]
instance instToOraclePolynomialDegreeLE : ToOracle (R⦃≤ d⦄[X]) where
  Query := R
  Response := R
  oracle := fun ⟨poly, _⟩ point => poly.eval point

/-- Univariate polynomials with degree less than `d` can be accessed via evaluation queries. -/
@[reducible, inline]
instance instToOraclePolynomialDegreeLT : ToOracle (R⦃< d⦄[X]) where
  Query := R
  Response := R
  oracle := fun ⟨poly, _⟩ point => poly.eval point

/-- Multivariate polynomials can be accessed via evaluation queries. -/
@[reducible, inline]
instance instToOracleMvPolynomial : ToOracle (R[X σ]) where
  Query := σ → R
  Response := R
  oracle := fun poly point => eval point poly

/-- Multivariate polynomials with individual degree at most `d` can be accessed via evaluation
queries. -/
@[reducible, inline]
instance instToOracleMvPolynomialDegreeLE : ToOracle (R⦃≤ d⦄[X σ]) where
  Query := σ → R
  Response := R
  oracle := fun ⟨poly, _⟩ point => eval point poly

end Polynomial

section Vector

variable {n : ℕ} {α : Type} [DecidableEq α] [Fintype α] [Inhabited α]

/-- Vectors of the form `Fin n → α` can be accessed via queries on their indices. -/
instance instToOracleForallFin : ToOracle (Fin n → α) where
  Query := Fin n
  Response := α
  oracle := fun vec i => vec i

/-- Vectors of the form `List.Vector α n` can be accessed via queries on their indices. -/
instance instToOracleListVector : ToOracle (List.Vector α n) where
  Query := Fin n
  Response := α
  oracle := fun vec i => vec[i]

/-- Vectors of the form `Vector α n` can be accessed via queries on their indices. -/
instance instToOracleVector : ToOracle (Vector α n) where
  Query := Fin n
  Response := α
  oracle := fun vec i => vec[i]

end Vector
