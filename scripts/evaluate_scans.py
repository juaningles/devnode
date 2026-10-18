#!/usr/bin/env python3
"""Summarize and compare Trivy JSON reports for devnode base images and
recommend which one Dockerfile.full should point at.

usage: evaluate_scans.py reports/eval-noble.json reports/eval-resolute.json ...
"""
import json
import os
import subprocess
import sys

SEVERITIES = ["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN"]
# Weighted risk score; fixable vulns weigh more because they mean the image is
# behind on patches, unfixed ones are what you live with on that release.
WEIGHTS = {"CRITICAL": 10, "HIGH": 5, "MEDIUM": 2, "LOW": 1, "UNKNOWN": 0}
REPO = os.environ.get("EVAL_REPO", "devnode")


def tag_from_path(path):
    name = os.path.splitext(os.path.basename(path))[0]
    return name[len("eval-"):] if name.startswith("eval-") else name


def image_size_mb(tag):
    docker = os.environ.get("DOCKER", "docker")
    try:
        out = subprocess.run([docker, "image", "inspect", "-f", "{{.Size}}", f"{REPO}:{tag}"],
                             capture_output=True, text=True, check=True).stdout
        return int(out.strip()) / 1_000_000
    except (OSError, subprocess.CalledProcessError, ValueError):
        return None


def load(path):
    with open(path) as f:
        report = json.load(f)
    tag = tag_from_path(path)
    os_meta = report.get("Metadata", {}).get("OS", {})
    base_file = os.path.splitext(path)[0] + ".base"
    base = open(base_file).read().strip() if os.path.exists(base_file) else None
    vulns = {}
    for result in report.get("Results", []):
        for v in result.get("Vulnerabilities") or []:
            # one entry per CVE; keep the highest severity / any fix
            vid = v["VulnerabilityID"]
            sev = v.get("Severity", "UNKNOWN")
            prev = vulns.get(vid)
            fixed = bool(v.get("FixedVersion"))
            if prev is None:
                vulns[vid] = {"severity": sev, "fixable": fixed, "pkgs": {v["PkgName"]}}
            else:
                if SEVERITIES.index(sev) < SEVERITIES.index(prev["severity"]):
                    prev["severity"] = sev
                prev["fixable"] |= fixed
                prev["pkgs"].add(v["PkgName"])
    counts = {s: 0 for s in SEVERITIES}
    fixable = {s: 0 for s in SEVERITIES}
    for v in vulns.values():
        counts[v["severity"]] += 1
        if v["fixable"]:
            fixable[v["severity"]] += 1
    score = sum(WEIGHTS[s] * counts[s] + WEIGHTS[s] * fixable[s] for s in SEVERITIES)
    return {
        "tag": tag,
        "base": base,
        "os": f'{os_meta.get("Family", "?")} {os_meta.get("Name", "?")}',
        "eosl": bool(os_meta.get("EOSL")),
        "vulns": vulns,
        "counts": counts,
        "fixable": fixable,
        "score": score,
        "size": image_size_mb(tag),
    }


def table(headers, rows):
    widths = [max(len(str(x)) for x in col) for col in zip(headers, *rows)]
    line = lambda r: "  ".join(str(x).rjust(w) if i else str(x).ljust(w)
                               for i, (x, w) in enumerate(zip(r, widths)))
    print(line(headers))
    print("  ".join("-" * w for w in widths))
    for r in rows:
        print(line(r))


def main(paths):
    images = [load(p) for p in paths]

    print("\n=== Scan summary (unique CVEs; fixable in parentheses) ===\n")
    headers = ["image", "os", "size MB"] + SEVERITIES + ["total", "score"]
    rows = []
    for im in images:
        rows.append([f'{REPO}:{im["tag"]}', im["os"] + (" (EOL)" if im["eosl"] else ""),
                     f'{im["size"]:.0f}' if im["size"] else "?"]
                    + [f'{im["counts"][s]} ({im["fixable"][s]})' for s in SEVERITIES]
                    + [f'{len(im["vulns"])} ({sum(im["fixable"].values())})', im["score"]])
    table(headers, rows)
    for im in images:
        if im["base"]:
            print(f'  {REPO}:{im["tag"]} built from {im["base"]}')

    print("\n=== Comparison ===\n")
    all_ids = [set(im["vulns"]) for im in images]
    shared = set.intersection(*all_ids) if all_ids else set()
    print(f"CVEs present in every image: {len(shared)}")
    for im, ids in zip(images, all_ids):
        only = ids - set().union(*(o for o in all_ids if o is not ids))
        sev = {s: 0 for s in SEVERITIES}
        for vid in only:
            sev[im["vulns"][vid]["severity"]] += 1
        detail = ", ".join(f"{s}={n}" for s, n in sev.items() if n)
        print(f'Only in {REPO}:{im["tag"]}: {len(only)}' + (f"  [{detail}]" if detail else ""))
        top = sorted((vid for vid in only if im["vulns"][vid]["severity"] in ("CRITICAL", "HIGH")),
                     key=lambda vid: SEVERITIES.index(im["vulns"][vid]["severity"]))[:10]
        for vid in top:
            v = im["vulns"][vid]
            print(f'    {vid:<20} {v["severity"]:<8} {"fixable" if v["fixable"] else "no fix":<8} '
                  f'{", ".join(sorted(v["pkgs"]))}')

    print("\n=== Recommendation for Dockerfile.full ===\n")
    print("score = sum(weight x count) + sum(weight x fixable), weights "
          + ", ".join(f"{s}={w}" for s, w in WEIGHTS.items() if w) + "; lower is better\n")
    candidates = [im for im in images if not im["eosl"]] or images
    ranked = sorted(candidates, key=lambda im: (im["score"], im["counts"]["CRITICAL"],
                                                im["counts"]["HIGH"], len(im["vulns"])))
    best = ranked[0]
    for im in images:
        if im["eosl"]:
            print(f'{REPO}:{im["tag"]} is end-of-life; excluded from recommendation.')
    if len(ranked) > 1 and ranked[1]["score"] == best["score"]:
        print(f'Tie between {best["tag"]} and {ranked[1]["tag"]}; prefer the newer release '
              f"for its longer support window.")
    else:
        others = ", ".join(f'{im["tag"]}={im["score"]}' for im in ranked[1:])
        print(f'Recommended: {best["tag"]} (score {best["score"]}'
              + (f"; vs {others}" if others else "") + ")")
    current = os.path.realpath("Dockerfile.full")
    target = f'Dockerfile.full-{best["tag"]}'
    if os.path.exists(target):
        if os.path.basename(current) == target:
            print(f"Dockerfile.full already points to {target}; no change needed.")
        else:
            print(f"Dockerfile.full currently points to {os.path.basename(current)}. To switch:")
            print(f"    ln -sfn {target} Dockerfile.full")
    else:
        print(f"Note: {target} does not exist yet; create it before switching Dockerfile.full.")
    print()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1:])
