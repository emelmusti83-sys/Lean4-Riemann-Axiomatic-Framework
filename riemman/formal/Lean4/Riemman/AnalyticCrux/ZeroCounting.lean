/-
Copyright (c) 2026 Mustafa (isnowx). SPDX-License-Identifier: MIT
Contact: mustafa@snowgamestr.com
-/
import Riemman.GuinandWeilBridge

noncomputable section

open Complex MeasureTheory
open scoped FourierTransform ComplexInnerProductSpace SchwartzMap

namespace RiemannHypothesisProtocol

/--
Zero-side positivity becomes immediate once an analytic kernel package has been supplied.

This file isolates the exact point where zero-counting / zero-ordering input is consumed.
-/
def zeroSideBinding_of_analyticKernel
    (D : GuinandWeilDatum)
    (Z : ZeroSideAnalyticKernel D) :
    ZeroSideBinding D :=
  Z.toBinding

theorem zeroSide_nonneg_of_analyticKernel
    (D : GuinandWeilDatum)
    (Z : ZeroSideAnalyticKernel D)
    (g : AdmissibleKernel) :
    0 ≤ D.zeroSide g := by
  have hLower : Z.toBinding.candidate.eval g ≤ D.zeroSide g := Z.toBinding.lowerBound g
  exact le_trans (Z.toBinding.candidate.eval_nonneg g) hLower

/--
The power-law majorant is the sharpest zero-counting target currently encoded in the project.
-/
def zeroSideBinding_of_powerLawMajorant
    (D : GuinandWeilDatum)
    (Z : PowerLawZeroMajorant D) :
    ZeroSideBinding D :=
  Z.toAnalyticKernel.toBinding

theorem zeroSide_nonneg_of_powerLawMajorant
    (D : GuinandWeilDatum)
    (Z : PowerLawZeroMajorant D)
    (g : AdmissibleKernel) :
    0 ≤ D.zeroSide g :=
  zeroSide_nonneg_of_analyticKernel D Z.toAnalyticKernel g

end RiemannHypothesisProtocol
