/-
Copyright (c) 2026 Mustafa (isnowx). SPDX-License-Identifier: MIT
Contact: mustafa@snowgamestr.com
-/
import Mathlib
import Mathlib.Analysis.Distribution.SchwartzSpace.Fourier
import Mathlib.Analysis.Fourier.PoissonSummation
import Riemman.RiemannHypothesisProtocol

noncomputable section

open Complex MeasureTheory
open scoped FourierTransform ComplexInnerProductSpace SchwartzMap BigOperators

namespace RiemannHypothesisProtocol

/--
A Lean-friendly kernel class for Guinand-Weil style explicit formulas.

The kernel is represented as a complex-valued Schwartz function on `ℝ`, together with
the positivity and symmetry conditions one normally wants when building Weil-type
quadratic forms.
-/
structure AdmissibleKernel where
  toSchwartz : 𝓢(ℝ, ℂ)
  even' : ∀ x : ℝ, toSchwartz (-x) = toSchwartz x
  realValued' : ∀ x : ℝ, (toSchwartz x).im = 0
  nonneg' : ∀ x : ℝ, 0 ≤ (toSchwartz x).re
  fourierNonneg' : ∀ x : ℝ, 0 ≤ ((𝓕 toSchwartz) x).re

instance : CoeFun AdmissibleKernel (fun _ => ℝ → ℂ) where
  coe g := g.toSchwartz

abbrev SchwartzKernel := 𝓢(ℝ, ℂ)

/-- The Fourier transform of an admissible kernel, still as a Schwartz function. -/
def AdmissibleKernel.fourierKernel (g : AdmissibleKernel) : SchwartzKernel :=
  𝓕 g.toSchwartz

theorem AdmissibleKernel.fourierKernel_apply (g : AdmissibleKernel) (x : ℝ) :
    g.fourierKernel x = (𝓕 g.toSchwartz) x :=
  rfl

theorem AdmissibleKernel.even (g : AdmissibleKernel) (x : ℝ) :
    g (-x) = g x :=
  g.even' x

theorem AdmissibleKernel.realValued (g : AdmissibleKernel) (x : ℝ) :
    (g x).im = 0 :=
  g.realValued' x

theorem AdmissibleKernel.nonneg (g : AdmissibleKernel) (x : ℝ) :
    0 ≤ (g x).re :=
  g.nonneg' x

theorem AdmissibleKernel.fourierNonneg (g : AdmissibleKernel) (x : ℝ) :
    0 ≤ (g.fourierKernel x).re :=
  g.fourierNonneg' x

theorem AdmissibleKernel.integrable (g : AdmissibleKernel) :
    Integrable g.toSchwartz volume :=
  g.toSchwartz.integrable (μ := volume)

theorem AdmissibleKernel.integrable_fourier (g : AdmissibleKernel) :
    Integrable g.fourierKernel volume :=
  g.fourierKernel.integrable (μ := volume)

/--
The real profile extracted from an admissible kernel. This is the positive test
function currently used in the abstract RH bridge.
-/
def AdmissibleKernel.toPositiveTestKernel (g : AdmissibleKernel) : PositiveTestKernel where
  toFun x := (g x).re
  nonneg' := g.nonneg'

/--
The real Fourier profile that should feed the zero side of a Guinand-Weil formula.

This is where a future formalization can connect critical-line ordinates to the
Schwartz/Fourier interface already available in mathlib.
-/
def AdmissibleKernel.criticalLineProfile (g : AdmissibleKernel) (t : ℝ) : ℝ :=
  (g.fourierKernel t).re

theorem AdmissibleKernel.criticalLineProfile_nonneg (g : AdmissibleKernel) (t : ℝ) :
    0 ≤ g.criticalLineProfile t :=
  g.fourierNonneg t

/--
A nonnegative weighted sample of the Fourier-side profile.

This is the atomic building block for lower bounds on the zero and archimedean sides:
the weight is nonnegative, and the sampled profile is nonnegative by admissibility.
-/
structure FourierProfileSample where
  point : ℝ
  weight : ℝ
  weight_nonneg : 0 ≤ weight

def FourierProfileSample.eval (s : FourierProfileSample) (g : AdmissibleKernel) : ℝ :=
  s.weight * g.criticalLineProfile s.point

theorem FourierProfileSample.eval_nonneg (s : FourierProfileSample) (g : AdmissibleKernel) :
    0 ≤ s.eval g := by
  unfold FourierProfileSample.eval
  exact mul_nonneg s.weight_nonneg (g.criticalLineProfile_nonneg s.point)

abbrev FourierLowerForm := List FourierProfileSample

def FourierLowerForm.eval (L : FourierLowerForm) (g : AdmissibleKernel) : ℝ :=
  (L.map fun s => s.eval g).sum

theorem FourierLowerForm.eval_nonneg (L : FourierLowerForm) (g : AdmissibleKernel) :
    0 ≤ L.eval g := by
  unfold FourierLowerForm.eval
  induction L with
  | nil =>
      simp
  | cons s ss ih =>
      simpa [List.map, FourierProfileSample.eval] using add_nonneg (s.eval_nonneg g) ih

/--
A concrete lower-form candidate for the zero side of the explicit formula.

This package isolates the exact object that should eventually be populated by the
nontrivial zeta zeros with nonnegative multiplicities.
-/
structure ZeroSideLowerCandidate where
  lowerForm : FourierLowerForm

def ZeroSideLowerCandidate.eval (Z : ZeroSideLowerCandidate) (g : AdmissibleKernel) : ℝ :=
  Z.lowerForm.eval g

theorem ZeroSideLowerCandidate.eval_nonneg
    (Z : ZeroSideLowerCandidate) (g : AdmissibleKernel) :
    0 ≤ Z.eval g :=
  Z.lowerForm.eval_nonneg g

/--
A nonnegative weighted sample of the real-side kernel profile.

This is the atomic building block for lower bounds on the prime-power side.
-/
structure KernelValueSample where
  point : ℝ
  weight : ℝ
  weight_nonneg : 0 ≤ weight

def KernelValueSample.eval (s : KernelValueSample) (g : AdmissibleKernel) : ℝ :=
  s.weight * (g s.point).re

theorem KernelValueSample.eval_nonneg (s : KernelValueSample) (g : AdmissibleKernel) :
    0 ≤ s.eval g := by
  unfold KernelValueSample.eval
  exact mul_nonneg s.weight_nonneg (g.nonneg s.point)

abbrev KernelLowerForm := List KernelValueSample

def KernelLowerForm.eval (L : KernelLowerForm) (g : AdmissibleKernel) : ℝ :=
  (L.map fun s => s.eval g).sum

theorem KernelLowerForm.eval_nonneg (L : KernelLowerForm) (g : AdmissibleKernel) :
    0 ≤ L.eval g := by
  unfold KernelLowerForm.eval
  induction L with
  | nil =>
      simp
  | cons s ss ih =>
      simpa [List.map, KernelValueSample.eval] using add_nonneg (s.eval_nonneg g) ih

/--
Data of a Guinand-Weil style explicit-formula model.

`zeroSide` is intended to encode the nontrivial zeros, `archimedeanSide` the
gamma-factor contribution, and `primePowerSide` the prime-power contribution.
The exact analytic formulas are intentionally deferred; this file isolates the
interface that the eventual proof or refutation must satisfy.
-/
structure GuinandWeilDatum where
  zeroSide : AdmissibleKernel → ℝ
  archimedeanSide : AdmissibleKernel → ℝ
  primePowerSide : AdmissibleKernel → ℝ

/--
The candidate quadratic form attached to a Guinand-Weil datum.

The sign convention is intentionally simple here: all analytic work is pushed into the
three component maps. When the explicit formula is instantiated, this definition is the
single place whose sign convention may need adjustment.
-/
def GuinandWeilDatum.Q (D : GuinandWeilDatum) (g : AdmissibleKernel) : ℝ :=
  D.zeroSide g + D.archimedeanSide g + D.primePowerSide g

theorem GuinandWeilDatum.Q_eq (D : GuinandWeilDatum) (g : AdmissibleKernel) :
    D.Q g = D.zeroSide g + D.archimedeanSide g + D.primePowerSide g :=
  rfl

/--
Abstract lower-bound scheme for proving positivity on the admissible cone.

The three sides of the explicit formula are each lower-bounded by sums of
nonnegative profile samples. Since those profile sums are themselves nonnegative,
the total quadratic form cannot drop below zero.
-/
structure PositivityConeExpansion (D : GuinandWeilDatum) where
  zeroLowerForm : FourierLowerForm
  archLowerForm : FourierLowerForm
  primeLowerForm : KernelLowerForm
  zeroLowerBound : ∀ g : AdmissibleKernel, zeroLowerForm.eval g ≤ D.zeroSide g
  archLowerBound : ∀ g : AdmissibleKernel, archLowerForm.eval g ≤ D.archimedeanSide g
  primeLowerBound : ∀ g : AdmissibleKernel, primeLowerForm.eval g ≤ D.primePowerSide g

/--
Main lower-bound lemma:

if a Guinand-Weil datum admits a positivity-cone expansion, then its quadratic form
is nonnegative on every admissible kernel.
-/
theorem GuinandWeilDatum.mainLowerBoundLemma
    (D : GuinandWeilDatum)
    (E : PositivityConeExpansion D)
    (g : AdmissibleKernel) :
    0 ≤ D.Q g := by
  have hz_nonneg : 0 ≤ E.zeroLowerForm.eval g := E.zeroLowerForm.eval_nonneg g
  have ha_nonneg : 0 ≤ E.archLowerForm.eval g := E.archLowerForm.eval_nonneg g
  have hp_nonneg : 0 ≤ E.primeLowerForm.eval g := E.primeLowerForm.eval_nonneg g
  have hlower_nonneg :
      0 ≤ E.zeroLowerForm.eval g + E.archLowerForm.eval g + E.primeLowerForm.eval g := by
    nlinarith [hz_nonneg, ha_nonneg, hp_nonneg]
  have hz_le : E.zeroLowerForm.eval g ≤ D.zeroSide g := E.zeroLowerBound g
  have ha_le : E.archLowerForm.eval g ≤ D.archimedeanSide g := E.archLowerBound g
  have hp_le : E.primeLowerForm.eval g ≤ D.primePowerSide g := E.primeLowerBound g
  have hlower_le_Q :
      E.zeroLowerForm.eval g + E.archLowerForm.eval g + E.primeLowerForm.eval g ≤ D.Q g := by
    dsimp [GuinandWeilDatum.Q]
    nlinarith [hz_le, ha_le, hp_le]
  exact le_trans hlower_nonneg hlower_le_Q

theorem GuinandWeilDatum.positiveCone_of_expansion
    (D : GuinandWeilDatum)
    (E : PositivityConeExpansion D) :
    ∀ g : AdmissibleKernel, 0 ≤ D.Q g :=
  D.mainLowerBoundLemma E

/--
Binding data for the zero side: a concrete lower-form candidate together with the
theorem that it lower-bounds the chosen zero-side functional.
-/
structure ZeroSideBinding (D : GuinandWeilDatum) where
  candidate : ZeroSideLowerCandidate
  lowerBound : ∀ g : AdmissibleKernel, candidate.eval g ≤ D.zeroSide g

/--
Finite-to-global data for the zero side: each partial lower form is nonnegative, and
the evaluations converge to the actual zero-side functional.

This is the exact interface needed to turn summability / convergence information on the
zeta zeros into a concrete lower bound for `zeroSide`.
-/
structure ZeroSideFiniteToGlobal (D : GuinandWeilDatum) where
  partialForms : ℕ → FourierLowerForm
  tendsto_eval :
    ∀ g : AdmissibleKernel,
      Filter.Tendsto (fun n : ℕ => (partialForms n).eval g) Filter.atTop (nhds (D.zeroSide g))

/--
An ordered zero-side sequence, intended to model nontrivial zeta zeros listed by increasing
absolute ordinate and decorated with nonnegative multiplicities.
-/
structure OrderedZeroSequence where
  sample : ℕ → FourierProfileSample
  absMonotone : Monotone fun n => |(sample n).point|

def OrderedZeroSequence.partialForm (Z : OrderedZeroSequence) (N : ℕ) : FourierLowerForm :=
  (List.range N).map Z.sample

theorem OrderedZeroSequence.partialForm_eval_eq_finset_sum
    (Z : OrderedZeroSequence) (N : ℕ) (g : AdmissibleKernel) :
    (Z.partialForm N).eval g = Finset.sum (Finset.range N) (fun i => (Z.sample i).eval g) := by
  induction N with
  | zero =>
      simp [OrderedZeroSequence.partialForm, FourierLowerForm.eval]
  | succ N ih =>
      calc
        (Z.partialForm (N + 1)).eval g
            = (Z.partialForm N).eval g + (Z.sample N).eval g := by
                simp [OrderedZeroSequence.partialForm, FourierLowerForm.eval, List.range_succ,
                  List.map_append, List.sum_append]
        _ = Finset.sum (Finset.range N) (fun i => (Z.sample i).eval g) + (Z.sample N).eval g := by
              rw [ih]
        _ = Finset.sum (Finset.range (N + 1)) (fun i => (Z.sample i).eval g) := by
              rw [Finset.sum_range_succ]

theorem OrderedZeroSequence.tendsto_partialForm_eval_of_hasSum
    (Z : OrderedZeroSequence)
    (D : GuinandWeilDatum)
    (hHasSum : ∀ g : AdmissibleKernel, HasSum (fun n : ℕ => (Z.sample n).eval g) (D.zeroSide g))
    (g : AdmissibleKernel) :
    Filter.Tendsto (fun n : ℕ => (Z.partialForm n).eval g) Filter.atTop (nhds (D.zeroSide g)) := by
  convert (hHasSum g).tendsto_sum_nat using 1
  ext n
  exact OrderedZeroSequence.partialForm_eval_eq_finset_sum Z n g

def OrderedZeroSequence.toZeroSideFiniteToGlobal
    (Z : OrderedZeroSequence)
    (D : GuinandWeilDatum)
    (hHasSum : ∀ g : AdmissibleKernel, HasSum (fun n : ℕ => (Z.sample n).eval g) (D.zeroSide g)) :
    ZeroSideFiniteToGlobal D where
  partialForms := Z.partialForm
  tendsto_eval := Z.tendsto_partialForm_eval_of_hasSum D hHasSum

/--
Analytical kernel package for the zero side:

to prove global convergence, it suffices to dominate the sampled zero-side terms by a
summable majorant depending on the admissible kernel and to identify `zeroSide` with the
resulting infinite sum.
-/
structure ZeroSideAnalyticKernel (D : GuinandWeilDatum) where
  zeros : OrderedZeroSequence
  majorant : AdmissibleKernel → ℕ → ℝ
  majorant_nonneg : ∀ g n, 0 ≤ majorant g n
  dominates : ∀ g n, (zeros.sample n).eval g ≤ majorant g n
  summable_majorant : ∀ g, Summable (majorant g)
  zeroSide_eq_tsum : ∀ g, D.zeroSide g = ∑' n : ℕ, (zeros.sample n).eval g

theorem ZeroSideAnalyticKernel.summable_samples
    (A : ZeroSideAnalyticKernel D)
    (g : AdmissibleKernel) :
    Summable (fun n : ℕ => (A.zeros.sample n).eval g) := by
  exact (A.summable_majorant g).of_nonneg_of_le
    (fun n => (A.zeros.sample n).eval_nonneg g)
    (fun n => A.dominates g n)

theorem ZeroSideAnalyticKernel.hasSum_samples
    (A : ZeroSideAnalyticKernel D)
    (g : AdmissibleKernel) :
    HasSum (fun n : ℕ => (A.zeros.sample n).eval g) (D.zeroSide g) := by
  simpa [A.zeroSide_eq_tsum g] using (A.summable_samples g).hasSum

def ZeroSideAnalyticKernel.toFiniteToGlobal
    (A : ZeroSideAnalyticKernel D) : ZeroSideFiniteToGlobal D :=
  A.zeros.toZeroSideFiniteToGlobal D A.hasSum_samples

def ZeroSideAnalyticKernel.toBinding
    (A : ZeroSideAnalyticKernel D) : ZeroSideBinding D :=
  { candidate := { lowerForm := [] }
    lowerBound := by
      intro g
      have htsum : 0 ≤ ∑' n : ℕ, (A.zeros.sample n).eval g := by
        exact tsum_nonneg (fun n => (A.zeros.sample n).eval_nonneg g)
      simpa [A.zeroSide_eq_tsum g] using htsum }

/--
Power-law specialization of the analytical zero-side kernel.

This packages the most natural final goal for the zeta-zero side: prove that the sampled
profile is bounded by `C_g / (n + 1)^p` for some `p > 1`, and summability follows from the
classical `p`-series criterion already present in `mathlib`.
-/
structure PowerLawZeroMajorant (D : GuinandWeilDatum) where
  zeros : OrderedZeroSequence
  coefficient : AdmissibleKernel → ℝ
  coefficient_nonneg : ∀ g, 0 ≤ coefficient g
  exponent : ℝ
  exponent_gt_one : 1 < exponent
  dominates :
    ∀ g n,
      (zeros.sample n).eval g ≤ coefficient g * (1 / (((n + 1 : ℕ) : ℝ) ^ exponent))
  zeroSide_eq_tsum : ∀ g, D.zeroSide g = ∑' n : ℕ, (zeros.sample n).eval g

theorem PowerLawZeroMajorant.summable_majorant
    (A : PowerLawZeroMajorant D) (g : AdmissibleKernel) :
    Summable (fun n : ℕ => A.coefficient g * (1 / (((n + 1 : ℕ) : ℝ) ^ A.exponent))) := by
  have hbase : Summable (fun n : ℕ => 1 / (((n + 1 : ℕ) : ℝ) ^ A.exponent)) := by
    simpa [Nat.cast_add, Nat.cast_one] using
      ((_root_.summable_nat_add_iff 1).2 (Real.summable_one_div_nat_rpow.mpr A.exponent_gt_one))
  exact hbase.mul_left (A.coefficient g)

def PowerLawZeroMajorant.toAnalyticKernel
    (A : PowerLawZeroMajorant D) : ZeroSideAnalyticKernel D where
  zeros := A.zeros
  majorant := fun g n => A.coefficient g * (1 / (((n + 1 : ℕ) : ℝ) ^ A.exponent))
  majorant_nonneg := by
    intro g n
    refine mul_nonneg (A.coefficient_nonneg g) ?_
    refine one_div_nonneg.2 ?_
    exact Real.rpow_nonneg (by positivity) _
  dominates := A.dominates
  summable_majorant := A.summable_majorant
  zeroSide_eq_tsum := A.zeroSide_eq_tsum

theorem ZeroSideFiniteToGlobal.zeroSide_nonneg
    (D : GuinandWeilDatum)
    (Z : ZeroSideFiniteToGlobal D)
    (g : AdmissibleKernel) :
    0 ≤ D.zeroSide g := by
  by_contra hneg
  have hL : D.zeroSide g < 0 := lt_of_not_ge hneg
  let r : ℝ := -(D.zeroSide g) / 2
  have hr : 0 < r := by
    dsimp [r]
    linarith
  have hBall : Metric.ball (D.zeroSide g) r ∈ nhds (D.zeroSide g) :=
    Metric.ball_mem_nhds (D.zeroSide g) hr
  have hEventually :
      ∀ᶠ n : ℕ in Filter.atTop, (Z.partialForms n).eval g ∈ Metric.ball (D.zeroSide g) r :=
    Z.tendsto_eval g hBall
  obtain ⟨N, hN⟩ := Filter.eventually_atTop.1 hEventually
  have hmem : (Z.partialForms N).eval g ∈ Metric.ball (D.zeroSide g) r := hN N le_rfl
  have hdist : dist ((Z.partialForms N).eval g) (D.zeroSide g) < r := hmem
  have habs :
      |(Z.partialForms N).eval g - D.zeroSide g| < r := by
    simpa [Real.dist_eq] using hdist
  have hupper : (Z.partialForms N).eval g < 0 := by
    have hlt : (Z.partialForms N).eval g - D.zeroSide g < r := (abs_lt.mp habs).2
    dsimp [r] at hlt
    linarith
  have hnonneg : 0 ≤ (Z.partialForms N).eval g :=
    (Z.partialForms N).eval_nonneg g
  linarith

def ZeroSideBinding.ofFiniteToGlobal
    (D : GuinandWeilDatum)
    (Z : ZeroSideFiniteToGlobal D) :
    ZeroSideBinding D where
  candidate := { lowerForm := [] }
  lowerBound := by
    intro g
    simpa using Z.zeroSide_nonneg D g

structure ArchimedeanBinding (D : GuinandWeilDatum) where
  lowerForm : FourierLowerForm
  lowerBound : ∀ g : AdmissibleKernel, lowerForm.eval g ≤ D.archimedeanSide g

structure PrimePowerBinding (D : GuinandWeilDatum) where
  lowerForm : KernelLowerForm
  lowerBound : ∀ g : AdmissibleKernel, lowerForm.eval g ≤ D.primePowerSide g

/--
An explicit-formula binding packages the three lower-bound interfaces together.

This is the point where the abstract positivity cone is finally attached to actual
explicit-formula components.
-/
structure ExplicitFormulaBinding where
  datum : GuinandWeilDatum
  zeroSideBinding : ZeroSideBinding datum
  archimedeanBinding : ArchimedeanBinding datum
  primePowerBinding : PrimePowerBinding datum

def ExplicitFormulaBinding.toPositivityConeExpansion
    (B : ExplicitFormulaBinding) : PositivityConeExpansion B.datum where
  zeroLowerForm := B.zeroSideBinding.candidate.lowerForm
  archLowerForm := B.archimedeanBinding.lowerForm
  primeLowerForm := B.primePowerBinding.lowerForm
  zeroLowerBound := B.zeroSideBinding.lowerBound
  archLowerBound := B.archimedeanBinding.lowerBound
  primeLowerBound := B.primePowerBinding.lowerBound

theorem ExplicitFormulaBinding.zeroSide_nonneg
    (B : ExplicitFormulaBinding) (g : AdmissibleKernel) :
    0 ≤ B.zeroSideBinding.candidate.eval g :=
  B.zeroSideBinding.candidate.eval_nonneg g

theorem ExplicitFormulaBinding.Q_nonneg
    (B : ExplicitFormulaBinding) (g : AdmissibleKernel) :
    0 ≤ B.datum.Q g :=
  B.datum.mainLowerBoundLemma (B.toPositivityConeExpansion) g

theorem ExplicitFormulaBinding.offLineWitnessContradiction
    (B : ExplicitFormulaBinding)
    {ρ : ℂ}
    (_hρ : IsNontrivialZero ρ)
    (_hOff : ¬ OnCriticalLine ρ)
    (hWitness : ∃ g : AdmissibleKernel, B.datum.Q g < 0) :
    False := by
  rcases hWitness with ⟨g, hg⟩
  exact not_lt_of_ge (B.Q_nonneg g) hg

/--
Final witness package for the off-line zero contradiction.

To close the RH route, it is enough to produce, for every off-line zero, one admissible
kernel on which the explicit-formula quadratic form becomes negative.
-/
structure OffLineWitnessScheme (D : GuinandWeilDatum) where
  witnessKernel :
    ∀ {ρ : ℂ},
      IsNontrivialZero ρ →
      ¬ OnCriticalLine ρ →
      AdmissibleKernel
  witnessNegative :
    ∀ {ρ : ℂ}
      (hρ : IsNontrivialZero ρ)
      (hOff : ¬ OnCriticalLine ρ),
      D.Q (witnessKernel hρ hOff) < 0

theorem OffLineWitnessScheme.exists_negative
    (D : GuinandWeilDatum)
    (W : OffLineWitnessScheme D)
    {ρ : ℂ}
    (hρ : IsNontrivialZero ρ)
    (hOff : ¬ OnCriticalLine ρ) :
    ∃ g : AdmissibleKernel, D.Q g < 0 :=
  ⟨W.witnessKernel hρ hOff, W.witnessNegative hρ hOff⟩

theorem ExplicitFormulaBinding.offLineWitnessScheme_contradiction
    (B : ExplicitFormulaBinding)
    {ρ : ℂ}
    (hρ : IsNontrivialZero ρ)
    (hOff : ¬ OnCriticalLine ρ)
    (W : OffLineWitnessScheme B.datum) :
    False :=
  B.offLineWitnessContradiction hρ hOff (OffLineWitnessScheme.exists_negative B.datum W hρ hOff)

/--
An abstract package for the RH strategy:

- positivity of the Guinand-Weil quadratic form on the admissible cone;
- a negativity witness for every off-line zero.

If both are proved for one concrete datum, RH follows.
-/
structure GuinandWeilPackage where
  datum : GuinandWeilDatum
  positiveCone : ∀ g : AdmissibleKernel, 0 ≤ datum.Q g
  offLineWitness :
    ∀ {ρ : ℂ},
      IsNontrivialZero ρ →
      ¬ OnCriticalLine ρ →
      ∃ g : AdmissibleKernel, datum.Q g < 0

theorem riemannHypothesis_of_guinandWeilPackage
    (P : GuinandWeilPackage) :
    RiemannHypothesis := by
  intro s hs
  by_contra hNotCritical
  obtain ⟨g, hg⟩ := P.offLineWitness hs hNotCritical
  exact not_lt_of_ge (P.positiveCone g) hg

def GuinandWeilPackage.ofPositivityConeExpansion
    (D : GuinandWeilDatum)
    (E : PositivityConeExpansion D)
    (hWitness :
      ∀ {ρ : ℂ},
        IsNontrivialZero ρ →
        ¬ OnCriticalLine ρ →
        ∃ g : AdmissibleKernel, D.Q g < 0) :
    GuinandWeilPackage where
  datum := D
  positiveCone := D.positiveCone_of_expansion E
  offLineWitness := hWitness

theorem riemannHypothesis_of_positivityConeExpansion
    (D : GuinandWeilDatum)
    (E : PositivityConeExpansion D)
    (hWitness :
      ∀ {ρ : ℂ},
        IsNontrivialZero ρ →
        ¬ OnCriticalLine ρ →
        ∃ g : AdmissibleKernel, D.Q g < 0) :
    RiemannHypothesis :=
  riemannHypothesis_of_guinandWeilPackage (GuinandWeilPackage.ofPositivityConeExpansion D E hWitness)

theorem riemannHypothesis_of_explicitFormulaBinding
    (B : ExplicitFormulaBinding)
    (hWitness :
      ∀ {ρ : ℂ},
        IsNontrivialZero ρ →
        ¬ OnCriticalLine ρ →
        ∃ g : AdmissibleKernel, B.datum.Q g < 0) :
    RiemannHypothesis :=
  riemannHypothesis_of_positivityConeExpansion B.datum B.toPositivityConeExpansion hWitness

theorem riemannHypothesis_of_binding_and_witnessScheme
    (B : ExplicitFormulaBinding)
    (W : OffLineWitnessScheme B.datum) :
    RiemannHypothesis :=
  riemannHypothesis_of_explicitFormulaBinding B
    (fun hρ hOff => OffLineWitnessScheme.exists_negative B.datum W hρ hOff)

def ExplicitFormulaBinding.ofMajorantAndSideBindings
    (D : GuinandWeilDatum)
    (Z : ZeroSideAnalyticKernel D)
    (A : ArchimedeanBinding D)
    (P : PrimePowerBinding D) :
    ExplicitFormulaBinding where
  datum := D
  zeroSideBinding := Z.toBinding
  archimedeanBinding := A
  primePowerBinding := P

theorem riemannHypothesis_of_majorant_and_witnessScheme
    (D : GuinandWeilDatum)
    (Z : ZeroSideAnalyticKernel D)
    (A : ArchimedeanBinding D)
    (P : PrimePowerBinding D)
    (W : OffLineWitnessScheme D) :
    RiemannHypothesis :=
  riemannHypothesis_of_binding_and_witnessScheme
    (ExplicitFormulaBinding.ofMajorantAndSideBindings D Z A P) W

/--
Generic epsilon-compression lemma:

if a real-valued deformation tends to a strictly positive limit, then it is eventually
nonnegative. This is the abstract limit principle behind the numerical `epsilon -> 0`
compression experiments.
-/
theorem eventually_nonneg_of_tendsto_positive_limit
    {α : Type*}
    {F : Filter α}
    {Q : α → ℝ}
    {L : ℝ}
    (hlim : Filter.Tendsto Q F (nhds L))
    (hL : 0 < L) :
    ∀ᶠ x in F, 0 ≤ Q x := by
  have hBall : Metric.ball L (L / 2) ∈ nhds L := Metric.ball_mem_nhds L (by linarith)
  have hEventually : ∀ᶠ x in F, Q x ∈ Metric.ball L (L / 2) := hlim hBall
  filter_upwards [hEventually] with x hx
  have hdist : dist (Q x) L < L / 2 := hx
  have habs : |Q x - L| < L / 2 := by simpa [Real.dist_eq] using hdist
  have hleft : -(L / 2) < Q x - L := (abs_lt.mp habs).1
  linarith

/--
The current obstruction is now precise:

to prove RH through this route, one must instantiate one concrete `GuinandWeilDatum`
whose `Q` is both positive on every admissible kernel and negative for at least one
admissible kernel whenever an off-line zero exists.
-/
theorem guinandWeil_obstruction_is_explicit :
    GuinandWeilPackage → RiemannHypothesis := by
  intro P
  exact riemannHypothesis_of_guinandWeilPackage P

end RiemannHypothesisProtocol
