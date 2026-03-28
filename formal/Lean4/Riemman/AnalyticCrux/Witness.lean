/-
Copyright (c) 2026 Mustafa (isnowx). SPDX-License-Identifier: MIT
Contact: mustafa@snowgamestr.com
-/
import Riemman.AnalyticCrux.Bindings

noncomputable section

open Complex MeasureTheory Classical
open scoped FourierTransform ComplexInnerProductSpace SchwartzMap

namespace RiemannHypothesisProtocol

/--
Pointwise existence of negative admissible witnesses is enough; choice upgrades it to a full
`OffLineWitnessScheme`.
-/
noncomputable def offLineWitnessScheme_of_exists
    (D : GuinandWeilDatum)
    (hWitness :
      ∀ {ρ : ℂ},
        IsNontrivialZero ρ →
        ¬ OnCriticalLine ρ →
        ∃ g : AdmissibleKernel, D.Q g < 0) :
    OffLineWitnessScheme D where
  witnessKernel := fun {_} hρ hOff => Classical.choose (hWitness hρ hOff)
  witnessNegative := fun {_} hρ hOff => Classical.choose_spec (hWitness hρ hOff)

theorem contradiction_of_pointwise_existential_witness
    (B : ExplicitFormulaBinding)
    {ρ : ℂ}
    (hρ : IsNontrivialZero ρ)
    (hOff : ¬ OnCriticalLine ρ)
    (hWitness : ∃ g : AdmissibleKernel, B.datum.Q g < 0) :
    False :=
  B.offLineWitnessContradiction hρ hOff hWitness

end RiemannHypothesisProtocol
