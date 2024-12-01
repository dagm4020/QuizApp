class QuizSettings {
  final int numberOfQuestions;
  final int categoryId;
  final String difficulty;
  final String type;

  QuizSettings({
    required this.numberOfQuestions,
    required this.categoryId,
    required this.difficulty,
    required this.type,
  });

  int getTimerDuration() {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 15;
      case 'medium':
        return 10;
      case 'hard':
        return 5;
      default:
        return 10;
    }
  }
}
