#!/usr/bin/env python3

import configparser
import shutil
import sys
import tempfile
from pathlib import Path


MESON_FILES = ('meson.build', 'meson.options', 'meson_options.txt')


def copy_path(source, destination):
    if source.is_dir():
        shutil.copytree(source, destination, symlinks=True)
    else:
        shutil.copy2(source, destination, follow_symlinks=False)


def filter_subproject(subprojects_dir, wrap_path):
    config = configparser.ConfigParser()
    config.read(wrap_path)
    section = config['wrap-git']
    subfolder = section.get('x_subfolder')
    if not subfolder:
        return

    subproject_dir = subprojects_dir / section['directory']
    source_dir = (subproject_dir / subfolder).resolve()
    print(
        f'Filtering {subproject_dir.name}: retaining {subfolder}',
        file=sys.stderr,
    )
    try:
        source_dir.relative_to(subproject_dir.resolve())
    except ValueError:
        raise ValueError(f'{wrap_path}: x_subfolder must be inside the subproject')

    if not source_dir.is_dir():
        raise FileNotFoundError(f'{wrap_path}: x_subfolder does not exist: {subfolder}')

    filtered_dir = Path(tempfile.mkdtemp(
        prefix=f'.{subproject_dir.name}-', dir=subproject_dir.parent))
    try:
        for source in source_dir.iterdir():
            copy_path(source, filtered_dir / source.name)

        # packagefiles may provide the root Meson build configuration.
        for filename in MESON_FILES:
            source = subproject_dir / filename
            if source.exists():
                copy_path(source, filtered_dir / filename)

        shutil.rmtree(subproject_dir)
        filtered_dir.rename(subproject_dir)
        print(f'Filtered {subproject_dir.name}', file=sys.stderr)
    except Exception:
        shutil.rmtree(filtered_dir, ignore_errors=True)
        raise


def main():
    subprojects_dir = Path.cwd() / 'subprojects'
    for wrap_path in sorted(subprojects_dir.glob('*.wrap')):
        try:
            filter_subproject(subprojects_dir, wrap_path)
        except (KeyError, ValueError, OSError) as error:
            print(error, file=sys.stderr)
            return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
