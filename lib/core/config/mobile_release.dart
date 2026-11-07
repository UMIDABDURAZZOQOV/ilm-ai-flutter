import 'integrated_beta.dart';

/// Re-enable additional reviewed subjects only in the isolated integrated beta.
const biologyOnly = !reviewedMobileRelease && bool.fromEnvironment('BIOLOGY_ONLY', defaultValue: true);

bool isPublishedMobileSubject(String? slug) => reviewedLearning
    ? betaSubjectSlugs.contains(slug)
    : (!biologyOnly || slug == 'biologiya');
