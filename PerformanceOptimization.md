# Performance Optimization

This note records what Phase 5 performance work did and why CPU usage looked low in the earlier version.

**Contact:** [mustafa@snowgamestr.com](mailto:mustafa@snowgamestr.com)

## Why was CPU usage low?

Two effects dominated runtime in the old version:

1. Rebuilding the `zetazero` pool from scratch on every run as a single work chunk.  
2. Running the kernel hunt on a **single** process.

On a many-core machine total CPU **percentage** stays modest when one heavy Python process only fills a small fraction of the system.

## Improvements made

- `ProcessPoolExecutor` parallelizes kernel evaluations across tasks.  
- Deep hunt parallelized per kernel.  
- Zero-side and prime-power sides **vectorized** with `numpy`.  
- Quartet contribution computed on a grid of `epsilon` values in bulk.  
- Results written to disk **once** at the end (single JSON), not every step.  
- `zetazero` pool cached in `numerics/zero_pool_400.json`.

## Profiling summary

Profile artifact:

- `numerics/profile_summary.json`

For a single-kernel profile, largest local cost:

- `archimedean_integral`  
- Inside it: `scipy.integrate.quad`  
- And in the integrand: `h_real`

After these optimizations the bottleneck is **no longer** Python loops—it is the Gauss–Kronrod quadrature itself.

## Speed outcome

After cache hit, a recent run:

- `precompute_seconds ≈ 0.01`  
- `parallel_evaluation_seconds ≈ 0.80`  
- `parallel_hunt_seconds ≈ 0.75`  
- `total_seconds ≈ 1.57`

This is a dramatic improvement over earlier tens-of-seconds or minute-scale runs.

## Mathematical outcome

Speed did **not** change the witness picture:

- In aggressive Gaussian / Poisson-like / Fejér-like admissible families, `Q_hypothesis` did **not** go negative.

So the next strategic shift—as intended—is toward **global positivity** and theoretical lower bounds.
