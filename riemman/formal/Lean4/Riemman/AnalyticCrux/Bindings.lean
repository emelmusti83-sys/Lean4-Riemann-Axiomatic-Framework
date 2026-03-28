/-
Copyright (c) 2026 Mustafa (isnowx). SPDX-License-Identifier: MIT
Contact: mustafa@snowgamestr.com
-/
import Riemman.AnalyticCrux.ZeroSideMajorant
import Riemman.ConcreteTruncationModel

noncomputable section

open Complex MeasureTheory
open scoped FourierTransform ComplexInnerProductSpace SchwartzMap

namespace RiemannHypothesisProtocol

/--
The finite truncation model provides a concrete sanity-check instance of an explicit binding.
-/
theorem finiteTruncation_Q_nonneg_via_binding
    (model : FiniteTruncationModel)
    (g : AdmissibleKernel)
    (hArch : ∀ node ∈ model.archimedeanNodes, 0 ≤ node.weight)
    (hPrime : ∀ term ∈ model.primePowerTerms, 0 ≤ term.signedWeight) :
    0 ≤ model.toDatum.Q g :=
  (model.explicitFormulaBinding hArch hPrime).Q_nonneg g

end RiemannHypothesisProtocol
