class ProblemSourceModel {
  final String unitType;
  final List<Problem> problems;

  ProblemSourceModel({
    required this.unitType,
    required this.problems,
  });

  factory ProblemSourceModel.fromJson(Map<String, dynamic> json) {
    return ProblemSourceModel(
      unitType: json['unit_type'],
      problems: (json['problems'] as List)
          .map((e) => Problem.fromJson(e))
          .toList(),
    );
  }
}

class Problem {
  final String causeId;
  final String causeName;
  final List<Solution> solutions;

  Problem({
    required this.causeId,
    required this.causeName,
    required this.solutions,
  });

  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      causeId: json['cause_id'],
      causeName: json['cause_name'],
      solutions: (json['solutions'] as List)
          .map((e) => Solution.fromJson(e))
          .toList(),
    );
  }
}

class Solution {
  final String solutionId;
  final String solutionName;
  final String ahoFlag;

  Solution({
    required this.solutionId,
    required this.solutionName,
    required this.ahoFlag,
  });

  factory Solution.fromJson(Map<String, dynamic> json) {
    return Solution(
      solutionId: json['solution_id'],
      solutionName: json['solution_name'],
      ahoFlag: json['aho_flag'],
    );
  }
}
