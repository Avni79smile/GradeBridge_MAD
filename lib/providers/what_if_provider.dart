import 'package:flutter/material.dart';

class WhatIfAnalysisProvider extends ChangeNotifier {
  // What-if calculation methods

  /// Calculate required score to reach target GPA
  double calculateRequiredScore({
    required double currentAverage,
    required double targetGPA,
    required double credit,
    required double outOf,
  }) {
    // Formula: requiredScore = (targetGPA * outOf / 10) - (currentAverage * (totalCredit - credit)) / credit
    try {
      if (credit == 0) return 0.0;

      final gradePoint = targetGPA;
      final requiredPercentage = (gradePoint / 10) * 100;
      final requiredScore = (requiredPercentage * outOf) / 100;

      return requiredScore > outOf ? outOf : requiredScore;
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate target GPA based on future marks
  double calculatePredictedGPA({
    required double currentCGPA,
    required double currentCredits,
    required double newMarks,
    required double newCredit,
    required double outOf,
  }) {
    try {
      final percentage = (newMarks / outOf) * 100;
      double newGradePoint = 0;

      if (percentage >= 90) {
        newGradePoint = 10;
      } else if (percentage >= 80) {
        newGradePoint = 9;
      } else if (percentage >= 70) {
        newGradePoint = 8;
      } else if (percentage >= 60) {
        newGradePoint = 7;
      } else if (percentage >= 50) {
        newGradePoint = 6;
      } else if (percentage >= 40) {
        newGradePoint = 5;
      } else if (percentage >= 30) {
        newGradePoint = 4;
      }

      final totalGradePoints =
          (currentCGPA * currentCredits) + (newGradePoint * newCredit);
      final totalCredits = currentCredits + newCredit;

      return totalCredits > 0 ? totalGradePoints / totalCredits : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get grade from percentage
  String getGradeFromPercentage(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C+';
    if (percentage >= 40) return 'C';
    if (percentage >= 30) return 'D';
    return 'F';
  }

  /// Get grade point from percentage
  double getGradePointFromPercentage(double percentage) {
    if (percentage >= 90) return 10;
    if (percentage >= 80) return 9;
    if (percentage >= 70) return 8;
    if (percentage >= 60) return 7;
    if (percentage >= 50) return 6;
    if (percentage >= 40) return 5;
    if (percentage >= 30) return 4;
    return 0;
  }

  /// Calculate minimum marks needed
  Map<String, dynamic> calculateMinMarksNeeded({
    required double targetGPA,
    required double outOf,
  }) {
    final targetPercentage = (targetGPA / 10) * 100;
    final marksNeeded = (targetPercentage * outOf) / 100;

    return {
      'marksNeeded': marksNeeded,
      'percentage': targetPercentage,
      'grade': getGradeFromPercentage(targetPercentage),
    };
  }
}
