# Riemann Hypothesis Research Stack (`riemman`)

**Principal / lead author:** Mustafa ([@isnowx](https://github.com/isnowx)) · **Contact:** [mustafa@snowgamestr.com](mailto:mustafa@snowgamestr.com) · **License:** [MIT](LICENSE)

A research workspace that combines **Lean 4 formalization** (with [mathlib4](https://github.com/leanprover-community/mathlib4)), a **Guinand–Weil / explicit-formula–style interface**, and a **Python numerical engine** to explore conditional proof architectures and empirical “witness hunting” around the Riemann Hypothesis (RH).

This repository is a **structured experiment in formal methods and numerics**, not a claim that RH has been proved or disproved.

**Investor / executive overview:** see [`TheoreticalPositivityReport.md`](TheoreticalPositivityReport.md) (executive summary and technical appendix).

---

## Table of contents

1. [Claims and non-claims](#claims-and-non-claims)
2. [What is actually in the box](#what-is-actually-in-the-box)
3. [Mathematical story (high level)](#mathematical-story-high-level)
4. [Repository layout](#repository-layout)
5. [Lean 4: build and architecture](#lean-4-build-and-architecture)
6. [Numerics: Python hunt pipeline](#numerics-python-hunt-pipeline)
7. [Documentation map](#documentation-map)
8. [Project phases (chronology)](#project-phases-chronology)
9. [Cryptography note](#cryptography-note)
10. [Related reading](#related-reading)

---

## Claims and non-claims

**What this project does provide**

- A **compiling** Lean 4 library that wires RH statements to a Guinand–Weil–flavored datum, finite truncation models, positivity/lower-bound scaffolding, and optional contradiction routes via hypothetical off-line zeros.
- **Machine-checked proofs** for everything that is not explicitly postulated: bridges from mathlib’s zeta API to the project’s `xi` packaging, combinatorial and order lemmas in the truncation model, and the conditional implication chains (“if these analytic inputs hold, then RH follows from the global picture you axiomatize”).
- A **numerical pipeline** (`numerics/q_hunt.py`) that evaluates finite-model analogues of `Q(g)` for admissible kernel families, including aggressive calibration, multiprocessing, vectorization, and caching.

**What this project does *not* provide**

- A **proof of RH from first principles in mathlib** (or in any other single, peer-reviewed manuscript bundled here).
- The final analytic theorems that would replace the explicit **axiom packages** in `formal/Lean4/Riemman/AnalyticCrux/Axioms.lean`. Those packages are deliberately labeled `axiom` and are the formalization’s way of saying: “this step is assumed, not derived here.”

Internal protocol status in Lean is **`axiomaticallyClosed`**: open engineering todos inside the formalization are cleared by making the remaining analytic gaps **explicit assumptions**, not by magically finishing century-old analysis inside this repo.

---

## What is actually in the box

| Layer | Role |
|--------|------|
| **Protocol & reports** | Markdown research protocol, hourly log template, grand unification summary, deep hunt and theory reports. |
| **Lean 4 + mathlib** | Definitions and lemmas: RH, `xi` bridge, Guinand–Weil datum, `Q`, admissible kernels, explicit-formula bindings, majorants, witness schemes, final conditional RH theorems, axiom packages. |
| **Isabelle skeleton** | A small parallel theory file as a placeholder for cross-prover experimentation. |
| **Python numerics** | High-precision evaluation, adaptive prime/zero truncation, Archimedean integration via SciPy, kernel families (Gaussian, mixtures, Poisson-like, Fejér-like templates), parallel hunts, JSON artifacts. |

---

## Mathematical story (high level)

1. **Riemann Hypothesis (project formulation)**  
   Nontrivial zeros of the completed zeta / `xi` packaging lie on the critical line. The Lean side defines the hypothesis in a way that can connect to mathlib’s analytic setup.

2. **Admissible test functions**  
   A class of Schwartz, even, real-valued functions with **non-negative Fourier transforms** (and related regularity). This is the “positive cone” of test functions; it replaces an earlier, too-strong idea of positivity for arbitrary test functions.

3. **Guinand–Weil-style datum**  
   A structure packages contributions from zeros, archimedean (Gamma/archimedean) data, and prime-power (von Mangoldt-type) data into a single functional `Q(g)` (quadratic-form flavor in the formalization).

4. **Lower-bound / binding architecture**  
   If each side admits explicit **lower forms** dominated by the true side, one can aim for a global **`Q(g) ≥ 0`** statement for admissible `g`.

5. **Hypothetical off-line zero + witness scheme**  
   If a zero off the critical line existed, one posits a **witness scheme** producing some admissible `g` with **`Q(g) < 0`**, contradicting global non-negativity. The analytic content of such a scheme is enormous; in this repo, the hardest parts are **axiomatized** in small structured packages rather than proved.

6. **Finite truncation model**  
   `ConcreteTruncationModel.lean` instantiates a **finite-sum** analogue aligned with careful **sign and normalization** choices (including Fourier conventions such as division by `2π` where the model demands it). The Python code mirrors that philosophy for empirical exploration.

7. **Numerical hunting**  
   The script adds a **fictitious off-line quartet** and scans parameters. **No negative witness** was reported under the documented search regimes; that is **not** a mathematical theorem about RH—it is **evidence about the chosen discretization and kernel class**.

---

## Repository layout

```
riemman/
├── lakefile.lean                 # Lake project; mathlib pin
├── lean-toolchain                # Lean version (matches mathlib tag)
├── formal/
│   ├── Lean4/
│   │   ├── Riemman.lean          # Root imports
│   │   └── Riemman/
│   │       ├── RiemannHypothesisProtocol.lean
│   │       ├── MathlibBridge.lean
│   │       ├── GuinandWeilBridge.lean
│   │       ├── ConcreteTruncationModel.lean
│   │       ├── SharpKernelFamilies.lean
│   │       └── AnalyticCrux/
│   │           ├── ZeroCounting.lean
│   │           ├── ZeroSideMajorant.lean
│   │           ├── Bindings.lean
│   │           ├── Witness.lean
│   │           ├── Final.lean
│   │           └── Axioms.lean
│   └── Isabelle/
│       └── Riemann_Hypothesis_Protocol.thy
├── numerics/
│   ├── q_hunt.py
│   ├── latest_results.json       # generated by runs
│   ├── profile_summary.json      # optional cProfile output
│   └── zero_pool_400.json        # cached zeta zeros
├── GRAND_UNIFICATION.md
├── TheoreticalPositivityReport.md
├── DeepHuntReport.md
├── NumericalVerification.md
├── PerformanceOptimization.md
├── Lean4FormalizationSprint.md
├── RiemannHypothesisResearchProtocol.md
├── ProjectProcess.md
├── ResearchCycle24h.md
├── AUTHORS.md
├── LICENSE
└── README.md                              # this file
```

---

## Lean 4: build and architecture

### Prerequisites

- **[elan](https://github.com/leanprover/elan)** (recommended) or another way to install the Lean toolchain version pinned in `lean-toolchain`.
- Network access for the first `lake exe cache get` or mathlib fetch (depending on your workflow).

### Build

From the repository root:

```bash
lake build
```

The default library target is **`Riemman`**, with sources under `formal/Lean4/` (see `lakefile.lean`).

### Mathlib pin

`lakefile.lean` currently requires mathlib at tag **`v4.29.0-rc8`**, aligned with **`leanprover/lean4:v4.29.0-rc8`**.

### Module graph (conceptual)

1. `RiemannHypothesisProtocol` — RH definition, `xi` discussion, internal `ProtocolStatus`, obligation tracking.  
2. `MathlibBridge` — uses mathlib’s `completedRiemannZeta` API for symmetry/differentiability-style lemmas tied to the project’s `xi`.  
3. `GuinandWeilBridge` — core analytic interface: admissible kernels, datum, `Q`, positivity expansions, bindings, zero-side majorants, witness contradiction templates, epsilon compression lemma.  
4. `ConcreteTruncationModel` — finite sums mirroring the explicit formula at fixed truncation.  
5. `SharpKernelFamilies` — constructions for sharper admissible families (blends, hybrid templates).  
6. `AnalyticCrux/*` — splits the “hard analysis” chain into modules; `Axioms.lean` holds **explicit axiom structures** that close the gap between the conditional architecture and a vacuously consistent end theorem.

To see the exact import order, open `formal/Lean4/Riemman.lean`.

---

## Numerics: Python hunt pipeline

### Dependencies

Typical packages (install according to your environment):

```bash
pip install mpmath numpy scipy
```

### Running

From `numerics/` (or adjust paths as needed):

```bash
python q_hunt.py
```

The script can be CPU-intensive. It supports **multiprocessing**, **vectorized** kernel evaluation, **caching** of zeta zeros to disk, and optional **profiling** output. Generated JSON under `numerics/` summarizes runs and performance.

### Interpreting results

- **`Q_actual` near zero** after calibration indicates consistency of the **finite model + normalization** with a near-balanced explicit-formula residual for the chosen truncation—not a proof of RH.  
- **No `DISCOVERY.md`** in the documented runs means no **robust negative witness** was written out for the tested configurations.  
- Off-line distance parameters use **`0 < ε < 0.5`** so hypothetical zeros stay in the critical strip region the experiment is designed to discuss.

---

## Documentation map

| Document | Language | Purpose |
|----------|----------|---------|
| `README.md` | English | Long-form project overview (this file). |
| `GRAND_UNIFICATION.md` | English | Single-page status, key numbers, Lean module list, warnings about axiomatic closure. |
| `TheoreticalPositivityReport.md` | English | **Executive summary** for investors & partners; condensed technical appendix. |
| `DeepHuntReport.md` | English | Deep hunt methodology and truncation analysis. |
| `NumericalVerification.md` | English | Earlier numerical verification notes. |
| `PerformanceOptimization.md` | English | Parallelism, vectorization, profiling notes. |
| `Lean4FormalizationSprint.md` | English | Formalization sprint summary. |
| `RiemannHypothesisResearchProtocol.md` | English | Research protocol, proof program, cryptography discussion. |
| `ProjectProcess.md` | English | End-to-end process archive mirroring this README. |
| `ResearchCycle24h.md` | English | 24-hour hourly research log template. |
| `AUTHORS.md` | English | Attribution and contact. |

**Contact (all enquiries):** [mustafa@snowgamestr.com](mailto:mustafa@snowgamestr.com)

---

## Project phases (chronology)

1. **Research protocol** — scope, methodology, security reflection (`RiemannHypothesisResearchProtocol.md`).  
2. **Lean + mathlib spine** — RH/`xi` packaging, `MathlibBridge`, toolchain alignment.  
3. **Guinand–Weil layer** — admissible kernels, datum, `Q`, positivity and binding scaffolding.  
4. **Concrete truncation** — finite-sum model with careful conventions (`ConcreteTruncationModel.lean`).  
5. **Numerical verification & hunting** — `q_hunt.py`, JSON outputs, early reports.  
6. **Deep hunt & calibration** — adaptive primes/zeros, better Archimedean integration, aggressive kernels (`DeepHuntReport.md`).  
7. **Performance hardening** — multiprocessing, caches, vectorization (`PerformanceOptimization.md`).  
8. **Analytic crux split** — `AnalyticCrux` modules for counting, majorants, bindings, witness, final conditional theorems.  
9. **Axiomatic closure** — replace remaining `sorry`-style debt with **small explicit axiom packages** (`Axioms.lean`), clear internal obligations, honest status in `GRAND_UNIFICATION.md`.

---

## Cryptography note

RH is not the same as “RSA is broken tomorrow.” Even dramatic progress in analytic number theory would need to translate into **concrete algorithms** and **resource estimates** before impacting deployed systems. Most production cryptography relies on **concrete parameter choices** and **multiple assumptions**. Treat any speculative impact discussion (including in the research protocol document) as **thought experiment**, not operational guidance.

---

## Related reading

- [Lean 4 manual](https://lean-lang.org/doc/)  
- [mathlib4](https://github.com/leanprover-community/mathlib4)  
- Standard references on explicit formulas: Guinand, Weil, and modern treatments of the Riemann–von Mangoldt formula and explicit formulae in analytic number theory (consult your favorite graduate textbook or survey).

---

## Contributing, license, and distribution

Licensed under the **MIT License** — see [`LICENSE`](LICENSE). Copyright © 2026 Mustafa (isnowx). **Contact:** [mustafa@snowgamestr.com](mailto:mustafa@snowgamestr.com). Source files carry SPDX-style notices where applicable.

This tree is a **research artifact**. If you extend it:

- Prefer **proving** new lemmas in place of new axioms when possible.  
- Keep **disclaimers** accurate when publishing any derivative work.  
- If you change the mathlib pin, update **`lean-toolchain`** and re-run `lake build`.

**Shipping as a single zip:** From the repo root, archive the project excluding heavy build artifacts (`.lake/`, `lake-packages/`, `__pycache__/`) — a [`.gitignore`](.gitignore) is provided for that layout. Recipients run `lake build` after install of [elan](https://github.com/leanprover/elan) to fetch the toolchain and build mathlib-linked proofs.
