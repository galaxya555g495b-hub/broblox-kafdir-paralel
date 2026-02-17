#!/usr/bin/env python3
"""Simple capacity planning helper for parallel worker systems."""

from __future__ import annotations

import argparse
import math


def calculate_workers(requests_per_minute: int, avg_job_ms: int, target_utilization: float) -> int:
    requests_per_second = requests_per_minute / 60.0
    service_time_seconds = avg_job_ms / 1000.0

    raw_workers = (requests_per_second * service_time_seconds) / target_utilization
    return max(1, math.ceil(raw_workers))


def suggest_queue_limit(workers: int) -> int:
    return workers * 150


def suggest_max_capacity(workers: int) -> int:
    return workers * 60


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Capacity planner")
    parser.add_argument("--requests-per-minute", type=int, required=True)
    parser.add_argument("--avg-job-ms", type=int, required=True)
    parser.add_argument("--target-utilization", type=float, default=0.7)
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    if not (0.1 <= args.target_utilization <= 0.95):
        raise SystemExit("target-utilization should be between 0.1 and 0.95")

    workers = calculate_workers(
        requests_per_minute=args.requests_per_minute,
        avg_job_ms=args.avg_job_ms,
        target_utilization=args.target_utilization,
    )

    print(f"recommended_workers={workers}")
    print(f"recommended_queue_limit={suggest_queue_limit(workers)}")
    print(f"recommended_max_capacity={suggest_max_capacity(workers)}")


if __name__ == "__main__":
    main()
