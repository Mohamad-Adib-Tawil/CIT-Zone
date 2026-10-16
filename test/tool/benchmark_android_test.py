import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch
import zipfile

spec = importlib.util.spec_from_file_location('benchmark', 'tool/benchmark_android.py')
benchmark = importlib.util.module_from_spec(spec)
spec.loader.exec_module(benchmark)

COLD = 'Status: ok\nLaunchState: COLD\nTotalTime: 472\nWaitTime: 491\n'


class BenchmarkTest(unittest.TestCase):
    def test_launch_android_24_and_current(self):
        self.assertEqual(benchmark.parse_launch(COLD)['TotalTime'], 472)
        self.assertEqual(benchmark.parse_launch(COLD.replace('LaunchState: COLD\n', ''))['WaitTime'], 491)

    def test_failed_warm_or_missing_launch_is_not_a_zero_sample(self):
        for output in ['Status: timeout', COLD.replace('COLD', 'WARM'),
                       COLD + 'Warning: Activity not started',
                       COLD.replace('TotalTime: 472', 'TotalTime: 0'),
                       COLD.replace('WaitTime: 491', '')]:
            with self.subTest(output=output), self.assertRaises(benchmark.MeasurementError):
                benchmark.parse_launch(output)

    def test_pss_handles_both_android_formats_in_kib(self):
        self.assertEqual(benchmark.parse_pss('TOTAL PSS: 175000 TOTAL RSS: 210000'), 175000)
        self.assertEqual(benchmark.parse_pss('  TOTAL   175000  11000  24000  0'), 175000)

    def test_dead_or_missing_process_pss_is_rejected(self):
        for output in ['No process found', 'TOTAL PSS: 0', 'TOTAL RSS: 12000']:
            with self.subTest(output=output), self.assertRaises(benchmark.MeasurementError):
                benchmark.parse_pss(output)

    def test_statistics_use_nearest_rank_p95_and_keep_sample_count(self):
        self.assertEqual(benchmark.summarize(list(range(20, 0, -1))),
                         {'count': 20, 'median': 10.5, 'p95_nearest_rank': 19})
        with self.assertRaises(benchmark.MeasurementError):
            benchmark.summarize([])

    def test_reference_requirements_cannot_silently_accept_debug_or_emulator(self):
        defaults = dict(diagnostic=False, mode='release', emulator=False, runs=10,
                        debuggable=False, kernel_blob=False)
        benchmark.validate_run(**defaults)
        for changes in [dict(emulator=True), dict(mode='debug'), dict(runs=9),
                        dict(debuggable=True), dict(kernel_blob=True), dict(runs=31)]:
            with self.subTest(changes=changes), self.assertRaises(benchmark.MeasurementError):
                benchmark.validate_run(**(defaults | changes))
        benchmark.validate_run(**(defaults | dict(diagnostic=True, emulator=True, mode='debug', runs=3, debuggable=True, kernel_blob=True)))
        with self.assertRaises(benchmark.MeasurementError):
            benchmark.validate_run(**(defaults | dict(mode='profile', kernel_blob=True)))

    def test_interrupted_collection_preserves_partial_samples_without_success_summary(self):
        with tempfile.TemporaryDirectory() as folder:
            apk = Path(folder) / 'sample.apk'
            with zipfile.ZipFile(apk, 'w') as archive:
                archive.writestr('AndroidManifest.xml', 'fixture')
            output = Path(folder) / 'report.json'
            args = SimpleNamespace(package='com.example.test', apk=apk, adb='adb',
                                   serial='emulator-fixture', mode='debug', diagnostic=True,
                                   runs=2, settle_seconds=1, network='offline fixture', output=output)

            class FakeAdb:
                starts = 0

                def shell(self, *command, **kwargs):
                    if command == ('pm', 'path', args.package):
                        return 'package:/fixture/base.apk'
                    if command[0] == 'sha256sum':
                        return benchmark.digest(apk) + '  /fixture/base.apk'
                    if command[:2] == ('cmd', 'package'):
                        return 'com.example.test/.MainActivity'
                    if command == ('cat', '/proc/meminfo'):
                        return 'MemTotal: 2000000 kB'
                    if command[:2] == ('am', 'start'):
                        self.starts += 1
                        return COLD if self.starts == 1 else 'Status: timeout'
                    if command[:2] == ('dumpsys', 'meminfo'):
                        return 'TOTAL PSS: 175000'
                    return ''

            with patch.object(benchmark, 'Adb', return_value=FakeAdb()), \
                    patch.object(benchmark.time, 'sleep'), \
                    patch.object(benchmark.subprocess, 'run', return_value=SimpleNamespace(stdout='', returncode=0)):
                with self.assertRaises(benchmark.MeasurementError):
                    benchmark.collect(args)
            report = json.loads(output.read_text())
            self.assertFalse(report['completed'])
            self.assertFalse(report['acceptance_proven'])
            self.assertEqual(len(report['samples']), 1)
            self.assertNotIn('summary', report)
            self.assertEqual(report['classification'], 'diagnostic_only')


if __name__ == '__main__':
    unittest.main()
