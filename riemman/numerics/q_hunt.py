from __future__ import annotations

# Copyright (c) 2026 Mustafa (isnowx). SPDX-License-Identifier: MIT
# Contact: mustafa@snowgamestr.com

import cProfile
import cmath
import json
import math
import os
import pstats
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from dataclasses import asdict, dataclass
from functools import cached_property
from pathlib import Path
from typing import Iterator

import mpmath as mp
import numpy as np
from scipy import integrate, special


mp.mp.dps = 80

TWO_PI = 2.0 * math.pi


@dataclass(frozen=True)
class EvaluationConfig:
    power_weight_tol: float = 1e-6
    prime_contribution_tol: float = 1e-12
    zero_term_tol: float = 1e-12
    min_zero_count: int = 50
    zero_small_streak: int = 6
    max_zero_count: int = 400
    max_prime_count: int = 100000
    max_power: int = 256
    arch_epsabs: float = 1e-12
    arch_epsrel: float = 1e-12
    target_cpu_fraction: float = 0.75


@dataclass(frozen=True)
class PrimePowerTerm:
    prime: int
    power: int
    signed_weight: float
    sample_point: float
    contribution_bound: float


@dataclass(frozen=True)
class AdaptivePrimeSummary:
    prime_count: int
    prime_power_term_count: int
    largest_prime: int
    largest_power: int
    power_weight_tol: float
    contribution_tol: float
    m1_weight_tol_reached: bool


@dataclass(frozen=True)
class AdaptiveZeroSummary:
    zero_count: int
    last_gamma: float
    last_term: float
    term_tol: float


@dataclass(frozen=True)
class KernelSpec:
    name: str
    components: tuple[tuple[float, float], ...]

    @cached_property
    def weights_np(self) -> np.ndarray:
        return np.array([float(w) for w, _ in self.components], dtype=np.float64)

    @cached_property
    def scales_np(self) -> np.ndarray:
        return np.array([float(a) for _, a in self.components], dtype=np.float64)

    @cached_property
    def sqrt_scales_np(self) -> np.ndarray:
        return np.sqrt(self.scales_np)

    def min_scale(self) -> float:
        return float(np.min(self.scales_np))

    def component_dicts(self) -> list[dict[str, float]]:
        return [{"weight": float(w), "scale": float(a)} for w, a in self.components]

    def g_real(self, x: float) -> float:
        xx = float(x)
        return float(np.sum(self.weights_np * np.exp(-math.pi * xx * xx / self.scales_np)))

    def h_real(self, u: float) -> float:
        uu = float(u)
        return float(
            np.sum(
                self.weights_np
                * self.sqrt_scales_np
                * np.exp(-math.pi * self.scales_np * uu * uu)
            )
        )

    def g_real_vec(self, x: np.ndarray) -> np.ndarray:
        xs = np.asarray(x, dtype=np.float64)
        exponents = -math.pi * np.square(xs)[None, :] / self.scales_np[:, None]
        return np.sum(self.weights_np[:, None] * np.exp(exponents), axis=0)

    def h_real_vec(self, u: np.ndarray) -> np.ndarray:
        us = np.asarray(u, dtype=np.float64)
        exponents = -math.pi * self.scales_np[:, None] * np.square(us)[None, :]
        return np.sum(
            (self.weights_np * self.sqrt_scales_np)[:, None] * np.exp(exponents),
            axis=0,
        )

    def h_complex(self, z: complex) -> complex:
        total = 0j
        for weight, scale in self.components:
            total += float(weight) * math.sqrt(float(scale)) * cmath.exp(
                -math.pi * float(scale) * z * z
            )
        return total

    def quartet_values(self, gamma: float, epsilons: np.ndarray) -> np.ndarray:
        g = gamma / TWO_PI
        s = epsilons / TWO_PI
        scales = self.scales_np[:, None]
        weights = self.weights_np[:, None]
        sqrt_scales = self.sqrt_scales_np[:, None]
        exponent = -math.pi * scales * (g * g - s * s)
        phase = 2.0 * math.pi * scales * g * s
        values = 4.0 * np.sum(
            weights * sqrt_scales * np.exp(exponent) * np.cos(phase),
            axis=0,
        )
        return values


@dataclass(frozen=True)
class KernelEvaluation:
    kernel: KernelSpec
    q_actual: float
    boundary: float
    archimedean: float
    archimedean_error: float
    prime_power: float
    zero_side: float
    zero_ordinates: tuple[float, ...]
    zero_terms: tuple[float, ...]
    zero_summary: AdaptiveZeroSummary
    prime_summary: AdaptivePrimeSummary


@dataclass
class HuntRecord:
    kernel: str
    mode: str
    gamma_index: int
    gamma: float
    epsilon: float
    q_actual: float
    q_hypothesis: float
    delta_q: float


def prime_generator() -> Iterator[int]:
    yield 2
    primes = [2]
    candidate = 3
    while True:
        is_prime = True
        limit = int(candidate**0.5)
        for p in primes:
            if p > limit:
                break
            if candidate % p == 0:
                is_prime = False
                break
        if is_prime:
            primes.append(candidate)
            yield candidate
        candidate += 2


def first_primes(n: int) -> tuple[int, ...]:
    result = []
    for idx, p in enumerate(prime_generator(), start=1):
        result.append(p)
        if idx >= n:
            break
    return tuple(result)


def zeta_zero_ordinate_worker(k: int) -> tuple[int, float]:
    return k, float(mp.im(mp.zetazero(k)))


def load_or_compute_zero_pool(
    max_count: int, cache_path: Path, worker_count: int
) -> tuple[tuple[float, ...], dict[str, object]]:
    if cache_path.exists():
        payload = json.loads(cache_path.read_text(encoding="utf-8"))
        ordinates = payload.get("ordinates", [])
        if payload.get("max_count") == max_count and len(ordinates) >= max_count:
            return tuple(float(x) for x in ordinates[:max_count]), {
                "cache_hit": True,
                "worker_count": worker_count,
                "cache_path": str(cache_path.name),
            }

    with ProcessPoolExecutor(max_workers=worker_count) as executor:
        futures = [executor.submit(zeta_zero_ordinate_worker, k) for k in range(1, max_count + 1)]
        items = [future.result() for future in as_completed(futures)]
    items.sort(key=lambda pair: pair[0])
    ordinates = [value for _, value in items]
    cache_path.write_text(
        json.dumps({"max_count": max_count, "ordinates": ordinates}),
        encoding="utf-8",
    )
    return tuple(ordinates), {
        "cache_hit": False,
        "worker_count": worker_count,
        "cache_path": str(cache_path.name),
    }


def build_adaptive_zero_ordinates(
    kernel: KernelSpec, config: EvaluationConfig, zero_pool: tuple[float, ...]
) -> tuple[tuple[float, ...], tuple[float, ...], AdaptiveZeroSummary]:
    zero_array = np.asarray(zero_pool, dtype=np.float64)
    terms = 2.0 * kernel.h_real_vec(zero_array / TWO_PI)
    cutoff = len(zero_array)
    small_streak = 0
    for idx, term in enumerate(terms):
        if idx + 1 >= config.min_zero_count and abs(float(term)) < config.zero_term_tol:
            small_streak += 1
            if small_streak >= config.zero_small_streak:
                cutoff = idx + 1
                break
        else:
            small_streak = 0
    summary = AdaptiveZeroSummary(
        zero_count=int(cutoff),
        last_gamma=float(zero_array[cutoff - 1]),
        last_term=float(terms[cutoff - 1]),
        term_tol=config.zero_term_tol,
    )
    return tuple(zero_array[:cutoff]), tuple(float(x) for x in terms[:cutoff]), summary


def build_adaptive_prime_power_terms(
    kernel: KernelSpec, config: EvaluationConfig, prime_pool: tuple[int, ...]
) -> tuple[tuple[PrimePowerTerm, ...], AdaptivePrimeSummary]:
    terms: list[PrimePowerTerm] = []
    largest_prime = 2
    largest_power = 0
    prime_count = 0
    m1_weight_tol_reached = False

    for p in prime_pool:
        prime_count += 1
        if prime_count > config.max_prime_count:
            break
        largest_prime = p
        log_p = math.log(p)
        m1_weight = log_p / math.sqrt(p)
        if m1_weight < config.power_weight_tol:
            m1_weight_tol_reached = True
        m1_sample = log_p / TWO_PI
        m1_contribution = 2.0 * m1_weight * kernel.g_real(m1_sample)
        if p >= 11 and m1_contribution < config.prime_contribution_tol:
            break

        for power in range(1, config.max_power + 1):
            pm = p**power
            weight = log_p / math.sqrt(pm)
            sample = math.log(pm) / TWO_PI
            contribution = 2.0 * weight * kernel.g_real(sample)
            if weight < config.power_weight_tol or contribution < config.prime_contribution_tol:
                break
            terms.append(
                PrimePowerTerm(
                    prime=p,
                    power=power,
                    signed_weight=weight,
                    sample_point=sample,
                    contribution_bound=contribution,
                )
            )
            largest_power = max(largest_power, power)

    summary = AdaptivePrimeSummary(
        prime_count=prime_count,
        prime_power_term_count=len(terms),
        largest_prime=largest_prime,
        largest_power=largest_power,
        power_weight_tol=config.power_weight_tol,
        contribution_tol=config.prime_contribution_tol,
        m1_weight_tol_reached=m1_weight_tol_reached,
    )
    return tuple(terms), summary


def boundary_term(kernel: KernelSpec) -> float:
    pole = 2.0 * kernel.h_complex(1j / (4.0 * math.pi)).real
    log_pi = kernel.g_real(0.0) * math.log(math.pi)
    return float(pole - log_pi)


def archimedean_integral(kernel: KernelSpec, config: EvaluationConfig) -> tuple[float, float]:
    def integrand(u: float) -> float:
        return kernel.h_real(u) * float(special.digamma(0.25 + math.pi * 1j * u).real)

    value, error = integrate.quad(
        integrand,
        0.0,
        math.inf,
        epsabs=config.arch_epsabs,
        epsrel=config.arch_epsrel,
        limit=400,
    )
    return float(2.0 * value), float(error)


def prime_power_side(kernel: KernelSpec, terms: tuple[PrimePowerTerm, ...]) -> float:
    if not terms:
        return 0.0
    samples = np.array([term.sample_point for term in terms], dtype=np.float64)
    weights = np.array([term.signed_weight for term in terms], dtype=np.float64)
    values = kernel.g_real_vec(samples)
    return float(np.sum(2.0 * weights * values))


def evaluate_kernel(
    kernel: KernelSpec, config: EvaluationConfig, zero_pool: tuple[float, ...], prime_pool: tuple[int, ...]
) -> KernelEvaluation:
    zero_ordinates, zero_terms, zero_summary = build_adaptive_zero_ordinates(kernel, config, zero_pool)
    prime_terms, prime_summary = build_adaptive_prime_power_terms(kernel, config, prime_pool)
    zero_side = float(sum(zero_terms))
    boundary = boundary_term(kernel)
    archimedean, arch_error = archimedean_integral(kernel, config)
    prime_side = prime_power_side(kernel, prime_terms)
    q_actual = zero_side - boundary - archimedean + prime_side
    return KernelEvaluation(
        kernel=kernel,
        q_actual=float(q_actual),
        boundary=float(boundary),
        archimedean=float(archimedean),
        archimedean_error=float(arch_error),
        prime_power=float(prime_side),
        zero_side=float(zero_side),
        zero_ordinates=zero_ordinates,
        zero_terms=zero_terms,
        zero_summary=zero_summary,
        prime_summary=prime_summary,
    )


def evaluate_kernel_worker(
    kernel: KernelSpec, config: EvaluationConfig, zero_pool: tuple[float, ...], prime_pool: tuple[int, ...]
) -> KernelEvaluation:
    return evaluate_kernel(kernel, config, zero_pool, prime_pool)


def profile_single_kernel(
    kernel: KernelSpec, config: EvaluationConfig, zero_pool: tuple[float, ...], prime_pool: tuple[int, ...]
) -> dict[str, object]:
    profiler = cProfile.Profile()
    profiler.enable()
    evaluate_kernel(kernel, config, zero_pool, prime_pool)
    profiler.disable()
    stats = pstats.Stats(profiler).sort_stats("cumtime")
    lines: list[str] = []
    for func, stat in list(stats.stats.items())[:0]:
        _ = func, stat
    import io

    stream = io.StringIO()
    stats.stream = stream
    stats.print_stats(12)
    raw = stream.getvalue().splitlines()
    top_lines = [line for line in raw if line.strip()][:16]
    return {"kernel": kernel.name, "top_cprofile_lines": top_lines}


def evaluation_summary_dict(evaluation: KernelEvaluation) -> dict[str, object]:
    return {
        "components": evaluation.kernel.component_dicts(),
        "q_actual": evaluation.q_actual,
        "boundary": evaluation.boundary,
        "archimedean": evaluation.archimedean,
        "archimedean_error": evaluation.archimedean_error,
        "prime_power": evaluation.prime_power,
        "zero_side": evaluation.zero_side,
        "zero_count": evaluation.zero_summary.zero_count,
        "last_gamma": evaluation.zero_summary.last_gamma,
        "last_zero_term": evaluation.zero_summary.last_term,
        "prime_count": evaluation.prime_summary.prime_count,
        "prime_power_term_count": evaluation.prime_summary.prime_power_term_count,
        "largest_prime": evaluation.prime_summary.largest_prime,
        "largest_power": evaluation.prime_summary.largest_power,
        "m1_weight_tol_reached": evaluation.prime_summary.m1_weight_tol_reached,
    }


def max_workers_for(task_count: int, config: EvaluationConfig) -> int:
    cpu = os.cpu_count() or 1
    target = max(1, int(round(cpu * config.target_cpu_fraction)))
    return max(1, min(task_count, target))


def parallel_evaluate_kernels(
    kernels: list[KernelSpec], config: EvaluationConfig, zero_pool: tuple[float, ...], prime_pool: tuple[int, ...]
) -> list[KernelEvaluation]:
    workers = max_workers_for(len(kernels), config)
    results: list[KernelEvaluation] = []
    with ProcessPoolExecutor(max_workers=workers) as executor:
        futures = [
            executor.submit(evaluate_kernel_worker, kernel, config, zero_pool, prime_pool)
            for kernel in kernels
        ]
        for future in as_completed(futures):
            results.append(future.result())
    results.sort(key=lambda ev: ev.kernel.name)
    return results


def hunt_best_records_for_kernel(
    evaluation: KernelEvaluation, epsilons: np.ndarray, target_zero_count: int
) -> tuple[HuntRecord, HuntRecord]:
    best_negative: HuntRecord | None = None
    best_delta: HuntRecord | None = None
    q_actual = evaluation.q_actual
    zero_count = min(target_zero_count, len(evaluation.zero_ordinates))

    for idx in range(zero_count):
        gamma = evaluation.zero_ordinates[idx]
        pair = evaluation.zero_terms[idx]
        quartet = evaluation.kernel.quartet_values(gamma, epsilons)
        candidates = {
            "augment": q_actual + quartet,
            "replace_pair": q_actual - pair + quartet,
        }
        for mode, values in candidates.items():
            min_idx = int(np.argmin(values))
            q_hyp = float(values[min_idx])
            record = HuntRecord(
                kernel=evaluation.kernel.name,
                mode=mode,
                gamma_index=idx + 1,
                gamma=float(gamma),
                epsilon=float(epsilons[min_idx]),
                q_actual=float(q_actual),
                q_hypothesis=q_hyp,
                delta_q=float(q_hyp - q_actual),
            )
            if best_negative is None or record.q_hypothesis < best_negative.q_hypothesis:
                best_negative = record
            if best_delta is None or record.delta_q < best_delta.delta_q:
                best_delta = record

    assert best_negative is not None
    assert best_delta is not None
    return best_negative, best_delta


def hunt_kernel_worker(
    evaluation: KernelEvaluation, epsilons: tuple[float, ...], target_zero_count: int
) -> dict[str, object]:
    eps_array = np.asarray(epsilons, dtype=np.float64)
    best_negative, best_delta = hunt_best_records_for_kernel(evaluation, eps_array, target_zero_count)
    witness = None
    if abs(best_negative.q_actual) <= 1e-6 and best_negative.q_hypothesis < -1e-6 and best_negative.delta_q < -1e-6:
        witness = best_negative
    return {
        "kernel": evaluation.kernel.name,
        "best_negative": asdict(best_negative),
        "best_delta": asdict(best_delta),
        "witness": None if witness is None else asdict(witness),
    }


def parallel_hunt(
    evaluations: list[KernelEvaluation], epsilons: tuple[float, ...], target_zero_count: int, config: EvaluationConfig
) -> dict[str, object]:
    workers = max_workers_for(len(evaluations), config)
    kernel_results: list[dict[str, object]] = []
    with ProcessPoolExecutor(max_workers=workers) as executor:
        futures = [
            executor.submit(hunt_kernel_worker, evaluation, epsilons, target_zero_count)
            for evaluation in evaluations
        ]
        for future in as_completed(futures):
            kernel_results.append(future.result())

    best_negative = min(
        (result["best_negative"] for result in kernel_results),
        key=lambda record: record["q_hypothesis"],
    )
    best_delta = min(
        (result["best_delta"] for result in kernel_results),
        key=lambda record: record["delta_q"],
    )
    witnesses = [result["witness"] for result in kernel_results if result["witness"] is not None]
    witness = min(witnesses, key=lambda record: record["q_hypothesis"]) if witnesses else None
    return {
        "kernel_results": kernel_results,
        "best_negative_q": best_negative,
        "best_delta_q": best_delta,
        "witness_found": witness is not None,
        "witness": witness,
    }


def make_single_gaussian_kernel(scale: float, name: str | None = None) -> KernelSpec:
    scale = float(scale)
    label = name or f"gaussian_a_{scale:.12g}"
    return KernelSpec(label, ((1.0, scale),))


def make_mixture_kernel(weight: float, a1: float, a2: float, name: str | None = None) -> KernelSpec:
    w = float(weight)
    comps = ((w, float(a1)), (1.0 - w, float(a2)))
    label = name or f"mix_w_{w:.6f}_a1_{a1:.6g}_a2_{a2:.6g}"
    return KernelSpec(label, comps)


def make_poisson_like_kernel(
    core_scale: float, tail_scale: float, tail_weight: float, name: str | None = None
) -> KernelSpec:
    label = name or (
        f"poisson_like_core_{core_scale:.6g}_tail_{tail_scale:.6g}_wt_{tail_weight:.6g}"
    )
    return make_mixture_kernel(1.0 - tail_weight, core_scale, tail_scale, label)


def make_fejer_like_kernel(
    core_scale: float, shoulder_scale: float, shoulder_weight: float, name: str | None = None
) -> KernelSpec:
    label = name or (
        f"fejer_like_core_{core_scale:.6g}_shoulder_{shoulder_scale:.6g}_wt_{shoulder_weight:.6g}"
    )
    return make_mixture_kernel(1.0 - shoulder_weight, core_scale, shoulder_scale, label)


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    results_path = root / "numerics" / "latest_results.json"
    discovery_path = root / "DISCOVERY.md"
    profile_path = root / "numerics" / "profile_summary.json"
    zero_cache_path = root / "numerics" / f"zero_pool_{EvaluationConfig().max_zero_count}.json"

    config = EvaluationConfig()
    epsilons = tuple(k / 1000.0 for k in range(1, 401))

    candidate_kernels = [
        make_single_gaussian_kernel(0.0015),
        make_single_gaussian_kernel(0.0018),
        make_single_gaussian_kernel(0.002),
        make_single_gaussian_kernel(0.0022),
        make_single_gaussian_kernel(0.0025),
        make_single_gaussian_kernel(0.003),
        make_single_gaussian_kernel(0.004),
        make_single_gaussian_kernel(0.005),
        make_poisson_like_kernel(0.0018, 0.02, 0.02, "poisson_like_ultra_1"),
        make_poisson_like_kernel(0.0020, 0.05, 0.01, "poisson_like_ultra_2"),
        make_fejer_like_kernel(0.0015, 0.0045, 0.08, "fejer_like_ultra_1"),
        make_fejer_like_kernel(0.0020, 0.0060, 0.12, "fejer_like_ultra_2"),
    ]

    timings: dict[str, float] = {}
    zero_cache_meta: dict[str, object]

    t0 = time.perf_counter()
    zero_pool, zero_cache_meta = load_or_compute_zero_pool(
        config.max_zero_count,
        zero_cache_path,
        max_workers_for(config.max_zero_count, config),
    )
    prime_pool = first_primes(5000)
    timings["precompute_seconds"] = time.perf_counter() - t0

    profile_summary = profile_single_kernel(candidate_kernels[2], config, zero_pool, prime_pool)
    profile_path.write_text(json.dumps(profile_summary, indent=2), encoding="utf-8")

    t1 = time.perf_counter()
    candidate_evaluations = parallel_evaluate_kernels(candidate_kernels, config, zero_pool, prime_pool)
    timings["parallel_evaluation_seconds"] = time.perf_counter() - t1

    candidate_summary = {
        evaluation.kernel.name: evaluation_summary_dict(evaluation)
        for evaluation in candidate_evaluations
    }
    best_eval = min(candidate_evaluations, key=lambda ev: abs(ev.q_actual))
    hunt_evaluations = [
        ev for ev in candidate_evaluations if abs(ev.q_actual) <= 1e-2
    ]
    if not hunt_evaluations:
        hunt_evaluations = sorted(candidate_evaluations, key=lambda ev: abs(ev.q_actual))[:5]

    target_zero_count = 50
    t2 = time.perf_counter()
    hunt_summary = parallel_hunt(hunt_evaluations, epsilons, target_zero_count, config)
    timings["parallel_hunt_seconds"] = time.perf_counter() - t2
    timings["total_seconds"] = time.perf_counter() - t0

    payload = {
        "config": asdict(config),
        "performance": {
            "cpu_count": os.cpu_count(),
            "target_worker_count": max_workers_for(len(candidate_kernels), config),
            "zero_pool": zero_cache_meta,
            "timings": timings,
            "batch_write_policy": "single final JSON write; no per-step disk flushes",
            "vectorization": [
                "zero-side tail evaluation uses numpy arrays",
                "prime-power side uses vectorized kernel evaluation on sample points",
                "quartet hunt is vectorized over the epsilon grid",
            ],
            "profile_summary_path": str(profile_path.name),
        },
        "candidate_kernels": candidate_summary,
        "calibration": {
            "best_kernel": {
                "name": best_eval.kernel.name,
                **evaluation_summary_dict(best_eval),
            },
            "target_hit_abs_q_lt_1e_8": abs(best_eval.q_actual) < 1e-8,
        },
        "deep_hunt": {
            "hypothesis_zero_count": target_zero_count,
            "epsilon_step": 0.001,
            "epsilon_count": len(epsilons),
            "searched_kernels": [evaluation.kernel.name for evaluation in hunt_evaluations],
            **hunt_summary,
        },
    }
    results_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    witness = hunt_summary["witness"]
    if witness is not None:
        discovery_path.write_text(
            "\n".join(
                [
                    "# Discovery",
                    "",
                    "A conservative negative witness candidate was detected in the aggressive deep hunt.",
                    "",
                    f"- Kernel: `{witness['kernel']}`",
                    f"- Mode: `{witness['mode']}`",
                    f"- Zero index: `{witness['gamma_index']}`",
                    f"- Gamma: `{witness['gamma']}`",
                    f"- Epsilon: `{witness['epsilon']}`",
                    f"- Baseline Q: `{witness['q_actual']}`",
                    f"- Hypothetical Q: `{witness['q_hypothesis']}`",
                    f"- Delta Q: `{witness['delta_q']}`",
                ]
            ),
            encoding="utf-8",
        )
    elif discovery_path.exists():
        discovery_path.unlink()


if __name__ == "__main__":
    main()
