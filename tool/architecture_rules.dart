import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/utilities.dart';

/// Checks actual Dart directives, including exports, parts and every conditional
/// branch. Paths in [sources] are repository-relative (lib/...).
List<String> architectureViolations(Map<String, String> sources) {
  final graph = <String, List<String>>{};
  for (final entry in sources.entries) {
    final unit = parseString(
      content: entry.value,
      throwIfDiagnostics: false,
    ).unit;
    final edges = <String>[];
    for (final directive in unit.directives) {
      if (directive is UriBasedDirective) {
        final uri = directive.uri.stringValue;
        if (uri != null) edges.add(uri);
      }
      if (directive is NamespaceDirective) {
        for (final configuration in directive.configurations) {
          final uri = configuration.uri.stringValue;
          if (uri != null) edges.add(uri);
        }
      }
    }
    graph[entry.key] = edges;
  }

  final violations = <String>{};
  for (final root in sources.keys.where((path) => !path.endsWith('.g.dart'))) {
    final domain =
        root.startsWith('lib/features/') && root.contains('/domain/');
    final presentation =
        root.startsWith('lib/features/') && root.contains('/presentation/');
    final data = root.startsWith('lib/features/') && root.contains('/data/');
    final core = root.startsWith('lib/core/');
    final visited = <String>{};

    void visit(String file, List<String> trail) {
      if (!visited.add(file)) return;
      for (final uri in graph[file] ?? <String>[]) {
        String? reason;
        final target = _localTarget(file, uri);
        if (target != null) {
          if (!sources.containsKey(target)) {
            reason = 'missing local dependency';
          } else if (domain && !_domainFile(target)) {
            reason = 'domain depends on an outer layer';
          } else if (presentation &&
              (target.contains('/data/') ||
                  target.startsWith('lib/app/di/') ||
                  _infrastructureFile(target))) {
            reason = 'presentation bypasses a repository/constructor boundary';
          } else if (data &&
              (target.contains('/presentation/') ||
                  target.startsWith('lib/app/'))) {
            reason = 'data depends on presentation/composition';
          } else if (core &&
              (target.startsWith('lib/features/') ||
                  target.startsWith('lib/app/'))) {
            reason = 'core depends on a feature/composition';
          }
        } else if (domain && !_pureDomainLibrary(uri)) {
          reason = 'domain imports a platform or unapproved library';
        } else if (presentation && _infrastructureLibrary(uri)) {
          reason = 'presentation imports an infrastructure SDK';
        }
        if (uri.startsWith('package:get_it/') &&
            !file.startsWith('lib/app/di/')) {
          reason = 'service locator is restricted to the composition root';
        }
        final next = [...trail, target ?? uri];
        if (reason != null) {
          violations.add('$reason: ${next.join(' -> ')}');
        } else if (target != null) {
          visit(target, next);
        }
      }
    }

    visit(root, [root]);
  }
  return violations.toList()..sort();
}

String? _localTarget(String source, String dependency) {
  const prefix = 'package:cit_zone/';
  if (dependency.startsWith(prefix)) {
    return Uri.parse('file:///lib/')
        .resolve(dependency.substring(prefix.length))
        .path
        .substring(1);
  }
  if (Uri.parse(dependency).hasScheme) return null;
  return Uri.parse('file:///$source').resolve(dependency).path.substring(1);
}

bool _domainFile(String path) =>
    (path.startsWith('lib/features/') && path.contains('/domain/')) ||
    path.startsWith('lib/core/errors/') ||
    path.startsWith('lib/core/media/');

bool _pureDomainLibrary(String uri) => const {
  'dart:core',
  'dart:async',
  'dart:collection',
  'dart:convert',
  'dart:math',
  'dart:typed_data',
  'package:meta/meta.dart',
}.contains(uri);

bool _infrastructureFile(String path) => const [
  'lib/core/network/',
  'lib/core/storage/',
  'lib/core/security/',
].any(path.startsWith);

bool _infrastructureLibrary(String uri) =>
    const [
      'dio',
      'drift',
      'drift_flutter',
      'flutter_secure_storage',
      'google_sign_in',
      'get_it',
      'http',
      'sqflite',
      'shared_preferences',
    ].any((package) => uri.startsWith('package:$package/')) ||
    const {'dart:io', 'dart:ffi', 'dart:html', 'dart:js_interop'}.contains(uri);

Map<String, String> readArchitectureSources(Directory directory) => {
  for (final file in directory.listSync(recursive: true).whereType<File>())
    if (file.path.endsWith('.dart'))
      file.path.replaceAll('\\', '/'): file.readAsStringSync(),
};

void main() {
  final violations = architectureViolations(
    readArchitectureSources(Directory('lib')),
  );
  if (violations.isNotEmpty) {
    stderr.writeln(violations.join('\n'));
    exitCode = 1;
  } else {
    stdout.writeln('Architecture boundaries passed.');
  }
}
