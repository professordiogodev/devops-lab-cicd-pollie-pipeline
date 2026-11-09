"""Static checks on .github/workflows/ci.yml. Usage: workflow_lint.py <check>. Exit 0 = pass."""
import re
import sys

import yaml

raw = open(".github/workflows/ci.yml").read()
w = yaml.safe_load(raw)
on = w.get(True, w.get("on", {}))  # PyYAML reads the key `on` as True
jobs = w.get("jobs", {})
check = sys.argv[1]


def steps(j):
    return jobs[j].get("steps", [])


def uses_all():
    for j in jobs.values():
        for s in j.get("steps", []):
            if "uses" in s:
                yield s["uses"]


def find_job(word):
    return [k for k in jobs if word in k.lower() or word in str(jobs[k].get("name", "")).lower()]


def needs(j):
    n = jobs[j].get("needs", [])
    return [n] if isinstance(n, str) else list(n)


if check == "triggers":
    ev = on if isinstance(on, dict) else {k: None for k in (on if isinstance(on, list) else [on])}
    push = ev.get("push")
    ok = "pull_request" in ev and "push" in ev and (push is None or "main" in str((push or {}).get("branches", ["main"])))
elif check == "permissions":
    p = w.get("permissions")
    ok = p is not None and p != "write-all" and (isinstance(p, dict) and all(v in ("read", "none") for v in p.values()) or p == "read-all")
elif check == "pins":
    ok = not any(re.search(r"@(main|master|latest)$", u) for u in uses_all())
elif check == "concurrency":
    c = w.get("concurrency")
    ok = bool(c) and (not isinstance(c, dict) or str(c.get("cancel-in-progress", "")).lower() == "true")
elif check == "services":
    t = find_job("test")
    ok = False
    for k in t:
        s = jobs[k].get("services", {})
        if len(s) >= 2:
            txt = str(s).lower()
            ok = "postgres" in txt and "redis" in txt and "health-cmd" in txt
elif check == "cache":
    ok = bool(re.search(r"cache:\s*pip|actions/cache@|cache-from|cache-to", raw))
elif check == "build":
    ok = "docker/build-push-action" in raw or re.search(r"docker (buildx )?build", raw) is not None
elif check == "scan":
    ok = bool(re.search(r"trivy", raw, re.I)) and bool(re.search(r"exit-code:\s*[\"']?1|--exit-code[ =]1", raw))
elif check == "publish":
    p = find_job("publish")
    ok = bool(p)
    for k in p:
        j = jobs[k]
        perm = j.get("permissions", {})
        ok = ok and "main" in str(j.get("if", "")) and isinstance(perm, dict) and perm.get("packages") == "write"
    top = w.get("permissions", {})
    ok = ok and not (isinstance(top, dict) and top.get("packages") == "write")
elif check == "chain":
    names = {w_: find_job(w_) for w_ in ["lint", "test", "build", "scan", "publish"]}
    ok = all(names.values())
    if ok:
        b, s, p = names["build"][0], names["scan"][0], names["publish"][0]
        ok = bool(needs(b)) and bool(needs(s)) and bool(needs(p))
else:
    ok = False
sys.exit(0 if ok else 1)
