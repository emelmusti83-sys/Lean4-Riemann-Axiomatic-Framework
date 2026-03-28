/-
Copyright (c) 2026 Mustafa (isnowx). SPDX-License-Identifier: MIT
Contact: mustafa@snowgamestr.com
-/
import Mathlib
import Riemman.GuinandWeilBridge

noncomputable section

open Complex MeasureTheory
open scoped FourierTransform ComplexInnerProductSpace SchwartzMap

namespace RiemannHypothesisProtocol

/--
Positive linear blends preserve admissibility.

This is the Lean-side synchronization point for the numerical "sharp kernel" hunt:
any kernel produced as a nonnegative blend of already admissible kernels is again
an `AdmissibleKernel`.
-/
def positiveBlend
    (a b : ℝ)
    (ha : 0 ≤ a)
    (hb : 0 ≤ b)
    (g h : AdmissibleKernel) : AdmissibleKernel where
  toSchwartz := (a : ℂ) • g.toSchwartz + (b : ℂ) • h.toSchwartz
  even' x := by
    change (a : ℂ) * g (-x) + (b : ℂ) * h (-x) = (a : ℂ) * g x + (b : ℂ) * h x
    simp [g.even x, h.even x]
  realValued' x := by
    change (((a : ℂ) * g x + (b : ℂ) * h x).im = 0)
    simp [g.realValued x, h.realValued x]
  nonneg' x := by
    have hg : 0 ≤ (g x).re := g.nonneg x
    have hh : 0 ≤ (h x).re := h.nonneg x
    change 0 ≤ (((a : ℂ) * g x + (b : ℂ) * h x).re)
    simp [Complex.mul_re, g.realValued x, h.realValued x]
    nlinarith
  fourierNonneg' x := by
    have hg : 0 ≤ (g.fourierKernel x).re := g.fourierNonneg x
    have hh : 0 ≤ (h.fourierKernel x).re := h.fourierNonneg x
    have hg' : 0 ≤ ((𝓕 g.toSchwartz) x).re := by
      simpa [AdmissibleKernel.fourierKernel] using hg
    have hh' : 0 ≤ ((𝓕 h.toSchwartz) x).re := by
      simpa [AdmissibleKernel.fourierKernel] using hh
    change
      0 ≤
        (((SchwartzMap.fourierTransformCLM ℂ)
            ((a : ℂ) • g.toSchwartz + (b : ℂ) • h.toSchwartz) x).re)
    rw [ContinuousLinearMap.map_add, ContinuousLinearMap.map_smul, ContinuousLinearMap.map_smul]
    change 0 ≤ ((((a : ℂ) • (𝓕 g.toSchwartz) + (b : ℂ) • (𝓕 h.toSchwartz)) x).re)
    change 0 ≤ (((a : ℂ) * (g.fourierKernel x) + (b : ℂ) * (h.fourierKernel x)).re)
    simp [AdmissibleKernel.fourierKernel, Complex.mul_re]
    nlinarith [ha, hb, hg', hh']

/--
Two-scale sharp hybrid kernels. Numerically, these are the templates used for the
"Poisson-like" and "Fejer-like" aggressive hunts.
-/
structure SharpHybridKernel where
  core : AdmissibleKernel
  shoulder : AdmissibleKernel
  coreWeight : ℝ
  shoulderWeight : ℝ
  coreWeight_nonneg : 0 ≤ coreWeight
  shoulderWeight_nonneg : 0 ≤ shoulderWeight

def SharpHybridKernel.toAdmissibleKernel (K : SharpHybridKernel) : AdmissibleKernel :=
  positiveBlend
    K.coreWeight
    K.shoulderWeight
    K.coreWeight_nonneg
    K.shoulderWeight_nonneg
    K.core
    K.shoulder

/-- Poisson-like sharp kernels are modeled as two-scale nonnegative blends. -/
abbrev PoissonLikeKernel := SharpHybridKernel

/-- Fejer-like sharp kernels are modeled as two-scale nonnegative blends. -/
abbrev FejerLikeKernel := SharpHybridKernel

end RiemannHypothesisProtocol
