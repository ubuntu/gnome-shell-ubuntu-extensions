#!/usr/bin/env python3

import glob
import json
import os
import sys
import argparse

EXTENSIONS_PATH = "usr/share/gnome-shell/extensions/*/metadata.json"

class UnsupportedShellVersionError(Exception):
    pass

def compute_shell_versions(package_name, needs_version):
    pattern = os.path.join(os.path.curdir, "debian", package_name, EXTENSIONS_PATH)
    matches = sorted(glob.glob(pattern, recursive=False))
    if not matches:
        print(f"No files matched pattern: {pattern}", file=sys.stderr)
        sys.exit(1)

    max_version = sys.maxsize
    min_version = 0

    for fname in matches:
        with open(fname, 'rt', encoding='utf-8') as f:
            versions = [int(v) for v in json.load(f)['shell-version']]

            if needs_version and needs_version not in versions:
                raise UnsupportedShellVersionError(
                    f"{fname} does not support shell version {needs_version}")

            max_version = min(max_version, max(versions))
            min_version = max(min(versions), min_version)

    assert min_version != 0
    assert max_version != sys.maxsize

    return (
        min_version,
        max_version,
    )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("package_name")
    ap.add_argument('--min-version', action='store_true')
    ap.add_argument('--max-version', action='store_true')
    ap.add_argument('--must-support', type=int)
    args = ap.parse_args()

    if not args.min_version and not args.max_version and not args.must_support:
        raise argparse.ArgumentError(None, "No valid option specified")

    (min_version, max_version) = compute_shell_versions(args.package_name,
                                                        args.must_support)

    if args.min_version:
        print(min_version)
    if args.max_version:
        print(max_version + 1)


if __name__ == "__main__":
    main()
