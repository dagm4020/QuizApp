import 'package:flutter/material.dart';
import '../models/user_answer.dart';
import 'setup_screen.dart';
import 'quiz_screen.dart';
import '../models/quiz_settings.dart';
import '../services/api_service.dart';

class SummaryScreen extends StatelessWidget {
  final List<UserAnswer> userAnswers;
  final int totalScore;
  final QuizSettings settings;

  SummaryScreen({
    required this.userAnswers,
    required this.totalScore,
    required this.settings,
  });

  void _resetSessionToken() async {
    try {
      await ApiService.instance.resetSessionToken();
      print('Session token reset after quiz.');
    } catch (e) {
      print('Error resetting session token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _resetSessionToken();

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Summary'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Your Score: $totalScore/${userAnswers.length}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: userAnswers.length,
                itemBuilder: (context, index) {
                  final userAnswer = userAnswers[index];
                  bool timedOut = userAnswer.selectedAnswer == "No Answer";
                  return Card(
                    color: userAnswer.isCorrect
                        ? Colors.green[50]
                        : (timedOut ? Colors.orange[50] : Colors.red[50]),
                    child: ListTile(
                      leading: Icon(
                        userAnswer.isCorrect
                            ? Icons.check_circle
                            : (timedOut ? Icons.access_time : Icons.cancel),
                        color: userAnswer.isCorrect
                            ? Colors.green
                            : (timedOut ? Colors.orange : Colors.red),
                      ),
                      title: Text(userAnswer.question.question),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text('Your Answer: ${userAnswer.selectedAnswer}'),
                          Text(
                              'Correct Answer: ${userAnswer.question.correctAnswer}'),
                          if (timedOut)
                            Text(
                              'Status: Time’s up!',
                              style: TextStyle(color: Colors.orange),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizScreen(settings: settings),
                      ),
                    );
                  },
                  child: Text('Retake Quiz'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(150, 50),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => SetupScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: Text('Change Settings'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(150, 50),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
