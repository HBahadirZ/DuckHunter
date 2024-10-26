import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(ShootTheDuckApp());
}

class ShootTheDuckApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shoot The Duck',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: MainMenu(),
    );
  }
}

class MainMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Shoot The Duck',
              style: TextStyle(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                int hearts = prefs.getInt('hearts') ?? 3;
                int tapCount = prefs.getInt('tapCount') ?? 0;
                int totalScore = 0; // Set totalScore to 0 at the beginning of the game
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GameScreen(level: 1, hearts: hearts, tapCount: tapCount, totalScore: totalScore)),
                );
              },
              child: Text('New Game', style: TextStyle(color: Colors.black)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HighScoresScreen()),
                );
              },
              child: Text('High Scores', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final int level;
  final int hearts;
  final int tapCount;
  final int totalScore;

  GameScreen({required this.level, required this.hearts, required this.tapCount, required this.totalScore});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  double _top = 100;
  double _right = 50;
  late int _tapCount;
  late int _hearts;
  late int _totalScore;
  Timer? _timer;
  Timer? _iconTimer;
  int _timeLeft = 10;
  bool _gameEnded = false;
  bool _iconBeingTapped = false;

  @override
  void initState() {
    super.initState();
    _tapCount = widget.tapCount;
    _hearts = widget.hearts;
    _totalScore = widget.totalScore;
    _startTimer();
    _startIconTimer();
  }

  void _startTimer() {
    if (widget.level < 3) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_timeLeft > 0) {
          setState(() {
            _timeLeft--;
          });
        } else {
          _endGame();
        }
      });
    }
  }

  void _startIconTimer() {
    double interval;
    if (widget.level == 1) {
      interval = 1.25;
    } else if (widget.level == 2) {
      interval = 0.85;
    } else {
      interval = 0.55;
    }
    _iconTimer = Timer.periodic(Duration(milliseconds: (interval * 1000).toInt()), (timer) {
      if (!_iconBeingTapped) {
        setState(() {
          _iconBeingTapped = true;
          _changePosition();
          _iconBeingTapped = false;
        });
      }
    });
  }

  void _changePosition() {
    final random = Random();
    setState(() {
      _top = 150 + random.nextDouble() * (MediaQuery.of(context).size.height - 250);
      _right = 20 + random.nextDouble() * (MediaQuery.of(context).size.width - 100);
    });
  }

  void _tapIcon() {
    if (!_gameEnded) {
      _iconBeingTapped = true;
      _tapCount++;
      _changePosition();
      _iconTimer?.cancel();
      _startIconTimer();
      _iconBeingTapped = false;

      if (_tapCount >= 10) {
        _endLevel();
      }
    }
  }

  void _loseHeart() {
    if (_hearts > 0 && !_gameEnded) {
      setState(() {
        _hearts--;
        if (_hearts == 0) {
          _endGame();
        }
      });
    }
  }

  void _endLevel() async {
    _timer?.cancel();
    _iconTimer?.cancel();
    String message;
    if (widget.level == 1) {
      message = "Well done son! You are now a novice hunter";
    } else if (widget.level == 2) {
      message = "Wow man, you know what you are doing";
    } else {
      message = "You're a master hunter!";
    }

    _totalScore += 10;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hearts', _hearts);
    await prefs.setInt('tapCount', 0);
    await prefs.setInt('totalScore', _totalScore);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Level Complete"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (widget.level < 3) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => GameScreen(level: widget.level + 1, hearts: _hearts, tapCount: 0, totalScore: _totalScore)),
                  );
                } else {
                  _endGame();
                }
              },
              child: Text("Continue"),
            ),
          ],
        );
      },
    );
  }

  void _endGame() async {
    if (_gameEnded) return;
    _gameEnded = true;
    _timer?.cancel();
    _iconTimer?.cancel();
    _totalScore += _tapCount;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> highScores = prefs.getStringList('highScores') ?? [];
    List<int> scoreList = highScores.map((e) => int.tryParse(e) ?? 0).toList();
    scoreList.add(_totalScore);
    scoreList.sort((b, a) => a.compareTo(b));
    if (scoreList.length > 3) {
      scoreList = scoreList.sublist(0, 3);
    }
    highScores = scoreList.map((e) => e.toString()).toList();
    await prefs.setStringList('highScores', highScores);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HighScoresScreen(score: _totalScore)),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _iconTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loseHeart,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightBlueAccent, Colors.greenAccent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              right: _right,
              top: _top,
              child: GestureDetector(
                onTap: () {
                  _tapIcon();
                },
                child: Icon(
                  Icons.flutter_dash,
                  size: 60,
                  color: Colors.black,
                ),
              ),
            ),
            Positioned(
              top: 50,
              left: 20,
              child: Text(
                'Tap Count: $_tapCount',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: Text(
                'Time Left: ${widget.level < 3 ? '$_timeLeft s' : 'Unlimited'}',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 100,
              left: 20,
              child: Text(
                'Hearts: $_hearts',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 150,
              left: 20,
              child: Text(
                'Total Score: $_totalScore',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HighScoresScreen extends StatelessWidget {
  final int? score;

  HighScoresScreen({this.score});

  Future<List<int>> _getHighScores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> highScores = prefs.getStringList('highScores') ?? [];
    return highScores.map((e) => int.tryParse(e) ?? 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[100],
      body: Center(
        child: FutureBuilder<List<int>>(
          future: _getHighScores(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error loading high scores');
            } else {
              List<int> highScores = snapshot.data ?? [];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'High Scores',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 30),
                  if (score != null)
                    Text(
                      'Your Score: $score',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  SizedBox(height: 20),
                  ...highScores.asMap().entries.map((entry) {
                    int index = entry.key;
                    int value = entry.value;
                    return Text(
                      'High Score ${index + 1}: $value',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => GameScreen(level: 1, hearts: 3, tapCount: 0, totalScore: 0)),
                      );
                    },
                    child: Text('Restart', style: TextStyle(color: Colors.black)),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
