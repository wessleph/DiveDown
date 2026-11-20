/// CI rules for this public repo (security.md G6/A3), checked by
/// `test/tool/workflow_policy_test.dart` against every file in
/// `.github/workflows/`.
///
/// W1 every `uses:` is local or pinned to a 40-character commit SHA
/// W2 no `pull_request_target`, no `workflow_run`
/// W3 top-level `permissions:` present, never `write-all`
/// W4 `secrets.*` (other than GITHUB_TOKEN) only in jobs with
///    `environment: release`, and only in workflows without `pull_request`
/// W5 a job with `environment: release` is limited by `if:` to this repo and
///    to `refs/tags/v*` or `refs/heads/main`
/// W6 every `actions/checkout` sets `persist-credentials: false`
/// W7 no `${{ github.event.* }}` or `${{ github.head_ref }}` inside `run:`
/// W8 no Flutter version written into a workflow; it comes from
///    `.github/flutter-version.txt`
/// W9 every job has `timeout-minutes` (reusable-workflow calls excepted)
library;

import 'package:yaml/yaml.dart';

class PolicyViolation {
  const PolicyViolation(this.rule, this.where, this.message);

  /// `W1` … `W9`.
  final String rule;

  /// `<file>:<job>` or `<file>`.
  final String where;
  final String message;

  @override
  String toString() => '$rule $where: $message';
}

/// The repository whose release job may sign (W5).
const releaseRepository = 'wessleph/DiveDown';

final _pinned = RegExp(r'^[^@\s]+@[0-9a-f]{40}$');
final _secret = RegExp(r'secrets\.([A-Za-z_][A-Za-z0-9_]*)');
final _injection = RegExp(r'\$\{\{[^}]*\b(github\.event\.|github\.head_ref)');
final _flutterBranch = RegExp(r'--branch\s+v?\d+\.\d+');

/// Checks one workflow file. [source] is the YAML text.
List<PolicyViolation> checkWorkflow(String fileName, String source) {
  final out = <PolicyViolation>[];
  void add(String rule, String where, String message) =>
      out.add(PolicyViolation(rule, where, message));

  final doc = loadYaml(source);
  if (doc is! YamlMap) {
    add('W3', fileName, 'not a workflow');
    return out;
  }

  // W2 and the pull request check for W4.
  final triggers = _triggers(doc['on']);
  for (final t in ['pull_request_target', 'workflow_run']) {
    if (triggers.contains(t)) add('W2', fileName, '$t is not allowed');
  }
  final pullRequests = triggers.contains('pull_request');

  // W3 at the top.
  final permissions = doc['permissions'];
  if (permissions == null) {
    add('W3', fileName, 'top-level permissions missing');
  } else if (permissions == 'write-all') {
    add('W3', fileName, 'permissions: write-all');
  }

  // W4: secrets outside jobs (workflow-level env).
  for (final name in _secretsIn(doc['env'])) {
    add('W4', fileName, 'secrets.$name in workflow-level env');
  }

  final jobs = doc['jobs'];
  if (jobs is! YamlMap) return out;
  for (final entry in jobs.entries) {
    final where = '$fileName:${entry.key}';
    final job = entry.value;
    if (job is! YamlMap) continue;

    if (job['permissions'] == 'write-all') {
      add('W3', where, 'permissions: write-all');
    }

    final environment = _environmentName(job['environment']);
    final secrets = _secretsIn(job).toSet();
    if (secrets.isNotEmpty) {
      if (environment != 'release') {
        add('W4', where, 'secrets ${secrets.join(', ')} outside release');
      }
      if (pullRequests) {
        add('W4', where, 'secrets in a workflow pull requests can trigger');
      }
    }

    if (environment == 'release') {
      final condition = job['if']?.toString() ?? '';
      final repoGuard = condition.contains(
        "github.repository == '$releaseRepository'",
      );
      final refGuard =
          condition.contains('refs/tags/v') ||
          condition.contains('refs/heads/main');
      if (!repoGuard || !refGuard) {
        add('W5', where, 'release job needs repository and ref guard in if:');
      }
    }

    final reusable = job['uses'];
    if (reusable != null) _checkUses(reusable.toString(), where, add);
    if (reusable == null && job['timeout-minutes'] == null) {
      add('W9', where, 'timeout-minutes missing');
    }

    final steps = job['steps'];
    if (steps is! YamlList) continue;
    for (final step in steps.whereType<YamlMap>()) {
      final uses = step['uses']?.toString();
      final withArgs = step['with'];
      if (uses != null) {
        _checkUses(uses, where, add);
        if (uses.startsWith('actions/checkout@')) {
          final persist = withArgs is YamlMap
              ? withArgs['persist-credentials']
              : null;
          if (persist != false && persist != 'false') {
            add('W6', where, 'checkout without persist-credentials: false');
          }
        }
      }
      if (withArgs is YamlMap) {
        final version = withArgs['flutter-version'];
        if (version != null && RegExp(r'^\d').hasMatch(version.toString())) {
          add('W8', where, 'Flutter version written into the workflow');
        }
      }
      final run = step['run']?.toString();
      if (run != null) {
        for (final _ in _injection.allMatches(run)) {
          add('W7', where, 'event data interpolated into run:');
        }
        if (run.contains('flutter') && _flutterBranch.hasMatch(run)) {
          add('W8', where, 'Flutter version written into the workflow');
        }
      }
    }
  }
  return out;
}

void _checkUses(
  String uses,
  String where,
  void Function(String, String, String) add,
) {
  if (uses.startsWith('./')) return;
  if (!_pinned.hasMatch(uses)) add('W1', where, '$uses is not pinned');
}

Set<String> _triggers(Object? on) => switch (on) {
  String s => {s},
  YamlList l => l.map((e) => e.toString()).toSet(),
  YamlMap m => m.keys.map((e) => e.toString()).toSet(),
  _ => {},
};

String? _environmentName(Object? environment) => switch (environment) {
  String s => s,
  YamlMap m => m['name']?.toString(),
  _ => null,
};

/// Secret names used anywhere below [node], GITHUB_TOKEN excluded.
Iterable<String> _secretsIn(Object? node) sync* {
  switch (node) {
    case String s:
      for (final m in _secret.allMatches(s)) {
        if (m.group(1) != 'GITHUB_TOKEN') yield m.group(1)!;
      }
    case YamlMap m:
      for (final e in m.entries) {
        yield* _secretsIn(e.key);
        yield* _secretsIn(e.value);
      }
    case YamlList l:
      for (final e in l) {
        yield* _secretsIn(e);
      }
  }
}
