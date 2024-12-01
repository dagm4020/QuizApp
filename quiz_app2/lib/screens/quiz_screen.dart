import 'package:flutter/material.dart';
import 'dart:async';
import '../models/question.dart';
import '../models/quiz_settings.dart';
import '../models/user_answer.dart';
import '../services/api_service.dart';
import 'summary_screen.dart';

class QuizScreen extends StatefulWidget {
  final QuizSettings settings;

  QuizScreen({required this.settings});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _loading = true;
  bool _answered = false;
  String _selectedAnswer = "";
  String _feedbackText = "";
  List<UserAnswer> _userAnswers = [];
  String? _error;
  Timer? _timer;
  int _remainingTime = 0;
  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      print('Loading questions for QuizScreen with settings:');
      print('Number of Questions: ${widget.settings.numberOfQuestions}');
      print('Category ID: ${widget.settings.categoryId}');
      print('Difficulty: ${widget.settings.difficulty}');
      print('Type: ${widget.settings.type}');

      final questions =
          await ApiService.instance.fetchQuestions(widget.settings);
      if (questions.isEmpty) {
        throw Exception('No questions available for the selected settings.');
      }
      setState(() {
        _questions = questions;
        _loading = false;
      });
      _startTimer();
    } catch (e, stacktrace) {
      print('Error loading questions: $e');
      print('Stacktrace: $stacktrace');
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(_error!),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  void _startTimer() {
    _remainingTime = widget.settings.getTimerDuration();
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime <= 0) {
        timer.cancel();
        _handleTimeUp();
      } else {
        setState(() {
          _remainingTime--;
        });
      }
    });

    setState(() {});
  }

  void _handleTimeUp() {
    setState(() {
      _answered = true;
      _selectedAnswer = "";
      _feedbackText = "Time’s up!";
      _remainingTime = 0;
    });

    _userAnswers.add(UserAnswer(
      question: _questions[_currentQuestionIndex],
      selectedAnswer: "No Answer",
      isCorrect: false,
    ));
  }

  void _submitAnswer(String selectedAnswer) {
    if (_answered) return;
    final correctAnswer = _questions[_currentQuestionIndex].correctAnswer;
    bool isCorrect = selectedAnswer == correctAnswer;

    setState(() {
      _answered = true;
      _selectedAnswer = selectedAnswer;
      if (isCorrect) {
        _score++;
        _feedbackText = "Correct! The answer is \"$correctAnswer\".";
      } else {
        _feedbackText = "Incorrect. The correct answer is \"$correctAnswer\".";
      }
    });

    _timer?.cancel();

    _userAnswers.add(UserAnswer(
      question: _questions[_currentQuestionIndex],
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
    ));
  }

  void _nextQuestion() {
    if (_currentQuestionIndex + 1 >= _questions.length) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryScreen(
            userAnswers: _userAnswers,
            totalScore: _score,
            settings: widget.settings,
          ),
        ),
      );
    } else {
      setState(() {
        _answered = false;
        _selectedAnswer = "";
        _feedbackText = "";
        _currentQuestionIndex++;
      });
      _startTimer();
    }
  }

  Widget _buildOptionButton(String option) {
    bool isSelected = _selectedAnswer == option;
    Color buttonColor = Colors.blue;
    if (_answered) {
      if (option == _questions[_currentQuestionIndex].correctAnswer) {
        buttonColor = Colors.green;
      } else if (isSelected &&
          option != _questions[_currentQuestionIndex].correctAnswer) {
        buttonColor = Colors.red;
      } else {
        buttonColor = Colors.grey;
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: _answered ? null : () => _submitAnswer(option),
        child: Text(option),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return Text(
      'Time Remaining: $_remainingTime s',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _remainingTime <= 5 ? Colors.red : Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold();
    }

    final question = _questions[_currentQuestionIndex];
    double progress =
        (_currentQuestionIndex + (_answered ? 1 : 0)) / _questions.length;

    return Scaffold(
      appBar: AppBar(title: Text('Quiz')),
      body: WillPopScope(
        onWillPop: () async => !_loading,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'Score: $_score',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                color: Colors.blue,
              ),
              SizedBox(height: 16),
              _buildTimer(),
              SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    question.question,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              SizedBox(height: 16),
              ...question.shuffledOptions
                  .map((option) => _buildOptionButton(option)),
              SizedBox(height: 20),
              if (_answered)
                AnimatedOpacity(
                  opacity: _answered ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 500),
                  child: Text(
                    _feedbackText,
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedAnswer == question.correctAnswer
                          ? Colors.green
                          : (_feedbackText == "Time’s up!"
                              ? Colors.orange
                              : Colors.red),
                    ),
                  ),
                ),
              if (_answered)
                ElevatedButton(
                  onPressed: _nextQuestion,
                  child: Text('Next Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
