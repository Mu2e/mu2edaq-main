#!/usr/bin/env python3
"""Import every dependency declared in a requirements.txt inside the current
interpreter (expected to be the package venv). Exit nonzero if any fail.

Usage: python smoke_imports.py <requirements.txt> [extra_module ...]
"""
import importlib
import re
import sys

# distribution name -> importable module (only where they differ)
DIST_TO_MODULE = {
    "pyyaml": "yaml",
    "pyqt5": "PyQt5.QtCore",
    "pyqt6": "PyQt6.QtCore",
    "pyqt6-webengine": "PyQt6.QtWebEngineCore",
    "pyside6": "PySide6.QtCore",
    "pyzmq": "zmq",
    "flask-socketio": "flask_socketio",
    "sqlalchemy": "sqlalchemy",
    "python3-saml": "onelogin.saml2.auth",
    "django": "django",
    "django-allauth": "allauth",
    "python-dotenv": "dotenv",
    "psycopg2-binary": "psycopg2",
    "ruamel.yaml": "ruamel.yaml",
    "uvicorn[standard]": "uvicorn",
    "backports.zoneinfo": None,  # only needed on <3.9; never on our baselines
}


def module_for(req_line):
    """Map one requirement line to a module name, or None to skip."""
    line = req_line.split("#", 1)[0].strip()
    if not line or line.startswith("-"):
        return None
    # environment markers: respect a "python_version < X" style marker crudely
    if ";" in line:
        spec, marker = line.split(";", 1)
        try:
            if not eval(  # noqa: S307 - marker comes from repo-controlled file
                marker.strip()
                .replace("python_version", repr("%d.%d" % sys.version_info[:2]))
            ):
                return None
        except Exception:
            pass
        line = spec
    dist = re.split(r"[<>=!~\s]", line.strip(), 1)[0].strip()
    if not dist:
        return None
    key = dist.lower()
    if key in DIST_TO_MODULE:
        return DIST_TO_MODULE[key]
    return dist.replace("-", "_")


def main():
    reqs = sys.argv[1]
    extra = sys.argv[2:]
    failures = []
    targets = []
    with open(reqs) as fh:
        for line in fh:
            mod = module_for(line)
            if mod:
                targets.append(mod)
    targets.extend(extra)
    for mod in targets:
        try:
            importlib.import_module(mod)
            print("import %-30s OK" % mod)
        except Exception as exc:  # noqa: BLE001 - report everything
            print("import %-30s FAIL: %s: %s" % (mod, type(exc).__name__, exc))
            failures.append(mod)
    if failures:
        print("FAILED imports: %s" % ", ".join(failures))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
