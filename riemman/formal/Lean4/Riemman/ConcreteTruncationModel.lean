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
A finite zero-side contribution sampled on Fourier-normalized critical-line ordinates.

In the `mathlib` Fourier normalization, the intended input is typically `γ / (2 * π)`.
-/
structure ZeroTruncationTerm where
  ordinate : ℝ
  multiplicity : ℝ
  multiplicity_nonneg : 0 ≤ multiplicity

def ZeroTruncationTerm.eval (term : ZeroTruncationTerm) (g : AdmissibleKernel) : ℝ :=
  term.multiplicity * g.criticalLineProfile term.ordinate

theorem ZeroTruncationTerm.eval_nonneg (term : ZeroTruncationTerm) (g : AdmissibleKernel) :
    0 ≤ term.eval g := by
  unfold ZeroTruncationTerm.eval
  exact mul_nonneg term.multiplicity_nonneg (g.criticalLineProfile_nonneg term.ordinate)

def ZeroTruncationTerm.toFourierProfileSample (term : ZeroTruncationTerm) : FourierProfileSample where
  point := term.ordinate
  weight := term.multiplicity
  weight_nonneg := term.multiplicity_nonneg

/--
A finite quadrature node for the archimedean side of a Guinand-Weil formula.

The sign convention is encoded in `weight`. No positivity is assumed here by default.
-/
structure ArchimedeanNode where
  sample : ℝ
  weight : ℝ

def ArchimedeanNode.eval (node : ArchimedeanNode) (g : AdmissibleKernel) : ℝ :=
  node.weight * g.criticalLineProfile node.sample

theorem ArchimedeanNode.eval_nonneg
    (node : ArchimedeanNode) (g : AdmissibleKernel) (hWeight : 0 ≤ node.weight) :
    0 ≤ node.eval g := by
  unfold ArchimedeanNode.eval
  exact mul_nonneg hWeight (g.criticalLineProfile_nonneg node.sample)

def ArchimedeanNode.toFourierProfileSample
    (node : ArchimedeanNode) (hWeight : 0 ≤ node.weight) : FourierProfileSample where
  point := node.sample
  weight := node.weight
  weight_nonneg := hWeight

/--
A finite prime-power term.

The intended normalizing factor is `log p / sqrt (p^m)`, while `coefficient` is left free
so that sign conventions and truncation-specific normalizations are explicit in the data.
-/
structure PrimePowerTerm where
  prime : ℕ
  power : ℕ
  hPrime : Nat.Prime prime
  power_pos : 0 < power
  coefficient : ℝ

def PrimePowerTerm.samplePoint (term : PrimePowerTerm) : ℝ :=
  Real.log (((term.prime : ℝ) ^ term.power)) / (2 * Real.pi)

def PrimePowerTerm.baseWeight (term : PrimePowerTerm) : ℝ :=
  Real.log (term.prime : ℝ) / Real.sqrt (((term.prime : ℝ) ^ term.power))

def PrimePowerTerm.signedWeight (term : PrimePowerTerm) : ℝ :=
  term.coefficient * term.baseWeight

/--
The symmetric kernel value appearing on the prime-power side.

Because admissible kernels are even, this is twice the real part at `log (p^m)`, but we keep
the symmetric form explicit to make sign conventions harder to get wrong.
-/
def PrimePowerTerm.kernelValue (term : PrimePowerTerm) (g : AdmissibleKernel) : ℝ :=
  (g term.samplePoint).re + (g (-term.samplePoint)).re

theorem PrimePowerTerm.kernelValue_nonneg
    (term : PrimePowerTerm) (g : AdmissibleKernel) :
    0 ≤ term.kernelValue g := by
  unfold PrimePowerTerm.kernelValue
  linarith [g.nonneg term.samplePoint, g.nonneg (-term.samplePoint)]

theorem PrimePowerTerm.kernelValue_eq_two_mul
    (term : PrimePowerTerm) (g : AdmissibleKernel) :
    term.kernelValue g = 2 * (g term.samplePoint).re := by
  have hRe :
      (g (-term.samplePoint)).re = (g term.samplePoint).re := by
    simpa using congrArg Complex.re (g.even term.samplePoint)
  unfold PrimePowerTerm.kernelValue
  linarith

def PrimePowerTerm.eval (term : PrimePowerTerm) (g : AdmissibleKernel) : ℝ :=
  term.signedWeight * term.kernelValue g

theorem PrimePowerTerm.eval_nonneg
    (term : PrimePowerTerm) (g : AdmissibleKernel) (hWeight : 0 ≤ term.signedWeight) :
    0 ≤ term.eval g := by
  unfold PrimePowerTerm.eval
  exact mul_nonneg hWeight (term.kernelValue_nonneg g)

def PrimePowerTerm.toKernelLowerForm
    (term : PrimePowerTerm) (hWeight : 0 ≤ term.signedWeight) : KernelLowerForm :=
  [ { point := term.samplePoint, weight := term.signedWeight, weight_nonneg := hWeight }
  , { point := -term.samplePoint, weight := term.signedWeight, weight_nonneg := hWeight }
  ]

theorem PrimePowerTerm.toKernelLowerForm_eval_eq
    (term : PrimePowerTerm) (hWeight : 0 ≤ term.signedWeight) (g : AdmissibleKernel) :
    (term.toKernelLowerForm hWeight).eval g = term.eval g := by
  unfold PrimePowerTerm.toKernelLowerForm KernelLowerForm.eval PrimePowerTerm.eval PrimePowerTerm.kernelValue
  simp [KernelValueSample.eval, add_comm, mul_add]

/--
A concrete finite truncation model for the Guinand-Weil explicit formula.

This is the first genuinely concrete `Q`: every side is now a finite sum rather than an
abstract callback.
-/
structure FiniteTruncationModel where
  zeroTerms : List ZeroTruncationTerm
  archimedeanNodes : List ArchimedeanNode
  primePowerTerms : List PrimePowerTerm

def FiniteTruncationModel.zeroSide (model : FiniteTruncationModel) (g : AdmissibleKernel) : ℝ :=
  (model.zeroTerms.map fun term => term.eval g).sum

def FiniteTruncationModel.archimedeanSide
    (model : FiniteTruncationModel) (g : AdmissibleKernel) : ℝ :=
  (model.archimedeanNodes.map fun node => node.eval g).sum

def FiniteTruncationModel.primePowerSide
    (model : FiniteTruncationModel) (g : AdmissibleKernel) : ℝ :=
  (model.primePowerTerms.map fun term => term.eval g).sum

def FiniteTruncationModel.Q (model : FiniteTruncationModel) (g : AdmissibleKernel) : ℝ :=
  model.zeroSide g + model.archimedeanSide g + model.primePowerSide g

def FiniteTruncationModel.toDatum (model : FiniteTruncationModel) : GuinandWeilDatum where
  zeroSide := model.zeroSide
  archimedeanSide := model.archimedeanSide
  primePowerSide := model.primePowerSide

theorem FiniteTruncationModel.Q_eq_toDatum_Q
    (model : FiniteTruncationModel) (g : AdmissibleKernel) :
    model.Q g = model.toDatum.Q g := by
  rfl

def FiniteTruncationModel.zeroLowerCandidate (model : FiniteTruncationModel) : ZeroSideLowerCandidate where
  lowerForm := model.zeroTerms.map ZeroTruncationTerm.toFourierProfileSample

theorem FiniteTruncationModel.zeroLowerCandidate_eval_eq
    (model : FiniteTruncationModel) (g : AdmissibleKernel) :
    model.zeroLowerCandidate.eval g = model.zeroSide g := by
  unfold FiniteTruncationModel.zeroLowerCandidate ZeroSideLowerCandidate.eval
  unfold FiniteTruncationModel.zeroSide FourierLowerForm.eval
  induction model.zeroTerms with
  | nil =>
      simp
  | cons term terms ih =>
      simpa [ZeroTruncationTerm.toFourierProfileSample, ZeroTruncationTerm.eval, FourierProfileSample.eval]
        using congrArg (fun t : ℝ => term.eval g + t) ih

def FiniteTruncationModel.zeroSideBinding (model : FiniteTruncationModel) :
    ZeroSideBinding model.toDatum where
  candidate := model.zeroLowerCandidate
  lowerBound := by
    intro g
    rw [model.zeroLowerCandidate_eval_eq]
    exact le_rfl

theorem FiniteTruncationModel.zeroSide_nonneg
    (model : FiniteTruncationModel) (g : AdmissibleKernel) :
    0 ≤ model.zeroSide g := by
  unfold FiniteTruncationModel.zeroSide
  induction model.zeroTerms with
  | nil =>
      simp
  | cons term terms ih =>
      simpa [List.map, ZeroTruncationTerm.eval] using add_nonneg (term.eval_nonneg g) ih

theorem archimedeanNodes_sum_nonneg
    (nodes : List ArchimedeanNode)
    (g : AdmissibleKernel)
    (hWeight : ∀ node ∈ nodes, 0 ≤ node.weight) :
    0 ≤ (nodes.map fun node => node.eval g).sum := by
  induction nodes with
  | nil =>
      simp
  | cons node nodes ih =>
      have hNode : 0 ≤ node.weight := hWeight node (by simp)
      have hTail : ∀ n ∈ nodes, 0 ≤ n.weight := by
        intro n hn
        exact hWeight n (List.mem_cons_of_mem _ hn)
      simpa [List.map, ArchimedeanNode.eval] using
        add_nonneg (node.eval_nonneg g hNode) (ih hTail)

theorem FiniteTruncationModel.archimedeanSide_nonneg
    (model : FiniteTruncationModel)
    (g : AdmissibleKernel)
    (hWeight : ∀ node ∈ model.archimedeanNodes, 0 ≤ node.weight) :
    0 ≤ model.archimedeanSide g := by
  unfold FiniteTruncationModel.archimedeanSide
  exact archimedeanNodes_sum_nonneg model.archimedeanNodes g hWeight

def archimedeanLowerForm :
    (nodes : List ArchimedeanNode) →
    (hWeight : ∀ node ∈ nodes, 0 ≤ node.weight) →
    FourierLowerForm
  | [], _ => []
  | node :: nodes, hWeight =>
      node.toFourierProfileSample (hWeight node (by simp)) ::
        archimedeanLowerForm nodes (fun n hn => hWeight n (by simp [hn]))

theorem archimedeanLowerForm_eval_eq
    (nodes : List ArchimedeanNode)
    (g : AdmissibleKernel)
    (hWeight : ∀ node ∈ nodes, 0 ≤ node.weight) :
    (archimedeanLowerForm nodes hWeight).eval g = (nodes.map fun node => node.eval g).sum := by
  revert hWeight
  induction nodes with
  | nil =>
      intro hWeight
      simp [archimedeanLowerForm, FourierLowerForm.eval]
  | cons node nodes ih =>
      intro hWeight
      let hTail : ∀ n ∈ nodes, 0 ≤ n.weight := fun n hn => hWeight n (List.mem_cons_of_mem _ hn)
      calc
        (archimedeanLowerForm (node :: nodes) hWeight).eval g
            = node.eval g + (archimedeanLowerForm nodes hTail).eval g := by
                simp [archimedeanLowerForm, FourierLowerForm.eval, ArchimedeanNode.toFourierProfileSample,
                  ArchimedeanNode.eval, FourierProfileSample.eval]
        _ = node.eval g + (nodes.map fun node => node.eval g).sum := by
              rw [ih hTail]
        _ = ((node :: nodes).map fun node => node.eval g).sum := by
              simp

def FiniteTruncationModel.archimedeanBinding
    (model : FiniteTruncationModel)
    (hWeight : ∀ node ∈ model.archimedeanNodes, 0 ≤ node.weight) :
    ArchimedeanBinding model.toDatum where
  lowerForm := archimedeanLowerForm model.archimedeanNodes hWeight
  lowerBound := by
    intro g
    change (archimedeanLowerForm model.archimedeanNodes hWeight).eval g ≤ model.archimedeanSide g
    rw [archimedeanLowerForm_eval_eq model.archimedeanNodes g hWeight]
    exact le_rfl

theorem primePowerTerms_sum_nonneg
    (terms : List PrimePowerTerm)
    (g : AdmissibleKernel)
    (hWeight : ∀ term ∈ terms, 0 ≤ term.signedWeight) :
    0 ≤ (terms.map fun term => term.eval g).sum := by
  induction terms with
  | nil =>
      simp
  | cons term terms ih =>
      have hTerm : 0 ≤ term.signedWeight := hWeight term (by simp)
      have hTail : ∀ t ∈ terms, 0 ≤ t.signedWeight := by
        intro t ht
        exact hWeight t (List.mem_cons_of_mem _ ht)
      simpa [List.map, PrimePowerTerm.eval] using
        add_nonneg (term.eval_nonneg g hTerm) (ih hTail)

theorem FiniteTruncationModel.primePowerSide_nonneg
    (model : FiniteTruncationModel)
    (g : AdmissibleKernel)
    (hWeight : ∀ term ∈ model.primePowerTerms, 0 ≤ term.signedWeight) :
    0 ≤ model.primePowerSide g := by
  unfold FiniteTruncationModel.primePowerSide
  exact primePowerTerms_sum_nonneg model.primePowerTerms g hWeight

def primePowerLowerForm :
    (terms : List PrimePowerTerm) →
    (hWeight : ∀ term ∈ terms, 0 ≤ term.signedWeight) →
    KernelLowerForm
  | [], _ => []
  | term :: terms, hWeight =>
      term.toKernelLowerForm (hWeight term (by simp)) ++
        primePowerLowerForm terms (fun t ht => hWeight t (by simp [ht]))

theorem primePowerLowerForm_eval_eq
    (terms : List PrimePowerTerm)
    (g : AdmissibleKernel)
    (hWeight : ∀ term ∈ terms, 0 ≤ term.signedWeight) :
    (primePowerLowerForm terms hWeight).eval g = (terms.map fun term => term.eval g).sum := by
  revert hWeight
  induction terms with
  | nil =>
      intro hWeight
      simp [primePowerLowerForm, KernelLowerForm.eval]
  | cons term terms ih =>
      intro hWeight
      let hTail : ∀ t ∈ terms, 0 ≤ t.signedWeight := fun t ht => hWeight t (List.mem_cons_of_mem _ ht)
      calc
        (primePowerLowerForm (term :: terms) hWeight).eval g
            = (term.toKernelLowerForm (hWeight term (by simp))).eval g
                + (primePowerLowerForm terms hTail).eval g := by
                  simp [primePowerLowerForm, KernelLowerForm.eval]
        _ = term.eval g + (primePowerLowerForm terms hTail).eval g := by
              rw [PrimePowerTerm.toKernelLowerForm_eval_eq]
        _ = term.eval g + (terms.map fun term => term.eval g).sum := by
              rw [ih hTail]
        _ = ((term :: terms).map fun term => term.eval g).sum := by
              simp

def FiniteTruncationModel.primePowerBinding
    (model : FiniteTruncationModel)
    (hWeight : ∀ term ∈ model.primePowerTerms, 0 ≤ term.signedWeight) :
    PrimePowerBinding model.toDatum where
  lowerForm := primePowerLowerForm model.primePowerTerms hWeight
  lowerBound := by
    intro g
    change (primePowerLowerForm model.primePowerTerms hWeight).eval g ≤ model.primePowerSide g
    rw [primePowerLowerForm_eval_eq model.primePowerTerms g hWeight]
    exact le_rfl

def FiniteTruncationModel.explicitFormulaBinding
    (model : FiniteTruncationModel)
    (hArch : ∀ node ∈ model.archimedeanNodes, 0 ≤ node.weight)
    (hPrime : ∀ term ∈ model.primePowerTerms, 0 ≤ term.signedWeight) :
    ExplicitFormulaBinding where
  datum := model.toDatum
  zeroSideBinding := model.zeroSideBinding
  archimedeanBinding := model.archimedeanBinding hArch
  primePowerBinding := model.primePowerBinding hPrime

theorem FiniteTruncationModel.explicitFormulaBinding_Q_nonneg
    (model : FiniteTruncationModel)
    (g : AdmissibleKernel)
    (hArch : ∀ node ∈ model.archimedeanNodes, 0 ≤ node.weight)
    (hPrime : ∀ term ∈ model.primePowerTerms, 0 ≤ term.signedWeight) :
    0 ≤ model.toDatum.Q g :=
  (model.explicitFormulaBinding hArch hPrime).Q_nonneg g

/--
Safe sufficient condition for the truncated model to satisfy the positive-cone requirement.

This theorem is intentionally one-way only: it prevents us from accidentally claiming a
positive cone when the archimedean or prime-power sign conventions have drifted.
-/
theorem FiniteTruncationModel.Q_nonneg_of_signConvention
    (model : FiniteTruncationModel)
    (g : AdmissibleKernel)
    (hArch : ∀ node ∈ model.archimedeanNodes, 0 ≤ node.weight)
    (hPrime : ∀ term ∈ model.primePowerTerms, 0 ≤ term.signedWeight) :
    0 ≤ model.Q g := by
  unfold FiniteTruncationModel.Q
  refine add_nonneg ?_ (model.primePowerSide_nonneg g hPrime)
  exact add_nonneg (model.zeroSide_nonneg g) (model.archimedeanSide_nonneg g hArch)

end RiemannHypothesisProtocol
