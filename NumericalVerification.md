# Numerical Verification

This note records the first concrete hunt with `numerics/q_hunt.py`.

**Contact:** [mustafa@snowgamestr.com](mailto:mustafa@snowgamestr.com)

## Dataset

- First `100` primes.  
- For each prime, prime-power terms `m = 1..8`.  
- Total prime-power terms: `800`.  
- First `50` positive zeta zeros.  
- Hypothetical off-line zero scan over the first `20` zeros.

## Normalization

mathlib’s Fourier transform uses `2π` normalization, so:

- Zero-side sample point: `gamma / (2 * pi)`.  
- Prime-power sample point: `log(p^m) / (2 * pi)`.

This matches the Lean `ConcreteTruncationModel` scaling.

## Kernel family

Scanned admissible kernels:

- Single Gaussians: `a = 0.002, 0.003, 0.004, 0.005, 0.0075, 0.01, 0.02, 0.05, 0.10`  
- Positive-coefficient Gaussian mixtures:  
  - `gaussian_mix_small = 0.7 * G_0.005 + 0.3 * G_0.03`  
  - `gaussian_mix_mid = 0.6 * G_0.01 + 0.4 * G_0.05`  

Here `G_a(x) = exp(-pi * x^2 / a)` with positive Fourier profile.

## Hypothetical off-line zero scan

Scenarios:

- `mode = augment`: add an off-line quadruple on top of existing zeros.  
- `mode = replace_pair`: replace a critical-line pair with an off-line quadruple.

Physically meaningful regime only:

- `epsilon ∈ {0.01, 0.02, 0.05, 0.10, 0.20, 0.40}`  

so `beta = 1/2 ± epsilon` stays **inside** the critical strip.

## Summary results

- Baseline residual `Q_actual` got very near zero around `a = 0.005`:  
  - `Q_actual = 0.0003246452489952656`  
- Smaller `a` (`0.002`, `0.003`, `0.004`) gave **negative** residual—interpreted as **truncation imbalance**, not a witness.  
- Under valid `epsilon < 1/2` scan, **no** kernel and **no** hypothesis mode yielded `Q_hypothesis < 0`.  
- Smallest hypothetical `Q`:  
  - kernel: `gaussian_a_0.002`  
  - mode: `replace_pair`  
  - zero index: `20`  
  - `gamma = 77.1448400688748`  
  - `epsilon = 0.4`  
  - `Q_hypothesis = 0.002548499591620535`  

Still **positive**.

## Interpretation

In this first finite-truncation hunt:

- Small-`a` regime pulls residual toward zero—the truncation model is **not** meaningless.  
- The off-line quadruple hypothesis does **not**, at this data scale, push `Q` negative.  
- No reliable **negative witness** yet.

## Artifacts

- Script: `numerics/q_hunt.py`  
- Raw output: `numerics/latest_results.json`

No `DISCOVERY.md` because no witness was found.
