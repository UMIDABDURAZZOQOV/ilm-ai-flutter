/// Ported from ilm-ai-mobile's src/data/colleges.ts College type. The richer
/// fields (aka, professors, gpa, etc.) only come from the curated dataset --
/// bundled-JSON-only entries leave them null, matching the RN app.
class Professor {
  final String name;
  final String field;
  final String? note;
  Professor({required this.name, required this.field, this.note});
  factory Professor.fromJson(Map<String, dynamic> json) => Professor(
        name: json['name'] as String? ?? '',
        field: json['field'] as String? ?? '',
        note: json['note'] as String?,
      );
}

class College {
  final String id;
  final String name;
  final String? aka;
  final String city;
  final String state;
  final String country;
  final String region; // 'US' | 'EU'
  final String type;
  final String? setting;
  final double? acceptanceRate;
  final int? medianSAT;
  final int? medianACT;
  final double? yieldRate;
  final String? gpa;
  final String? testPolicy;
  final String? size;
  final String? website;
  final int? nobelAffiliated;
  final List<Professor> professors;

  College({
    required this.id,
    required this.name,
    this.aka,
    required this.city,
    required this.state,
    required this.country,
    required this.region,
    required this.type,
    this.setting,
    this.acceptanceRate,
    this.medianSAT,
    this.medianACT,
    this.yieldRate,
    this.gpa,
    this.testPolicy,
    this.size,
    this.website,
    this.nobelAffiliated,
    this.professors = const [],
  });

  factory College.fromJson(Map<String, dynamic> json) => College(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        aka: json['aka'] as String?,
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
        country: json['country'] as String? ?? 'United States',
        region: json['region'] as String? ?? 'US',
        type: json['type'] as String? ?? '',
        setting: json['setting'] as String?,
        acceptanceRate: (json['acceptanceRate'] as num?)?.toDouble(),
        medianSAT: (json['medianSAT'] as num?)?.toInt(),
        medianACT: (json['medianACT'] as num?)?.toInt(),
        yieldRate: (json['yieldRate'] as num?)?.toDouble(),
        gpa: json['gpa']?.toString(),
        testPolicy: json['testPolicy'] as String?,
        size: json['size']?.toString(),
        website: json['website'] as String?,
        nobelAffiliated: (json['nobelAffiliated'] as num?)?.toInt(),
        professors: (json['professors'] as List? ?? []).map((e) => Professor.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// Ported from ilm-ai-mobile's data/colleges.ts collegeLogo() -- derives a
/// favicon URL from the college's own domain via DuckDuckGo's icon proxy.
/// Returns null if the website URL can't be parsed (caller falls back to
/// the initials badge, same as RN's CollegeLogo component).
String? collegeLogoUrl(College c) {
  final site = c.website;
  if (site == null || site.isEmpty) return null;
  try {
    var host = Uri.parse(site).host;
    if (host.isEmpty) return null;
    if (host.startsWith('www.')) host = host.substring(4);
    return 'https://icons.duckduckgo.com/ip3/$host.ico';
  } catch (_) {
    return null;
  }
}

String collegeInitials(String name) {
  final stripped = name.replaceFirst(RegExp(r'^The '), '');
  final words = stripped.trim().split(RegExp(r'\s+'));
  return words.take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
}
