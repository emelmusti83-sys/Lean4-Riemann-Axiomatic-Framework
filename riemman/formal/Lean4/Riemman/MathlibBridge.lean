/-
Copyright (c) 2026 Mustafa (isnowx). SPDX-License-Identifier: MIT
Contact: mustafa@snowgamestr.com
-/
import Mathlib
import Riemman.RiemannHypothesisProtocol

noncomputable section

open Complex

namespace RiemannHypothesisProtocol

theorem completedRiemannZeta_symm (s : ℂ) :
    completedRiemannZeta (1 - s) = completedRiemannZeta s :=
  completedRiemannZeta_one_sub s

theorem completedRiemannZeta₀_symm (s : ℂ) :
    completedRiemannZeta₀ (1 - s) = completedRiemannZeta₀ s :=
  completedRiemannZeta₀_one_sub s

theorem xi_one_sub (s : ℂ) : xi (1 - s) = xi s := by
  rw [xi, completedRiemannZeta_one_sub, xi]
  ring

theorem differentiableAt_xi {s : ℂ} (hs0 : s ≠ 0) (hs1 : s ≠ 1) :
    DifferentiableAt ℂ xi s := by
  have hId : DifferentiableAt ℂ (fun z : ℂ => z) s := by
    fun_prop
  have hShift : DifferentiableAt ℂ (fun z : ℂ => z - 1) s := by
    fun_prop
  have hCompleted : DifferentiableAt ℂ completedRiemannZeta s :=
    differentiableAt_completedZeta hs0 hs1
  change DifferentiableAt ℂ
    (fun y : ℂ => ((1 : ℂ) / 2) * (y * ((y - 1) * completedRiemannZeta y))) s
  simpa using (hId.mul (hShift.mul hCompleted)).const_mul ((1 : ℂ) / 2)

theorem xi_zero : xi 0 = 0 := by
  simp [xi]

theorem xi_one : xi 1 = 0 := by
  simp [xi]

end RiemannHypothesisProtocol
