#!/usr/bin/env python3

import configparser
import glob
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

SHA1_RE = re.compile(r'^[0-9a-f]{7,40}$', re.I)


def ls_remote_tags(url):
    out = subprocess.check_output(['git', 'ls-remote', '--tags', url],
                                  stderr=subprocess.DEVNULL, timeout=30)
    tags = set()
    for line in out.splitlines():
        parts = line.decode('utf-8').split('\t', 1)
        if len(parts) != 2:
            continue
        _, ref = parts
        if not ref.startswith('refs/tags/'):
            continue
        # Annotated tags end with ^{}
        if ref.endswith('^{}'):
            tags.add(ref[len('refs/tags/'):-3])
        else:
            tags.add(ref[len('refs/tags/'):])
    return tags


def validate_wrap_file(path):
    cfg = configparser.ConfigParser()
    cfg.read(path)
    if 'wrap-git' not in cfg:
        return False, [f'{path}: not a wrap-git file']

    section = cfg['wrap-git']
    url = section.get('url')
    if not url:
        return False, [f'{path}: missing url']

    rev = section.get('revision')
    if not rev:
        return False, [f'{path}: missing revision']

    if SHA1_RE.match(rev):
        return True, []

    tags = ls_remote_tags(url)

    if tags is None:
        return False, [f'{path}: failed to query remote {url}']

    if rev not in tags:
        return False, [f'{path}: revision "{rev}" not found among tags in remote ' +
                       f'{url} (available tags: {sorted(list(tags))[:10]}...). ' +
                       'Note: branch names are not accepted.']

    return True, []


def main():
    repo_root = Path(__file__).resolve().parents[1]
    pattern = repo_root / 'subprojects' / '*.wrap'
    files = sorted(glob.glob(str(pattern)))
    if not files:
        print('No .wrap files found', file=sys.stderr)
        sys.exit(2)

    failures = []
    ok_files = []

    with ThreadPoolExecutor(max_workers=8) as exc:
        future_to_file = {exc.submit(validate_wrap_file, f): f for f in files}
        for fut in as_completed(future_to_file):
            f = future_to_file[fut]
            try:
                ok, errs = fut.result()
            except Exception as e:
                failures.append(f'{f}: exception during validation: {e}')
                continue
            if not ok:
                failures.extend(errs)
            else:
                ok_files.append(f)

    for f in sorted(ok_files):
        print(f'OK: {f}')

    print()
    if failures:
        print('Failures:')
        for e in failures:
            print(' -', e)
        sys.exit(1)

    print('All revisions valid')


if __name__ == '__main__':
    main()
