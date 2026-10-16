#!/usr/bin/env python3
"""Measure Android Activity cold launch and entry-screen PSS, not Flutter TTI.

Explicitly force-stops the named package; never clears app data or installs APKs.
Debug/emulator runs require --diagnostic and cannot establish device acceptance.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import statistics
import subprocess
import sys
import time
from datetime import datetime, timezone
import zipfile


class MeasurementError(RuntimeError):
    pass


def parse_launch(output):
    if not re.search(r'^Status:\s*ok\s*$', output, re.M):
        raise MeasurementError('Activity launch did not report Status: ok')
    if re.search(r'Warning:|Error:|Activity not started', output, re.I):
        raise MeasurementError('Activity launch reported a warning/error')
    state = re.search(r'^LaunchState:\s*(\w+)', output, re.M)
    if state and state[1] != 'COLD':
        raise MeasurementError('Activity launch was not cold')
    values = {}
    for field in ['TotalTime', 'WaitTime']:
        match = re.search(rf'^{field}:\s*(\d+)\s*$', output, re.M)
        if not match or int(match[1]) <= 0:
            raise MeasurementError(f'Missing/invalid {field}')
        values[field] = int(match[1])
    return values


def parse_pss(output):
    match = re.search(r'TOTAL PSS:\s*(\d+)', output)
    if not match:
        match = re.search(r'^\s*TOTAL\s+(\d+)\s+', output, re.M)
    if not match or int(match[1]) <= 0:
        raise MeasurementError('No positive total process PSS in meminfo')
    # Android dumpsys reports KiB, not bytes.
    return int(match[1])


def summarize(values):
    if not values:
        raise MeasurementError('Cannot summarize an empty measurement')
    ordered = sorted(values)
    return {'count': len(values), 'median': statistics.median(values),
            'p95_nearest_rank': ordered[math.ceil(len(values) * .95) - 1]}


def validate_run(*, diagnostic, mode, emulator, runs, debuggable, kernel_blob):
    if not 1 <= runs <= 30:
        raise MeasurementError('Runs must be between 1 and 30')
    if mode == 'release' and (debuggable or kernel_blob):
        raise MeasurementError('Release label conflicts with the installed artifact')
    if mode == 'profile' and kernel_blob:
        raise MeasurementError('Profile label conflicts with a debug kernel artifact')
    if not diagnostic and (mode == 'debug' or emulator or runs < 10):
        raise MeasurementError('Reference runs require a physical device, profile/release and >=10 samples; use --diagnostic for development')


def digest(path):
    result = hashlib.sha256()
    with Path(path).open('rb') as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b''):
            result.update(chunk)
    return result.hexdigest()


class Adb:
    def __init__(self, executable, serial):
        self.command = [executable, '-s', serial]

    def shell(self, *args, allow_failure=False):
        result = subprocess.run(self.command + ['shell', *args], text=True,
                                capture_output=True, timeout=40)
        if result.returncode and not allow_failure:
            # Do not echo arbitrary shell output (may contain account data).
            raise MeasurementError(f'adb command failed: {args[0]}')
        return result.stdout.strip()


def collect(args):
    if not re.fullmatch(r'[A-Za-z][\w]*(?:\.[A-Za-z][\w]*)+', args.package):
        raise MeasurementError('Invalid Android package name')
    if not 1 <= args.settle_seconds <= 60:
        raise MeasurementError('Settle seconds must be between 1 and 60')
    if args.output.exists():
        raise MeasurementError('Output already exists; choose a new report path')
    with zipfile.ZipFile(args.apk) as archive:
        kernel = 'assets/flutter_assets/kernel_blob.bin' in archive.namelist()
    adb = Adb(args.adb, args.serial)
    prop = lambda key: adb.shell('getprop', key)
    emulator = args.serial.startswith('emulator-') or any(
        prop(key) == '1' for key in ['ro.kernel.qemu', 'ro.boot.qemu'])
    package_info = adb.shell('dumpsys', 'package', args.package)
    debuggable = bool(re.search(r'\bDEBUGGABLE\b', package_info))
    validate_run(diagnostic=args.diagnostic, mode=args.mode, emulator=emulator,
                 runs=args.runs, debuggable=debuggable, kernel_blob=kernel)
    paths = [line.removeprefix('package:') for line in
             adb.shell('pm', 'path', args.package).splitlines()
             if line.startswith('package:')]
    if len(paths) != 1:
        raise MeasurementError('Expected one installed APK; split installs need a separate artifact inventory')
    checksum = re.match(r'^([0-9a-f]{64})\s', adb.shell('sha256sum', paths[0]))
    if not checksum:
        raise MeasurementError('Could not verify installed APK checksum')
    installed_hash = checksum[1]
    if installed_hash != digest(args.apk):
        raise MeasurementError('Supplied APK does not match the installed artifact')
    resolved = adb.shell('cmd', 'package', 'resolve-activity', '--brief',
                         '-a', 'android.intent.action.MAIN', '-c',
                         'android.intent.category.LAUNCHER', args.package)
    components = [line for line in resolved.splitlines()
                  if re.fullmatch(re.escape(args.package) + r'/[\w.$]+', line)]
    if len(components) != 1:
        raise MeasurementError('Could not resolve a unique launcher Activity')
    meminfo = adb.shell('cat', '/proc/meminfo')
    memory = re.search(r'^MemTotal:\s+(\d+) kB', meminfo, re.M)
    if not memory:
        raise MeasurementError('Missing device RAM metadata')
    git = subprocess.run(['git', 'rev-parse', 'HEAD'], text=True,
                         capture_output=True, check=False)
    dirty = subprocess.run(['git', 'status', '--porcelain'], text=True,
                           capture_output=True, check=True)
    report = {
        'schema_version': 1, 'recorded_at_utc': datetime.now(timezone.utc).isoformat(),
        'classification': 'diagnostic_only' if args.diagnostic else 'reference_measurement_only',
        'acceptance_proven': False,
        'limitations': ['Activity TotalTime is not Flutter time-to-interactive.',
                       'Entry-screen PSS is not catalog/player/PDF memory.',
                       'No frame timings, iOS footprint, thermal trend or DRM proof.',
                       'Build mode is declared and checked for obvious conflicts, not attested.'],
        'device': {'serial_sha256': hashlib.sha256(args.serial.encode()).hexdigest(),
                   'model': prop('ro.product.model'), 'android_release': prop('ro.build.version.release'),
                   'api': prop('ro.build.version.sdk'), 'abi': prop('ro.product.cpu.abi'),
                   'emulator': emulator, 'ram_total_kib': int(memory[1]),
                   'display': adb.shell('wm', 'size'),
                   'low_power_setting': adb.shell('settings', 'get', 'global', 'low_power')},
        'build': {'package': args.package, 'mode_declared': args.mode,
                  'apk_sha256': installed_hash, 'apk_bytes': args.apk.stat().st_size,
                  'debuggable': debuggable, 'git_head': git.stdout.strip() or None,
                  'working_tree_dirty': bool(dirty.stdout),
                  'lock_sha256': digest('pubspec.lock'), 'fvmrc_sha256': digest('.fvmrc')},
        'scenario': {'activity': components[0], 'settle_seconds': args.settle_seconds,
                     'requested_runs': args.runs, 'network': args.network},
        'samples': [], 'completed': False,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)

    def save():
        args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n')

    # Keep partial samples if the device disconnects; never turn failures into zero.
    try:
        for index in range(args.runs):
            adb.shell('am', 'force-stop', args.package)
            if adb.shell('pidof', args.package, allow_failure=True):
                raise MeasurementError('App process survived force-stop')
            timings = parse_launch(adb.shell('am', 'start', '-W', '-n', components[0]))
            time.sleep(args.settle_seconds)
            pss = parse_pss(adb.shell('dumpsys', 'meminfo', args.package))
            report['samples'].append({'run': index + 1, 'activity_total_ms': timings['TotalTime'],
                                      'activity_wait_ms': timings['WaitTime'], 'entry_pss_kib': pss})
            save()
            print(f'Sample {index + 1}/{args.runs} captured.', flush=True)
        report['summary'] = {field: summarize([s[field] for s in report['samples']])
                             for field in ['activity_total_ms', 'activity_wait_ms', 'entry_pss_kib']}
        report['completed'] = True
    except (MeasurementError, subprocess.SubprocessError) as error:
        report['error'] = type(error).__name__
        raise
    finally:
        save()
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', default='adb')
    parser.add_argument('--serial', required=True)
    parser.add_argument('--package', required=True)
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--mode', choices=['release', 'profile', 'debug'], required=True)
    parser.add_argument('--diagnostic', action='store_true')
    parser.add_argument('--runs', type=int, default=10)
    parser.add_argument('--settle-seconds', type=int, default=5)
    parser.add_argument('--network', required=True, help='Describe actual network, including offline/uncontrolled')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        collect(args)
    except (MeasurementError, subprocess.SubprocessError, OSError, zipfile.BadZipFile) as error:
        # No raw dumps, account information or remote paths in diagnostics.
        print(f'Measurement failed ({type(error).__name__}): {error if isinstance(error, MeasurementError) else "inspect device/artifact availability"}', file=sys.stderr)
        return 1
    print(f'Report saved: {args.output}; no acceptance claim.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
