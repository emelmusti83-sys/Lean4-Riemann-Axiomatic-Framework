# Riemann Hypothesis Research Project — Process & Archive

This document collects the **end-to-end process**, outputs, and **clear mathematical boundaries** of the work in the `riemman` workspace. For detailed technical reports, see the index at the end of this file.

**Contact:** [mustafa@snowgamestr.com](mailto:mustafa@snowgamestr.com)

---

## 1. Goal and outcome (honest summary)

**Goal:** Prove or refute the Riemann Hypothesis (RH); formalize the effort in Lean 4 / Isabelle; support it with the Guinand–Weil explicit formula and numerical experiments.

**What was achieved:**

- There is **no full mathlib-based proof of RH.** Remaining analytic gaps were closed in `AnalyticCrux/Axioms.lean` as **explicit axiom packages**—what we call **axiomatic closure** internally.
- **Machine verification:** The Lean 4 project (`lake build`) **compiles cleanly** under this architecture; missing links in the proof chain are labeled as axioms.
- **Numerics:** Finite truncation models and admissible kernel families were searched for a **negative witness (Q &lt; 0)**; under the reported conditions none was found. This is **not** evidence that RH is true—only that **no contradiction was produced** in the tested model and kernel class.

**What we do *not* claim:** “RIEMANN HYPOTHESIS: VERIFIED” or a Clay-level global proof. `GRAND_UNIFICATION.md` states explicitly that we did **not** move to `FORMALLY CONFIRMED` status.

---

## 2. Process phases (chronological)

### Phase 0 — Research protocol and framing

- `RiemannHypothesisResearchProtocol.md`: scope, methodology, output format including RSA/cryptography.
- `ResearchCycle24h.md`: hourly progress log template.
- An initial “SpectralPositivityBridge”-style bridge was considered; analysis showed that assuming **positivity for every test function** is too strong and does not map cleanly to RH, so the approach was narrowed to a **positive cone and admissible kernels**.

### Phase 1 — Lean 4 spine and mathlib link

- Toolchain: `elan` / `lake`, `mathlib` (e.g. tag aligned with `v4.29.0-rc8`), `lakefile.lean`, `lean-toolchain`.
- `Riemman.RiemannHypothesisProtocol`: RH definition, `xi` and completed zeta, internal `ProtocolStatus` (exploratory → … → `axiomaticallyClosed`).
- `Riemman.MathlibBridge`: **proved** links such as `xi` symmetry and differentiability from `completedRiemannZeta` in mathlib.
- `formal/Isabelle/Riemann_Hypothesis_Protocol.thy`: parallel Isabelle skeleton (outline level).

### Phase 2 — Guinand–Weil bridge and concrete truncation

- `GuinandWeilBridge.lean`: `AdmissibleKernel`, `GuinandWeilDatum`, `Q`, `PositivityConeExpansion`, `ExplicitFormulaBinding`, analytic/majorant structures for the zero side (`ZeroSideAnalyticKernel`, `PowerLawZeroMajorant`), `OffLineWitnessScheme` for off-line zeros, epsilon compression (`eventually_nonneg_of_tendsto_positive_limit`), etc.
- `ConcreteTruncationModel.lean`: a **finite** model for `Q` as concrete sums over zero nodes, Archimedean nodes, and prime-power terms; sign/normalization (e.g. Fourier `/(2 * π)`) aligned carefully.

### Phase 3 — Numerical verification and “hunt”

- `numerics/q_hunt.py`: high precision with `mpmath`, `numpy`, `scipy`, adaptive prime/zero truncation, Archimedean integration via `scipy.integrate.quad`.
- Initial datasets: e.g. first N primes / first M zeta zeros, mirroring the finite truncation idea numerically.
- A **fictitious off-line zero (quartet)** was added and `Q_hypothesis` scanned for a possible **negative witness**.
- Outputs: `NumericalVerification.md`, `numerics/latest_results.json`.

### Phase 4 — Calibration and deep hunt

- Adaptive prime-power grid: extend until term weight falls below a chosen tolerance.
- Finer Archimedean integration; Gaussian-mixture calibration to push `Q_actual` to very small positive values.
- Filtering **spurious negatives** from truncation imbalance.
- Report: `DeepHuntReport.md`.
- Epsilon range restricted (e.g. `0 < ε < 0.5`) so hypothetical zeros stay in a **physically meaningful** part of the critical strip.

### Phase 5 — Performance and aggressive kernel families

- Low CPU usage addressed with `ProcessPoolExecutor`, in-memory batching, `numpy` vectorization, `lru_cache`, on-disk zeta zero pool (`numerics/zero_pool_400.json`), `cProfile` (`numerics/profile_summary.json`).
- `SharpKernelFamilies.lean`: `positiveBlend`, sharp hybrid / Poisson-like / Fejér-like templates aimed at admissibility in Lean.
- Summaries: `PerformanceOptimization.md`, `Lean4FormalizationSprint.md`, `TheoreticalPositivityReport.md`.

### Phase 6 — Splitting analytic “crux” modules

- `AnalyticCrux/{ZeroCounting,ZeroSideMajorant,Bindings,Witness,Final}.lean`: **file-level ownership** of the majorant + witness + binding chain and conditional RH corollaries (e.g. `riemannHypothesis_of_powerLawMajorant_and_existentialWitness`).
- Root module `Riemman.lean` imports all layers in order.

### Phase 7 — Axiomatic closure (“zero debt” in project-internal terms)

- **Atomic structures** instead of single large axioms:
  - `actualZetaDatum`
  - `ActualArchimedeanAnalyticInputs` → `actualArchimedeanBinding`
  - `ActualPrimePowerAnalyticInputs` → `actualPrimePowerBinding`
  - `ActualZeroSideAnalyticInputs` → `actualPowerLawZeroMajorant`
  - `ActualWitnessAnalyticInputs` → off-line witness scheme
- `remainingOpenObligations` emptied; `protocolStatus` set to `axiomaticallyClosed`.
- Unified status and warnings: `GRAND_UNIFICATION.md`.

---

## 3. Repository map (path and role)

| Path | Role |
|------|------|
| `lakefile.lean`, `lean-toolchain` | Lean 4 project and toolchain |
| `formal/Lean4/Riemman.lean` | Main import tree |
| `formal/Lean4/Riemman/RiemannHypothesisProtocol.lean` | RH, protocol status, obligation list |
| `formal/Lean4/Riemman/MathlibBridge.lean` | mathlib ↔ project `xi` bridge |
| `formal/Lean4/Riemman/GuinandWeilBridge.lean` | Explicit formula interface and main theorem scaffold |
| `formal/Lean4/Riemman/ConcreteTruncationModel.lean` | Finite `Q` model and binding templates |
| `formal/Lean4/Riemman/SharpKernelFamilies.lean` | Sharp kernel families |
| `formal/Lean4/Riemman/AnalyticCrux/*.lean` | Counting, majorant, witness, final chain, axioms |
| `numerics/q_hunt.py` | Numerical hunt and calibration engine |
| `numerics/*.json` | Results, profiling, zero-pool cache |
| `formal/Isabelle/*` | Parallel Isabelle skeleton |
| `RiemannHypothesisResearchProtocol.md` | Initial protocol |
| `GRAND_UNIFICATION.md` | Single-page unified status |
| `TheoreticalPositivityReport.md` | Executive summary & theory pointer |
| `DeepHuntReport.md`, `NumericalVerification.md` | Numerical phase reports |
| `PerformanceOptimization.md` | CPU / parallelism notes |
| `README.md` | Main entry; details also in this file and `GRAND_UNIFICATION.md` |

---

## 4. Logical skeleton (short)

1. **Admissible kernel** `g`: Schwartz, even, real, Fourier side pointwise nonnegative.
2. **Guinand–Weil datum:** `Q(g)` combines zero, Archimedean, and prime-power contributions.
3. **Lower-bound architecture:** lower forms and binding inequalities aim for global `Q(g) ≥ 0`.
4. **Off-line zero:** a **witness scheme** posits `Q(g) < 0` under contradiction (each step is either a theorem or an axiom).
5. **Axiomatic closure:** analytic steps not yet in mathlib are assumed in small packages in `Axioms.lean` so the build completes without stray `sorry`s.

---

## 5. How to run (summary)

- **Lean:** From repo root, `lake build` (requires `elan` and the pinned toolchain).
- **Numerical hunt:** Run `q_hunt.py` under `numerics` in a Python environment with `mpmath`, `numpy`, `scipy`, etc.

---

## 6. Cybersecurity note (summary)

Proving or disproving RH does **not** mean RSA “breaks instantly”; most systems rely on **concrete bit security** and **large primes / key sizes**. The protocol document discusses speculative scenarios at the **probability and design** level; standard cryptographic practice is unchanged.

---

## 7. Meaningful next steps (optional)

- **Melt** one package in `Axioms.lean` into theorems using mathlib or external analysis.
- Numerics: other kernel classes or larger truncations (higher cost).
- Fill Isabelle theories aligned with Lean statements.

---

*Document date: 2026-03-28 (archive alignment with repository state).*
