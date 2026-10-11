/// Restore the broader product with --dart-define=SUBJECTS_ONLY=false.
/// Its screens, repositories and routes remain in the codebase.
const subjectsOnly = bool.fromEnvironment('SUBJECTS_ONLY', defaultValue: true);

bool isSubjectRoute(String path) => const {
  '/learn',
  '/setup',
  '/settings',
  '/skills/lesson',
  '/skills/practice',
  '/skills/marathon',
  '/skills/mock',
  '/skills/profile',
  '/skills/leaderboard',
  '/skills/achievements',
}.contains(path);
