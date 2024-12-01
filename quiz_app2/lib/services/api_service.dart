import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import '../models/quiz_settings.dart';
import '../models/category.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._privateConstructor();

  static final ApiService instance = ApiService._privateConstructor();

  String? _sessionToken;

  Future<void> initializeSessionToken() async {
    if (_sessionToken != null) return;

    final response = await http
        .get(Uri.parse('https://opentdb.com/api_token.php?command=request'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['response_code'] == 0) {
        _sessionToken = data['token'];
        print('Session Token Initialized: $_sessionToken');
      } else {
        throw Exception('Failed to initialize session token.');
      }
    } else {
      throw Exception(
          'Failed to initialize session token. Status Code: ${response.statusCode}');
    }
  }

  Future<void> resetSessionToken() async {
    if (_sessionToken == null) return;

    final url =
        'https://opentdb.com/api_token.php?command=reset&token=$_sessionToken';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['response_code'] == 0) {
        print('Session Token Reset Successfully.');
      } else {
        throw Exception('Failed to reset session token.');
      }
    } else {
      throw Exception(
          'Failed to reset session token. Status Code: ${response.statusCode}');
    }
  }

  Future<List<Question>> fetchQuestions(QuizSettings settings,
      {int retryCount = 0}) async {
    await initializeSessionToken();

    String url = 'https://opentdb.com/api.php?';
    url += 'amount=${settings.numberOfQuestions}';
    url += '&category=${settings.categoryId}';
    url += '&difficulty=${settings.difficulty}';
    url += '&type=${settings.type}';
    if (_sessionToken != null) {
      url += '&token=$_sessionToken';
    }

    print('Fetching Questions with URL: $url');

    final response = await http.get(Uri.parse(url));

    print('API Response Status: ${response.statusCode}');
    print('API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      switch (data['response_code']) {
        case 0:
          List<Question> questions = (data['results'] as List)
              .map((q) => Question.fromJson(q))
              .toList();
          print('Loaded ${questions.length} questions successfully.');
          return questions;
        case 1:
          throw Exception('No questions found for the selected settings.');
        case 2:
          throw Exception('Invalid parameter. Please check your settings.');
        case 3:
          throw Exception('Session Token not found.');
        case 4:
          if (retryCount < 1) {
            print(
                'Session Token Exhausted. Attempting to reset the token and retry.');
            await resetSessionToken();
            return await fetchQuestions(settings, retryCount: retryCount + 1);
          } else {
            throw Exception(
                'All questions have been exhausted for this session. Please try again.');
          }
        case 5:
          if (retryCount < 5) {
            int delay = pow(2, retryCount).toInt() * 100;
            print(
                'Received response_code:5 (Rate Limit). Implementing backoff.');
            print('Retrying after $delay ms...');
            await Future.delayed(Duration(milliseconds: delay));
            return await fetchQuestions(settings, retryCount: retryCount + 1);
          } else {
            throw Exception('Rate limit exceeded. Please try again later.');
          }
        default:
          print('Received unexpected response_code: ${data['response_code']}');
          throw Exception(
              'Unexpected response_code: ${data['response_code']}. Please try again.');
      }
    } else if (response.statusCode == 429) {
      if (retryCount < 5) {
        int delay = pow(2, retryCount).toInt() * 100;
        print('Received 429 Too Many Requests. Implementing backoff.');
        print('Retrying after $delay ms...');
        await Future.delayed(Duration(milliseconds: delay));
        return await fetchQuestions(settings, retryCount: retryCount + 1);
      } else {
        throw Exception('Too many requests. Please try again later.');
      }
    } else {
      throw Exception(
          'Failed to load questions. Status Code: ${response.statusCode}');
    }
  }

  Future<List<Category>> fetchCategories() async {
    final url = 'https://opentdb.com/api_category.php';
    print('Fetching Categories with URL: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Category> categories = (data['trivia_categories'] as List)
          .map((cat) => Category.fromJson(cat))
          .toList();
      print('Fetched ${categories.length} categories successfully.');
      return categories;
    } else {
      throw Exception(
          'Failed to load categories. Status Code: ${response.statusCode}');
    }
  }
}
