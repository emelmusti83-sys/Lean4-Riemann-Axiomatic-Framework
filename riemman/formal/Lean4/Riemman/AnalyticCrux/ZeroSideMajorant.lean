/-
Copyright (c) 2026 Mustafa (isnowx). SPDX-License-Identifier: MIT
Contact: mustafa@snowgamestr.com
-/
import Riemman.AnalyticCrux.ZeroCounting

noncomputable section

open Complex MeasureTheory
open scoped FourierTransform ComplexInnerProductSpace SchwartzMap

namespace RiemannHypothesisProtocol

/--
Once the zero side is controlled by a power-law majorant, the remaining work is to bind the other
two explicit-formula sides.
-/
def explicitFormulaBinding_of_powerLawMajorant
    (D : GuinandWeilDatum)
    (Z : PowerLawZeroMajorant D)
    (A : ArchimedeanBinding D)
    (P : PrimePowerBinding D) :
    ExplicitFormulaBinding :=
  ExplicitFormulaBinding.ofMajorantAndSideBindings D Z.toAnalyticKernel A P

theorem Q_nonneg_of_powerLawMajorant
    (D : GuinandWeilDatum)
    (Z : PowerLawZeroMajorant D)
    (A : ArchimedeanBinding D)
    (P : PrimePowerBinding D)
    (g : AdmissibleKernel) :
    0 ≤ D.Q g := by
  let B := explicitFormulaBinding_of_powerLawMajorant D Z A P
  simpa [B] using B.Q_nonneg g

end RiemannHypothesisProtocol
