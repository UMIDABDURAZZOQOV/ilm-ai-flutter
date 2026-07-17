class DailyPlan {
  final int day;
  final String topic;
  final String material;
  final List<String> tasks;
  final int durationMinutes;

  DailyPlan({required this.day, required this.topic, required this.material, required this.tasks, required this.durationMinutes});

  factory DailyPlan.fromJson(Map<String, dynamic> json) => DailyPlan(
        day: json['day'] as int? ?? 0,
        topic: json['topic'] as String? ?? '',
        material: json['material'] as String? ?? '',
        tasks: (json['tasks'] as List? ?? []).map((e) => e.toString()).toList(),
        durationMinutes: json['duration_minutes'] as int? ?? 0,
      );
}

class WeekPlan {
  final int week;
  final String focus;
  final List<DailyPlan> days;

  WeekPlan({required this.week, required this.focus, required this.days});

  factory WeekPlan.fromJson(Map<String, dynamic> json) => WeekPlan(
        week: json['week'] as int? ?? 0,
        focus: json['focus'] as String? ?? '',
        days: (json['days'] as List? ?? []).map((e) => DailyPlan.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class LearningPlan {
  final String goal;
  final String targetDate;
  final int daysAvailable;
  final double dailyHours;
  final String summary;
  final List<WeekPlan> weeklyBreakdown;
  final List<String> tips;
  final String? error;

  LearningPlan({
    required this.goal,
    required this.targetDate,
    required this.daysAvailable,
    required this.dailyHours,
    required this.summary,
    required this.weeklyBreakdown,
    required this.tips,
    this.error,
  });

  factory LearningPlan.fromJson(Map<String, dynamic> json) => LearningPlan(
        goal: json['goal'] as String? ?? '',
        targetDate: json['target_date'] as String? ?? '',
        daysAvailable: json['days_available'] as int? ?? 0,
        dailyHours: (json['daily_hours'] as num?)?.toDouble() ?? 0,
        summary: json['summary'] as String? ?? '',
        weeklyBreakdown: (json['weekly_breakdown'] as List? ?? []).map((e) => WeekPlan.fromJson(e as Map<String, dynamic>)).toList(),
        tips: (json['tips'] as List? ?? []).map((e) => e.toString()).toList(),
        error: json['error'] as String?,
      );
}

class TodayPlanResponse {
  final String status; // 'today' | 'no_plan' | 'finished'
  final DailyPlan? day;
  final int daysElapsed;
  final int daysTotal;

  TodayPlanResponse({required this.status, this.day, required this.daysElapsed, required this.daysTotal});

  factory TodayPlanResponse.fromJson(Map<String, dynamic> json) => TodayPlanResponse(
        status: json['status'] as String? ?? 'no_plan',
        day: json['day'] != null ? DailyPlan.fromJson(json['day'] as Map<String, dynamic>) : null,
        daysElapsed: json['days_elapsed'] as int? ?? 0,
        daysTotal: json['days_total'] as int? ?? 0,
      );
}
