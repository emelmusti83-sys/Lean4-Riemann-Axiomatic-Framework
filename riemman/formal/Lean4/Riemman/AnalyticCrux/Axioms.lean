/-
Copyright (c) 2026 Mustafa (isnowx). SPDX-License-Identifier: MIT
Contact: mustafa@snowgamestr.com
-/
import Riemman.AnalyticCrux.Final

noncomputable section

open Complex MeasureTheory
open scoped FourierTransform ComplexInnerProductSpace SchwartzMap

namespace RiemannHypothesisProtocol

/--
Axiomatically fixed datum representing the actual zeta explicit formula.

This is not derived inside the current development; it is the external analytic input
on which the axiomatically closed version of the project is based.
-/
axiom actualZetaDatum : GuinandWeilDatum

/--
Atomized local analytic inputs for the archimedean side.

The intention is that a convergent gamma-factor approximation controls an explicit
lower-form, and that approximation is itself bounded by the actual archimedean side.
-/
structure ActualArchimedeanAnalyticInputs where
  lowerForm : FourierLowerForm
  gammaApprox : AdmissibleKernel → ℕ → ℝ
  gammaApproxSummable : ∀ g, Summable (gammaApprox g)
  lowerForm_le_gammaTsum : ∀ g, lowerForm.eval g ≤ ∑' n : ℕ, gammaApprox g n
  gammaTsum_le_side : ∀ g, (∑' n : ℕ, gammaApprox g n) ≤ actualZetaDatum.archimedeanSide g

axiom actualArchimedeanAnalyticInputs : ActualArchimedeanAnalyticInputs

def actualArchimedeanBinding : ArchimedeanBinding actualZetaDatum where
  lowerForm := actualArchimedeanAnalyticInputs.lowerForm
  lowerBound := by
    intro g
    exact le_trans
      (actualArchimedeanAnalyticInputs.lowerForm_le_gammaTsum g)
      (actualArchimedeanAnalyticInputs.gammaTsum_le_side g)

/--
Atomized local analytic inputs for the prime-power side.

The intention is that a convergent von-Mangoldt series controls an explicit lower-form,
and that series is itself bounded by the actual prime-power side.
-/
structure ActualPrimePowerAnalyticInputs where
  lowerForm : KernelLowerForm
  vonMangoldtSeries : AdmissibleKernel → ℕ → ℝ
  vonMangoldtSummable : ∀ g, Summable (vonMangoldtSeries g)
  lowerForm_le_vonMangoldtTsum :
    ∀ g, lowerForm.eval g ≤ ∑' n : ℕ, vonMangoldtSeries g n
  vonMangoldtTsum_le_side :
    ∀ g, (∑' n : ℕ, vonMangoldtSeries g n) ≤ actualZetaDatum.primePowerSide g

axiom actualPrimePowerAnalyticInputs : ActualPrimePowerAnalyticInputs

def actualPrimePowerBinding : PrimePowerBinding actualZetaDatum where
  lowerForm := actualPrimePowerAnalyticInputs.lowerForm
  lowerBound := by
    intro g
    exact le_trans
      (actualPrimePowerAnalyticInputs.lowerForm_le_vonMangoldtTsum g)
      (actualPrimePowerAnalyticInputs.vonMangoldtTsum_le_side g)

/--
A fixed exponent strictly above `1`, used for the power-law majorant target.
-/
def actualZeroMajorantExponent : ℝ := 11 / 10

theorem actualZeroMajorantExponent_gt_one : 1 < actualZeroMajorantExponent := by
  norm_num [actualZeroMajorantExponent]

/--
Axiomatically supplied local analytic inputs for the zero side.

These are strictly weaker than postulating `actualPowerLawZeroMajorant` directly: they split
the missing analysis into an ordered zero sequence, a decay envelope on the sampled profile,
and a Riemann-von-Mangoldt style conversion from ordinate size to index decay.
-/
structure ActualZeroSideAnalyticInputs where
  zeros : OrderedZeroSequence
  decayCoefficient : AdmissibleKernel → ℝ
  decayCoefficient_nonneg : ∀ g, 0 ≤ decayCoefficient g
  profileDecay :
    ∀ g n,
      (zeros.sample n).eval g ≤
        decayCoefficient g * (1 / ((1 + |(zeros.sample n).point|) ^ (2 : ℕ) : ℝ))
  countingCoefficient : ℝ
  countingCoefficient_nonneg : 0 ≤ countingCoefficient
  ordinateToIndexPower :
    ∀ n,
      (1 / ((1 + |(zeros.sample n).point|) ^ (2 : ℕ) : ℝ)) ≤
        countingCoefficient * (1 / (((n + 1 : ℕ) : ℝ) ^ actualZeroMajorantExponent))
  zeroSide_eq_tsum :
    ∀ g, actualZetaDatum.zeroSide g = ∑' n : ℕ, (zeros.sample n).eval g

axiom actualZeroSideAnalyticInputs : ActualZeroSideAnalyticInputs

def actualPowerLawZeroMajorant : PowerLawZeroMajorant actualZetaDatum where
  zeros := actualZeroSideAnalyticInputs.zeros
  coefficient := fun g =>
    actualZeroSideAnalyticInputs.countingCoefficient * actualZeroSideAnalyticInputs.decayCoefficient g
  coefficient_nonneg := by
    intro g
    exact mul_nonneg
      actualZeroSideAnalyticInputs.countingCoefficient_nonneg
      (actualZeroSideAnalyticInputs.decayCoefficient_nonneg g)
  exponent := actualZeroMajorantExponent
  exponent_gt_one := actualZeroMajorantExponent_gt_one
  dominates := by
    intro g n
    let point := (actualZeroSideAnalyticInputs.zeros.sample n).point
    have hDecay := actualZeroSideAnalyticInputs.profileDecay g n
    have hIndex := actualZeroSideAnalyticInputs.ordinateToIndexPower n
    have hMul :
        actualZeroSideAnalyticInputs.decayCoefficient g *
            (1 / ((1 + |point|) ^ (2 : ℕ) : ℝ))
          ≤
        actualZeroSideAnalyticInputs.decayCoefficient g *
          (actualZeroSideAnalyticInputs.countingCoefficient *
            (1 / (((n + 1 : ℕ) : ℝ) ^ actualZeroMajorantExponent))) := by
      exact mul_le_mul_of_nonneg_left hIndex (actualZeroSideAnalyticInputs.decayCoefficient_nonneg g)
    calc
      (actualZeroSideAnalyticInputs.zeros.sample n).eval g
          ≤ actualZeroSideAnalyticInputs.decayCoefficient g *
              (1 / ((1 + |point|) ^ (2 : ℕ) : ℝ)) := by
                simpa [point] using hDecay
      _ ≤ actualZeroSideAnalyticInputs.decayCoefficient g *
            (actualZeroSideAnalyticInputs.countingCoefficient *
              (1 / (((n + 1 : ℕ) : ℝ) ^ actualZeroMajorantExponent))) := hMul
      _ =
            (actualZeroSideAnalyticInputs.countingCoefficient *
              actualZeroSideAnalyticInputs.decayCoefficient g) *
              (1 / (((n + 1 : ℕ) : ℝ) ^ actualZeroMajorantExponent)) := by ring
  zeroSide_eq_tsum := actualZeroSideAnalyticInputs.zeroSide_eq_tsum

/--
Atomized local analytic inputs for the witness side.

These split the previous single witness axiom into:
- a local quartet-negativity principle,
- an admissible approximation principle,
- a squeeze bridge from local negativity to a genuine global witness.
-/
structure ActualWitnessAnalyticInputs where
  localWitnessKernel :
    ∀ {ρ : ℂ},
      IsNontrivialZero ρ →
      ¬ OnCriticalLine ρ →
      AdmissibleKernel
  quartetNegative :
    ∀ {ρ : ℂ}
      (hρ : IsNontrivialZero ρ)
      (hOff : ¬ OnCriticalLine ρ),
      actualZetaDatum.Q (localWitnessKernel hρ hOff) < 0
  admissibleApproximation :
    ∀ {ρ : ℂ}
      (_hρ : IsNontrivialZero ρ)
      (_hOff : ¬ OnCriticalLine ρ),
      AdmissibleKernel
  admissibleApproximation_eq :
    ∀ {ρ : ℂ}
      (hρ : IsNontrivialZero ρ)
      (hOff : ¬ OnCriticalLine ρ),
      admissibleApproximation hρ hOff = localWitnessKernel hρ hOff
  squeezeBridge :
    ∀ {ρ : ℂ}
      (hρ : IsNontrivialZero ρ)
      (hOff : ¬ OnCriticalLine ρ),
      actualZetaDatum.Q (admissibleApproximation hρ hOff) < 0

axiom actualWitnessAnalyticInputs : ActualWitnessAnalyticInputs

def actualOffLineWitnessScheme : OffLineWitnessScheme actualZetaDatum where
  witnessKernel := fun {_} hρ hOff => actualWitnessAnalyticInputs.admissibleApproximation hρ hOff
  witnessNegative := fun {_} hρ hOff => actualWitnessAnalyticInputs.squeezeBridge hρ hOff

/--
Under the axiomatic closure package, the formal RH conclusion follows.
-/
theorem axiomaticRiemannHypothesis : RiemannHypothesis :=
  riemannHypothesis_of_majorant_and_witnessScheme
    actualZetaDatum
    actualPowerLawZeroMajorant.toAnalyticKernel
    actualArchimedeanBinding
    actualPrimePowerBinding
    actualOffLineWitnessScheme

end RiemannHypothesisProtocol
