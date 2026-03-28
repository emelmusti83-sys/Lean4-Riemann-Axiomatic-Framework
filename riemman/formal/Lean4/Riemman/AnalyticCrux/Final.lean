/-
Copyright (c) 2026 Mustafa (isnowx). SPDX-License-Identifier: MIT
Contact: mustafa@snowgamestr.com
-/
import Riemman.AnalyticCrux.Witness

noncomputable section

open Complex MeasureTheory
open scoped FourierTransform ComplexInnerProductSpace SchwartzMap

namespace RiemannHypothesisProtocol

/--
The final project-level theorem shape:

an actual zero-side analytic majorant, actual archimedean and prime bindings, and a pointwise
existence theorem for negative admissible witnesses together imply RH.
-/
theorem riemannHypothesis_of_powerLawMajorant_and_existentialWitness
    (D : GuinandWeilDatum)
    (Z : PowerLawZeroMajorant D)
    (A : ArchimedeanBinding D)
    (P : PrimePowerBinding D)
    (hWitness :
      ∀ {ρ : ℂ},
        IsNontrivialZero ρ →
        ¬ OnCriticalLine ρ →
        ∃ g : AdmissibleKernel, D.Q g < 0) :
    RiemannHypothesis := by
  let B := explicitFormulaBinding_of_powerLawMajorant D Z A P
  let W := offLineWitnessScheme_of_exists D hWitness
  exact riemannHypothesis_of_binding_and_witnessScheme B W

end RiemannHypothesisProtocol
