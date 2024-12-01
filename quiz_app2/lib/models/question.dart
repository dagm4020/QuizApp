class Question {
  final String type;
  final String difficulty;
  final String category;
  final String question;
  final String correctAnswer;
  final List<String> incorrectAnswers;
  final List<String> shuffledOptions;
  Question({
    required this.type,
    required this.difficulty,
    required this.category,
    required this.question,
    required this.correctAnswer,
    required this.incorrectAnswers,
    required this.shuffledOptions,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    String decodedQuestion = htmlUnescape(json['question']);
    String decodedCorrectAnswer = htmlUnescape(json['correct_answer']);
    List<String> decodedIncorrectAnswers = List<String>.from(
      json['incorrect_answers'].map((x) => htmlUnescape(x)),
    );

    List<String> allAnswers = List<String>.from(decodedIncorrectAnswers)
      ..add(decodedCorrectAnswer);
    allAnswers.shuffle();
    return Question(
      type: json['type'],
      difficulty: json['difficulty'],
      category: json['category'],
      question: decodedQuestion,
      correctAnswer: decodedCorrectAnswer,
      incorrectAnswers: decodedIncorrectAnswers,
      shuffledOptions: allAnswers,
    );
  }

  /*
  List<String> get options {
    List<String> allAnswers = List.from(incorrectAnswers)..add(correctAnswer);
    allAnswers.shuffle();     return allAnswers;
  }
  */

  static String htmlUnescape(String input) {
    return input
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}
