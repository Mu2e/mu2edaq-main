#!/usr/bin/env python3
"""Aggregate .compat/status/{build,test}.tsv into a markdown report.

Usage: report.py <status_dir> <output.md>
"""
import os
import platform
import sys
from collections import OrderedDict
from datetime import datetime


def load(path):
    rows = []
    if os.path.exists(path):
        with open(path) as fh:
            for line in fh:
                parts = line.rstrip("\n").split("\t")
                if len(parts) >= 4:
                    rows.append(parts)  # pkg, step, status, log[, ts]
    return rows


def main():
    status_dir, out = sys.argv[1], sys.argv[2]
    build = load(os.path.join(status_dir, "build.tsv"))
    test = load(os.path.join(status_dir, "test.tsv"))

    pkgs = OrderedDict()
    for phase, rows in (("build", build), ("test", test)):
        for pkg, step, status, log, *_ in rows:
            pkgs.setdefault(pkg, []).append((phase, step, status, log))

    def overall(entries):
        statuses = [s for _, _, s, _ in entries]
        if "FAIL" in statuses:
            return "FAIL"
        if all(s == "SKIP" for s in statuses):
            return "SKIP"
        return "PASS"

    lines = []
    lines.append("# mu2edaq compatibility report")
    lines.append("")
    lines.append(
        "Generated %s on %s (%s, Python %s)"
        % (
            datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            platform.node(),
            " ".join(platform.linux_distribution()[:2])
            if hasattr(platform, "linux_distribution")
            else platform.platform(),
            platform.python_version(),
        )
    )
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append("| Package | Result | Failed steps |")
    lines.append("|---|---|---|")
    for pkg, entries in pkgs.items():
        res = overall(entries)
        fails = ", ".join("%s/%s" % (ph, st) for ph, st, s, _ in entries if s == "FAIL")
        icon = {"PASS": "PASS", "FAIL": "**FAIL**", "SKIP": "skip"}[res]
        lines.append("| %s | %s | %s |" % (pkg, icon, fails or "—"))
    lines.append("")

    fails = [
        (pkg, ph, st, log)
        for pkg, entries in pkgs.items()
        for ph, st, s, log in entries
        if s == "FAIL"
    ]
    if fails:
        lines.append("## Failure details")
        lines.append("")
        for pkg, phase, step, log in fails:
            lines.append("### %s — %s / %s" % (pkg, phase, step))
            lines.append("")
            lines.append("Log: `%s`" % log)
            if log != "-" and os.path.exists(log):
                with open(log, errors="replace") as fh:
                    tail = fh.readlines()[-30:]
                lines.append("")
                lines.append("```")
                lines.extend(l.rstrip("\n") for l in tail)
                lines.append("```")
            lines.append("")

    with open(out, "w") as fh:
        fh.write("\n".join(lines) + "\n")
    print("wrote %s (%d packages, %d failing steps)" % (out, len(pkgs), len(fails)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
