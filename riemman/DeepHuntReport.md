# Deep Hunt Report

This report summarizes Phase 4 calibration and the deep-hunt pass.

**Contact:** [mustafa@snowgamestr.com](mailto:mustafa@snowgamestr.com)

## Methods

The numerical engine `numerics/q_hunt.py` was run with:

- Prime-power side **no longer** fixed to “first 100 primes” only.  
- Zero side **no longer** fixed to “first 50 zeros” only; the queue grows adaptively until contributions reach ~`1e-12`.

Archimedean side:

- `scipy.integrate.quad` instead of `mp.quad`.  
- Tolerances `epsabs = epsrel = 1e-12`.

## Adaptive truncation note

The user-requested condition `term.signedWeight < 1e-6` was applied along prime-power ladders. For `m = 1` this threshold is often reached **late**, so the prime front cannot stop on that rule alone.

Two rules were combined:

- For each fixed prime, increase `m` until `signedWeight < 1e-6` **or** effective contribution `< 1e-12`.  
- Stop extending the prime front when the **`m = 1`** effective contribution `< 1e-12`.

This keeps the computation realistic while controlling the tail of the explicit-formula sum.

## Ultra-calibrated kernel

Best kernel:

- `gaussian_a_0.002`

Result:

- `Q_actual = 4.8862519649565165e-09`

Below the targeted `10^-8` level.

Calibrated model details:

- zero count: `207`  
- last gamma: `407.5814603868962`  
- last zero term: `2.945294860219318e-13`  
- scanned primes: `5`  
- included prime-power terms: `1`  
- last scanned prime: `11`  
- archimedean integration error estimate: `1.1487606332830038e-13`

## Deep hunt outcome

Off-line quartet scan:

- Over the first `50` zeros.  
- `epsilon ∈ {0.01, 0.02, 0.05, 0.10, 0.20, 0.40}`.  
- Modes `augment` and `replace_pair` tried.

Smallest hypothetical `Q`:

- kernel: `gaussian_a_0.002`  
- mode: `replace_pair`  
- zero index: `50`  
- gamma: `143.11184580762063`  
- epsilon: `0.4`  
- `Q_hypothesis = 0.003433795621365543`

This value is **positive**.

Best `deltaQ` is the same record:

- `deltaQ = +0.003433790735113578`

So in this calibrated regime, the off-line quartet hypothesis **raises** `Q` rather than pulling it down.

## Interpretation

Two points:

1. Calibration is serious: `Q_actual` is almost zero.  
2. Yet in the chosen Gaussian admissible positive-cone family there is **no** negative witness.

The bottleneck is either:

- a sharper but still admissible kernel family that penalizes off-line quartets, **or**  
- a structural obstruction to producing a witness inside this Gaussian class.

## Artifacts

- Raw results: `numerics/latest_results.json`  
- Hunt engine: `numerics/q_hunt.py`

No `DISCOVERY.md` was created because no witness was found.
