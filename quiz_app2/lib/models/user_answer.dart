import 'question.dart';

class UserAnswer {
  final Question question;
  final String selectedAnswer;
  final bool isCorrect;

  UserAnswer({
    required this.question,
    required this.selectedAnswer,
    required this.isCorrect,
  });
}
