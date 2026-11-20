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

/// Checks one workflow file. [source] is the YAML text.
List<PolicyViolation> checkWorkflow(String fileName, String source) {
  throw UnimplementedError('checkWorkflow');
}
