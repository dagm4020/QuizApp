import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/quiz_settings.dart';
import '../services/api_service.dart';
import 'quiz_screen.dart';

class SetupScreen extends StatefulWidget {
  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();

  int _numberOfQuestions = 5;
  int? _selectedCategoryId;
  String _selectedDifficulty = 'medium';
  String _selectedType = 'boolean';
  List<Category> _categories = [];
  bool _loadingCategories = true;
  bool _startingQuiz = false;
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.instance.fetchCategories();
      setState(() {
        _categories = categories;
        _selectedCategoryId = categories.first.id;
        _loadingCategories = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        _loadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories.')),
      );
    }
  }

  void _startQuiz() {
    if (_formKey.currentState!.validate() && !_startingQuiz) {
      setState(() {
        _startingQuiz = true;
      });

      final settings = QuizSettings(
        numberOfQuestions: _numberOfQuestions,
        categoryId: _selectedCategoryId!,
        difficulty: _selectedDifficulty,
        type: _selectedType,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(settings: settings),
        ),
      ).then((_) {
        setState(() {
          _startingQuiz = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCategories) {
      return Scaffold(
        appBar: AppBar(title: Text('Setup Quiz')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Setup Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _numberOfQuestions,
                decoration: InputDecoration(labelText: 'Number of Questions'),
                items: [5, 10, 15]
                    .map((number) => DropdownMenuItem<int>(
                          value: number,
                          child: Text(number.toString()),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _numberOfQuestions = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: InputDecoration(labelText: 'Select Category'),
                items: _categories
                    .map((category) => DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value!;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDifficulty,
                decoration: InputDecoration(labelText: 'Select Difficulty'),
                items: ['easy', 'medium', 'hard']
                    .map((difficulty) => DropdownMenuItem<String>(
                          value: difficulty,
                          child: Text(difficulty.capitalize()),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDifficulty = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(labelText: 'Select Type'),
                items: [
                  {'value': 'multiple', 'label': 'Multiple Choice'},
                  {'value': 'boolean', 'label': 'True / False'}
                ]
                    .map((type) => DropdownMenuItem<String>(
                          value: type['value'],
                          child: Text(type['label']!),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _startingQuiz ? null : _startQuiz,
                child: _startingQuiz
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Starting Quiz...'),
                        ],
                      )
                    : Text('Start Quiz'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      this.length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}
