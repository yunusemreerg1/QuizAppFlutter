import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'database_helper.dart';
import 'sorular.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bilgi Yarışması',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilgi Yarışması'),
      ),
      body: Container(
        color: Colors.deepPurple,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bilgi Yarışmasına Hoşgeldiniz!',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QuizPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
                  textStyle: const TextStyle(fontSize: 18.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: const Text('Yarışmaya Başla'),
              ),
              const SizedBox(height: 10.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScoresPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
                  textStyle: const TextStyle(fontSize: 18.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: const Text('Önceki Skorlar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//a
class QuizPage extends StatefulWidget {
  const QuizPage({Key? key}) : super(key: key);

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentQuestionIndex = 0;
  List<Icon> _iconList = [];
  int _score = 0;
  final String _playerName = "Player";
  int _remainingSeconds = 85;
  Timer? _timer;

  bool doubleChanceUsed = false;
  bool fiftyFiftyUsed = false;
  bool skipUsed = false;
  bool isFirstAttempt = true; 

  late List<Map<String, Object>> _shuffledQuestions;

  @override
  void initState() {
    super.initState();
    _shuffledQuestions = List<Map<String, Object>>.from(questions)..shuffle(Random());
    _shuffledQuestions = _shuffledQuestions.take(20).toList();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _showResult();
        }
      });
    });
  }

  void _answerQuestion(int answerIndex) {
    setState(() {
      if (answerIndex == _shuffledQuestions[_currentQuestionIndex]['correctAnswer']) {
        _score++;
        _iconList.add(const Icon(Icons.check, color: Colors.green));
        _goToNextQuestion();
      } else {
        if (doubleChanceUsed && isFirstAttempt) {
          isFirstAttempt = false; 
          
          (_shuffledQuestions[_currentQuestionIndex]['answers'] as List<String>)[answerIndex] = '';
        } else {
          _iconList.add(const Icon(Icons.close, color: Colors.red));
          _goToNextQuestion();
        }
      }
    });
  }

  void _useDoubleChance() {
    setState(() {
      doubleChanceUsed = true;
      isFirstAttempt = true;
    });
  }

  void _useFiftyFifty() {
    setState(() {
      fiftyFiftyUsed = true;
      List<int> incorrectAnswers = [];
      for (int i = 0; i < (_shuffledQuestions[_currentQuestionIndex]['answers'] as List<String>).length; i++) {
        if (i != _shuffledQuestions[_currentQuestionIndex]['correctAnswer']) {
          incorrectAnswers.add(i);
        }
      }
      incorrectAnswers.shuffle();
      incorrectAnswers = incorrectAnswers.take(2).toList();
      for (int i in incorrectAnswers) {
        (_shuffledQuestions[_currentQuestionIndex]['answers'] as List<String>)[i] = '';
      }
    });
  }

  void _skipQuestion() {
    setState(() {
      skipUsed = true;
      _goToNextQuestion();
    });
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _shuffledQuestions.length - 1) {
      _currentQuestionIndex++;
      isFirstAttempt = true; 
    } else {
      _timer?.cancel();
      _showResult();
    }
  }

  void _showResult() async {
    await DatabaseHelper.instance.insertScore(_playerName, _score);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sonuçlar'),
        content: Text('Skorunuz: $_score / ${_shuffledQuestions.length}'),
        actions: <Widget>[
          TextButton(
            child: const Text('Yeniden Başla'),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _currentQuestionIndex = 0;
                _score = 0;
                _iconList = [];
                _shuffledQuestions.shuffle(Random());
                _shuffledQuestions = _shuffledQuestions.take(20).toList();
                _remainingSeconds = 85;
                _startTimer();
                doubleChanceUsed = false;
                fiftyFiftyUsed = false;
                skipUsed = false;
                isFirstAttempt = true; 
              });
            },
          ),
          TextButton(
            child: const Text('Ana Sayfaya Dön'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilgi Yarışması'),
      ),
      body: Container(
        color: Colors.deepPurple,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      '${_currentQuestionIndex + 1}.',
                      style: const TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      'Kalan Süre: ${_remainingSeconds}s',
                      style: const TextStyle(fontSize: 20, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Center(
                  child: Text(
                    _shuffledQuestions[_currentQuestionIndex]['questionText'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            ...(_shuffledQuestions[_currentQuestionIndex]['answers'] as List<String>).map((answer) {
              int answerIndex = (_shuffledQuestions[_currentQuestionIndex]['answers'] as List<String>).indexOf(answer);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    textStyle: const TextStyle(fontSize: 18.0),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: Text(
                    answer,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  onPressed: answer.isEmpty ? null : () => _answerQuestion(answerIndex),
                ),
              );
            }).toList(),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: doubleChanceUsed ? null : _useDoubleChance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: doubleChanceUsed ? Colors.grey : Colors.blue,
                    ),
                    child: const Text('Çift Cevap Hakkı'),
                  ),
                  const SizedBox(width: 10.0),
                  ElevatedButton(
                    onPressed: fiftyFiftyUsed ? null : _useFiftyFifty,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fiftyFiftyUsed ? Colors.grey : Colors.blue,
                    ),
                    child: const Text('%50 Jokeri'),
                  ),
                  const SizedBox(width: 10.0),
                  ElevatedButton(
                    onPressed: skipUsed ? null : _skipQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: skipUsed ? Colors.grey : Colors.blue,
                    ),
                    child: const Text('Pas Geçme Jokeri'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: _iconList,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScoresPage extends StatelessWidget {
  const ScoresPage({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchScores() async {
    return await DatabaseHelper.instance.getScores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Önceki Skorlar'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchScores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Hiç skor kaydedilmemiş.'));
          } else {
            final scores = snapshot.data!;
            return ListView.builder(
              itemCount: scores.length,
              itemBuilder: (context, index) {
                final score = scores[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.blue),
                    title: Text('Oyuncu: ${score['playerName']}'),
                    subtitle: Text('Skor: ${score['score']}'),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

