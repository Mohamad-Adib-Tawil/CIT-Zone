#!/usr/bin/env python3
"""Verify committed OR untracked generated Dart files without relying on Git.

Run after pub get. Uses the project's FVM SDK locally; CI already selects .fvmrc.
A mismatch fails and leaves regenerated output available for review.
"""
import argparse
import hashlib
from pathlib import Path
import subprocess
import sys


def snapshot():
    files = set(Path('lib').rglob('*.g.dart'))
    files.update(Path('lib').rglob('*.freezed.dart'))
    files.update(Path('lib/core/localization/generated').glob('*.dart'))
    return {str(path): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in sorted(files)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--no-fvm', action='store_true')
    args = parser.parse_args()
    before = snapshot()
    prefix = [] if args.no_fvm else ['fvm']
    for command in [prefix + ['flutter', 'gen-l10n'],
                    prefix + ['dart', 'run', 'build_runner', 'build']]:
        subprocess.run(command, check=True)
    after = snapshot()
    changed = [path for path in sorted(before.keys() | after.keys())
               if before.get(path) != after.get(path)]
    if changed:
        print('Generated output differs; regenerate and review:', *changed,
              sep='\n', file=sys.stderr)
        return 1
    print(f'Generated output reproducible: {len(after)} files.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
