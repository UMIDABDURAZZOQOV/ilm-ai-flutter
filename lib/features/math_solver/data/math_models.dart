class MathSolutionStep {
  final String expression;
  final String explanation;
  MathSolutionStep({required this.expression, required this.explanation});
  factory MathSolutionStep.fromJson(Map<String, dynamic> json) => MathSolutionStep(
        expression: json['expression'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
      );
}

class MathGraph {
  final String type; // 'linear' | 'quadratic'
  final double a;
  final double b;
  final double? c;
  MathGraph({required this.type, required this.a, required this.b, this.c});
  factory MathGraph.fromJson(Map<String, dynamic> json) => MathGraph(
        type: json['type'] as String? ?? 'linear',
        a: (json['a'] as num?)?.toDouble() ?? 0,
        b: (json['b'] as num?)?.toDouble() ?? 0,
        c: (json['c'] as num?)?.toDouble(),
      );

  double evaluate(double x) => type == 'quadratic' ? (a * x * x + b * x + (c ?? 0)) : (a * x + b);
}

class MathSolveResult {
  final String recognizedProblem;
  final String topic;
  final List<MathSolutionStep> steps;
  final String finalAnswer;
  final MathGraph? graph;

  MathSolveResult({
    required this.recognizedProblem,
    required this.topic,
    required this.steps,
    required this.finalAnswer,
    this.graph,
  });

  factory MathSolveResult.fromJson(Map<String, dynamic> json) => MathSolveResult(
        recognizedProblem: json['recognized_problem'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
        steps: (json['steps'] as List? ?? []).map((e) => MathSolutionStep.fromJson(e as Map<String, dynamic>)).toList(),
        finalAnswer: json['final_answer'] as String? ?? '',
        graph: json['graph'] != null ? MathGraph.fromJson(json['graph'] as Map<String, dynamic>) : null,
      );
}
