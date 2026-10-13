#!/usr/bin/env python3
"""Check the frozen G18 wireless build inputs; never regenerate the lock."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
LOCK = "config/g18-wifi-lock.json"


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", help="Read the trusted lock from this Git revision")
    parser.add_argument("--index", action="store_true", help="Check staged files")
    args = parser.parse_args()
    try:
        raw = git("show", f"{args.baseline}:{LOCK}") if args.baseline else (ROOT / LOCK).read_bytes()
        lock = json.loads(raw)
        errors = []
        for name, expected in lock["sha256"].items():
            try:
                data = git("show", f":{name}") if args.index else (ROOT / name).read_bytes()
                if hashlib.sha256(data).hexdigest() != expected:
                    errors.append(f"changed: {name}")
            except (OSError, subprocess.CalledProcessError):
                errors.append(f"missing: {name}")
        # New patches/build inputs must not silently alter the frozen packages.
        names = set(git("ls-files", "--", *lock["directories"]).decode().splitlines())
        if not args.index:
            for directory in lock["directories"]:
                names.update(str(p.relative_to(ROOT)) for p in (ROOT / directory).rglob("*") if p.is_file())
        for name in sorted(names - set(lock["sha256"])):
            errors.append(f"new protected file: {name}")
        if args.baseline:
            current = git("show", f":{LOCK}") if args.index else (ROOT / LOCK).read_bytes()
            if current != raw:
                errors.append("wireless lock itself was changed")
        if errors:
            print("G18 MT7615E protection: FAILED\n" + "\n".join(errors), file=sys.stderr)
            return 1
        print("G18 MT7615E protection: OK")
        return 0
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"G18 MT7615E protection: cannot verify: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
