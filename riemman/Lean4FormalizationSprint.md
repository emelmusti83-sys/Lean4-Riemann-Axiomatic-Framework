# Lean 4 Formalization Sprint

This note summarizes the first mathlib-based compilable RH sprint.

**Contact:** [mustafa@snowgamestr.com](mailto:mustafa@snowgamestr.com)

## Machine-verified parts

These Lean modules built successfully with `lake build`:

- `formal/Lean4/Riemman/RiemannHypothesisProtocol.lean`  
- `formal/Lean4/Riemman/MathlibBridge.lean`  
- `formal/Lean4/Riemman/GuinandWeilBridge.lean`  
- `formal/Lean4/Riemman/ConcreteTruncationModel.lean`  
- `formal/Lean4/Riemman.lean`  

Local run used Lean `4.29.0-rc8` and mathlib `v4.29.0-rc8`.

Correct theorem hooks:

- `completedRiemannZeta_one_sub`  
- `completedRiemannZeta₀_one_sub`  
- `differentiableAt_completedZeta`  

Machine-checked lemmas include:

- `RiemannHypothesisProtocol.xi_functional_equation`  
- `RiemannHypothesisProtocol.completedRiemannZeta_symm`  
- `RiemannHypothesisProtocol.completedRiemannZeta₀_symm`  
- `RiemannHypothesisProtocol.xi_one_sub`  
- `RiemannHypothesisProtocol.differentiableAt_xi`  
- `RiemannHypothesisProtocol.xi_zero`  
- `RiemannHypothesisProtocol.xi_one`  
- `RiemannHypothesisProtocol.positivityConeBridgeImpliesRH`  
- `RiemannHypothesisProtocol.AdmissibleKernel.integrable`  
- `RiemannHypothesisProtocol.AdmissibleKernel.integrable_fourier`  
- `RiemannHypothesisProtocol.AdmissibleKernel.criticalLineProfile_nonneg`  
- `RiemannHypothesisProtocol.riemannHypothesis_of_guinandWeilPackage`  
- `RiemannHypothesisProtocol.FiniteTruncationModel.Q_eq_toDatum_Q`  
- `RiemannHypothesisProtocol.FiniteTruncationModel.zeroSide_nonneg`  
- `RiemannHypothesisProtocol.FiniteTruncationModel.archimedeanSide_nonneg`  
- `RiemannHypothesisProtocol.FiniteTruncationModel.primePowerSide_nonneg`  
- `RiemannHypothesisProtocol.FiniteTruncationModel.Q_nonneg_of_signConvention`  

## SpectralPositivityBridge audit

Main finding:

- The first abstract core was **wrong**.

Why?

- The draft assumed a quantity like `Q(g) = ⟨g(H)v, v⟩` would be automatically `≥ 0` for **every** test function `g`.  
- That is false in general.  
- For a self-adjoint operator, nonnegativity follows automatically only when `g` is **pointwise nonnegative on the spectrum**.

So the first bridge failed to reach RH because:

- Positivity can be expected only on a **positive cone** of tests, not universally.

Lean fix:

- Introduced `PositiveTestKernel` (pointwise nonnegative kernels).  
- Abstract lemma stated **only** on that cone: `positivityConeBridgeImpliesRH`.

This matters mathematically and formally:

- Avoids a hidden sign mistake.  
- Forces negativity witness search into the **same** admissible class.

## Pivot toward negativity witnesses

No real counterexample / negativity witness was produced in Lean or analysis yet.

But the sprint clarified **where** to search:

- Not among arbitrary signed tests, but among tests **compatible with the explicit formula** and the **spectral positivity cone**.

That is a narrower but more correct search space than “try random kernels.”

## Guinand–Weil layer

New Lean layer:

- `AdmissibleKernel`: Schwartz on `ℝ`, even, real-valued, pointwise nonnegative, Fourier transform pointwise nonnegative—via mathlib `SchwartzMap` and Fourier.  
- `GuinandWeilDatum`: packages zero, archimedean, and prime-power sides.  
- `GuinandWeilDatum.Q`: candidate quadratic form combining the three.  
- `GuinandWeilPackage`: abstract package—if concrete datum yields both positivity and off-line witness, RH follows.

Value:

- Moved past “we will define Q someday.”  
- Fixed the interface for Guinand–Weil language in Lean.  
- Machine-pinned **what object** witness search targets.

## Concrete truncation stage

Second major step:

- `ZeroTruncationTerm`: finite zero-side term from Fourier profile.  
- `PrimePowerTerm`: finite prime-power term with sample `log(p^m)` and weight based on `log p / sqrt(p^m)`.  
- `FiniteTruncationModel`: combines zero side, archimedean quadrature, prime-power side.  
- `FiniteTruncationModel.Q`: **concrete** finite sum, not a placeholder interface.

Critical safety theorem:

- `FiniteTruncationModel.Q_nonneg_of_signConvention`

It forces:

- The positive cone exists only if archimedean and prime-power **weights** have the right signs—sign convention is an explicit Lean hypothesis, not a verbal slip.

## Next technical steps

1. Pick real numeric or symbolic truncation data for `FiniteTruncationModel`.  
2. Align `archimedeanNodes.weight` with gamma-factor sign from the explicit formula.  
3. Fix the correct sign convention for `PrimePowerTerm.coefficient`.  
4. Test whether an off-line quadruple in this concrete model produces a negative witness.  
5. If this step stalls, the part of the bridge that **fails to imply RH** is isolated.

## Outcome

This sprint did **not** “prove RH.”

It did something more durable:

- Found which abstract bridge version was **wrong**.  
- Replaced it with a machine-checked core lemma on the **correct** cone.  
- Linked mathlib’s `completedRiemannZeta` theorems to an `xi`-based formal spine.
