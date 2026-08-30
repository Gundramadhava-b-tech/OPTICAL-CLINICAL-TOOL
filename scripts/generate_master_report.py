import os
import json
import xml.etree.ElementTree as ET
from datetime import datetime
import argparse

def parse_junit(file_path):
    if not os.path.exists(file_path):
        return {"status": "FAIL", "passed": 0, "failed": 0, "skipped": 0, "total": 0, "duration": 0}

    try:
        tree = ET.parse(file_path)
        root = tree.getroot()

        tests = int(root.get("tests", 0))
        failures = int(root.get("failures", 0))
        errors = int(root.get("errors", 0))
        skipped = int(root.get("skipped", 0))
        time = float(root.get("time", 0))

        passed = tests - failures - errors - skipped
        status = "PASS" if (failures + errors) == 0 and tests > 0 else "FAIL"

        return {
            "status": status,
            "passed": passed,
            "failed": failures + errors,
            "skipped": skipped,
            "total": tests,
            "duration": round(time, 2)
        }
    except Exception:
        return {"status": "FAIL", "passed": 0, "failed": 0, "skipped": 0, "total": 0, "duration": 0}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sha", default="unknown")
    parser.add_argument("--run-number", default="0")
    parser.add_argument("--results-dir", default="results")
    args = parser.parse_args()

    # Results mapping
    results = {
        "Unit Tests": parse_junit(os.path.join(args.results_dir, "unit-test-report.xml")),
        "Validation Tests": parse_junit(os.path.join(args.results_dir, "validation-test-report.xml")),
        "Selenium Web Tests": parse_junit(os.path.join(args.results_dir, "selenium-web-report.xml")),
        "Appium Android Tests": parse_junit(os.path.join(args.results_dir, "appium-android-report.xml")),
    }

    # Deployment and Load tests might be different formats, for now assuming JUnit or mocking
    results["Load Testing"] = parse_junit(os.path.join(args.results_dir, "load-test-report.xml"))
    results["Deployment Status"] = parse_junit(os.path.join(args.results_dir, "deployment-test-report.xml"))

    total_executed = sum(r["total"] for r in results.values())
    total_passed = sum(r["passed"] for r in results.values())
    total_failed = sum(r["failed"] for r in results.values())
    total_skipped = sum(r["skipped"] for r in results.values())

    pass_rate = (total_passed / total_executed * 100) if total_executed > 0 else 0
    overall_status = "✅ PASSED" if total_failed == 0 and total_executed > 0 else "❌ FAILED"

    # Generate HTML
    html_content = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RetinaSeg AI - Executive Master Test Summary</title>
    <style>
        body {{ font-family: 'Inter', -apple-system, sans-serif; background-color: #0d1117; color: #c9d1d9; margin: 0; padding: 40px; }}
        .container {{ max-width: 1000px; margin: 0 auto; background: #161b22; padding: 30px; border-radius: 8px; border: 1px solid #30363d; }}
        h1 {{ color: #58a6ff; margin-bottom: 5px; }}
        h2 {{ color: #8b949e; font-size: 1.2rem; font-weight: 400; margin-top: 0; margin-bottom: 30px; }}
        .summary-box {{ display: flex; gap: 20px; margin-bottom: 30px; }}
        .stat-card {{ flex: 1; background: #0d1117; padding: 20px; border-radius: 6px; border: 1px solid #30363d; text-align: center; }}
        .stat-value {{ font-size: 2rem; font-weight: 700; color: #fff; }}
        .stat-label {{ font-size: 0.8rem; color: #8b949e; text-transform: uppercase; margin-top: 5px; }}
        table {{ width: 100%; border-collapse: collapse; margin-top: 20px; }}
        th, td {{ padding: 12px; text-align: left; border-bottom: 1px solid #30363d; }}
        th {{ background-color: #21262d; color: #fff; }}
        .status-pass {{ color: #3fb950; font-weight: bold; }}
        .status-fail {{ color: #f85149; font-weight: bold; }}
        .footer {{ margin-top: 40px; font-size: 0.8rem; color: #8b949e; text-align: center; border-top: 1px solid #30363d; padding-top: 20px; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>RetinaSeg AI — Executive Master Test Summary</h1>
        <h2>Automated Retinal Layer Segmentation in OCT Images Using Enhanced Preprocessing and U-Net Architecture</h2>

        <div style="font-size: 1.5rem; margin-bottom: 20px;">Overall Status: {overall_status}</div>

        <div class="summary-box">
            <div class="stat-card">
                <div class="stat-value">{total_executed}</div>
                <div class="stat-label">Total Executed</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{total_passed}</div>
                <div class="stat-label">Passed</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{total_failed}</div>
                <div class="stat-label">Failed</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{round(pass_rate, 1)}%</div>
                <div class="stat-label">Pass Rate</div>
            </div>
        </div>

        <table>
            <tr>
                <th>Metric</th>
                <th>Value</th>
            </tr>
            <tr><td>Commit SHA</td><td><code>{args.sha}</code></td></tr>
            <tr><td>CI Run Number</td><td>#{args.run_number}</td></tr>
            <tr><td>Timestamp</td><td>{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</td></tr>
        </table>

        <h3>🧪 Test Suite Results Matrix</h3>
        <table>
            <thead>
                <tr>
                    <th>Suite</th>
                    <th>Status</th>
                    <th>Passed</th>
                    <th>Failed</th>
                    <th>Skipped</th>
                    <th>Total</th>
                    <th>Duration</th>
                </tr>
            </thead>
            <tbody>
"""

    for suite, data in results.items():
        status_class = "status-pass" if data["status"] == "PASS" else "status-fail"
        html_content += f"""
                <tr>
                    <td>{suite}</td>
                    <td class="{status_class}">{data["status"]}</td>
                    <td>{data["passed"]}</td>
                    <td>{data["failed"]}</td>
                    <td>{data["skipped"]}</td>
                    <td>{data["total"]}</td>
                    <td>{data["duration"]}s</td>
                </tr>
"""

    html_content += """
            </tbody>
        </table>

        <div class="footer">
            Report generated by AeroDiag Master CI/CD Pipeline
        </div>
    </div>
</body>
</html>
"""

    output_file = os.path.join("reports", "master-report.html")
    os.makedirs("reports", exist_ok=True)
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(html_content)

    print(f"Master report generated at {output_file}")

    # Generate Markdown summary for GitHub Actions
    with open(os.environ.get("GITHUB_STEP_SUMMARY", "summary.md"), "a") as f:
        f.write(f"## AeroDiag — Executive Master Test Summary\n\n")
        f.write(f"### Overall Status: {overall_status}\n\n")
        f.write(f"| Metric | Value |\n| --- | --- |\n")
        f.write(f"| Total Tests Executed | {total_executed} |\n")
        f.write(f"| Passed | {total_passed} |\n")
        f.write(f"| Failed | {total_failed} |\n")
        f.write(f"| Pass Rate | {round(pass_rate, 1)}% |\n")
        f.write(f"| Commit SHA | `{args.sha[:7]}` |\n")
        f.write(f"| CI Run Number | #{args.run_number} |\n\n")

        f.write(f"### 🧪 Test Suite Results Matrix\n\n")
        f.write(f"| Suite Icon & Name | Status | Passed | Failed | Total | Duration |\n")
        f.write(f"| --- | --- | --- | --- | --- | --- |\n")
        for suite, data in results.items():
            icon = "✅" if data["status"] == "PASS" else "❌"
            f.write(f"| {icon} {suite} | {data['status']} | {data['passed']} | {data['failed']} | {data['total']} | {data['duration']}s |\n")

        f.write(f"\n_Report generated by AeroDiag Master CI/CD Pipeline_")

if __name__ == "__main__":
    main()
