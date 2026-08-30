import unittest
import os
import sys
import time
import json
import argparse
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import numpy as np

root_dir = Path(__file__).resolve().parent.parent.parent
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

from fastapi.testclient import TestClient
from backend.main import app

def execute_load_test(num_requests=100, concurrency=10):
    """
    Executes a real multi-threaded concurrent performance load test against API endpoints.
    """
    client = TestClient(app)
    
    # 1. Setup authenticated user
    reg_email = f"loadtest_{os.getpid()}@hospital.org"
    reg_res = client.post("/api/auth/register", json={
        "email": reg_email,
        "password": "LoadTestPass@2026",
        "full_name": "Dr. Load Tester, MD",
        "role": "OPHTHALMOLOGIST"
    })
    token = reg_res.json().get("access_token", "")
    headers = {"Authorization": f"Bearer {token}"} if token else {}

    endpoints = [
        ("GET", "/health", None, {}),
        ("GET", "/api/dashboard/stats", None, headers),
        ("GET", "/api/patients", None, headers),
        ("GET", "/style.css", None, {}),
        ("GET", "/", None, {})
    ]

    latencies = []
    successes = 0
    failures = 0

    start_time = time.time()

    def send_request(idx):
        nonlocal successes, failures
        method, path, body, hdrs = endpoints[idx % len(endpoints)]
        t0 = time.time()
        try:
            if method == "GET":
                r = client.get(path, headers=hdrs)
            else:
                r = client.post(path, json=body, headers=hdrs)
            t1 = time.time()
            elapsed_ms = (t1 - t0) * 1000.0
            if r.status_code in [200, 304]:
                successes += 1
            else:
                failures += 1
            return elapsed_ms
        except Exception:
            failures += 1
            return 0.0

    with ThreadPoolExecutor(max_workers=concurrency) as executor:
        futures = [executor.submit(send_request, i) for i in range(num_requests)]
        for f in futures:
            lat = f.result()
            if lat > 0:
                latencies.append(lat)

    total_time = time.time() - start_time
    avg_latency = float(np.mean(latencies)) if latencies else 0.0
    p50 = float(np.percentile(latencies, 50)) if latencies else 0.0
    p90 = float(np.percentile(latencies, 90)) if latencies else 0.0
    p95 = float(np.percentile(latencies, 95)) if latencies else 0.0
    p99 = float(np.percentile(latencies, 99)) if latencies else 0.0
    rps = float(num_requests / total_time) if total_time > 0 else 0.0

    report = {
        "suite": "Load Testing — Performance",
        "total_requests": num_requests,
        "successful_requests": successes,
        "failed_requests": failures,
        "error_rate_percent": round((failures / num_requests) * 100.0, 2),
        "total_duration_sec": round(total_time, 3),
        "throughput_rps": round(rps, 2),
        "avg_latency_ms": round(avg_latency, 2),
        "p50_latency_ms": round(p50, 2),
        "p90_latency_ms": round(p90, 2),
        "p95_latency_ms": round(p95, 2),
        "p99_latency_ms": round(p99, 2)
    }

    return report

class TestLoadPerformanceSuite(unittest.TestCase):
    """
    Performance and Load Testing Unit Suite.
    """

    def test_01_concurrent_load_performance(self):
        """Execute concurrent performance load test and verify SLA metrics."""
        report = execute_load_test(num_requests=50, concurrency=5)
        self.assertEqual(report["failed_requests"], 0, f"Load test had failures: {report}")
        self.assertGreater(report["throughput_rps"], 5.0)
        self.assertLess(report["avg_latency_ms"], 500.0)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", default="results")
    parser.add_argument("--requests", type=int, default=100)
    parser.add_argument("--concurrency", type=int, default=10)
    args = parser.parse_args()

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    report = execute_load_test(num_requests=args.requests, concurrency=args.concurrency)

    # Save JSON report
    json_path = out_dir / "load-test-report.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)

    # Save JUnit XML report
    xml_path = out_dir / "load-test-report.xml"
    xml_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="Load Testing — Performance" tests="{report['total_requests']}" failures="{report['failed_requests']}" errors="0" skipped="0" time="{report['total_duration_sec']}">
    <testcase name="concurrent_load_test" classname="performance.load" time="{report['total_duration_sec']}"/>
</testsuite>
"""
    with open(xml_path, "w", encoding="utf-8") as f:
        f.write(xml_content)

    print(f"Load test completed: {report['total_requests']} requests ({report['throughput_rps']} RPS, avg: {report['avg_latency_ms']}ms)")
    print(f"Reports saved to {json_path} and {xml_path}")

if __name__ == "__main__":
    if "--output-dir" in sys.argv or "--requests" in sys.argv:
        main()
    else:
        unittest.main()
