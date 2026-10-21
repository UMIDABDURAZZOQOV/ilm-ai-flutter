/// Re-enable additional reviewed subjects with a coordinated backend release.
const biologyOnly = bool.fromEnvironment('BIOLOGY_ONLY', defaultValue: true);

bool isPublishedMobileSubject(String? slug) =>
    !biologyOnly || slug == 'biologiya';
