import 'package:flutter/material.dart';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notifications;
import 'package:flutter/scheduler.dart';
import 'package:vibration/vibration.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackgroundService();
  await initializeNotifications();
  runApp(const MaterialApp(
    home: TimerApp(),
    debugShowCheckedModeBanner: false,
  ));
}

final notifications.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = notifications.FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const notifications.AndroidInitializationSettings initializationSettingsAndroid =
  notifications.AndroidInitializationSettings('@mipmap/ic_launcher');

  const notifications.InitializationSettings initializationSettings =
  notifications.InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onSelectNotification: (String? payload) async {
      if (payload == 'STOP_TIMER') {
        TimerAppState.timerAppState?.stopTimer();
      } else if (payload == 'PAUSE_TIMER') {
        TimerAppState.timerAppState?.pauseTimer();
      }
    },
  );
}

Future<void> showNotification(String remainingTime) async {
  const notifications.AndroidNotificationDetails androidPlatformChannelSpecifics =
  notifications.AndroidNotificationDetails(
    'your_channel_id',
    'Timer Notification',
    channelDescription: 'This notification shows the timer',
    importance: notifications.Importance.max,
    priority: notifications.Priority.high,
    ongoing: true,
    visibility: notifications.NotificationVisibility.public,
    showWhen: false,
  );

  const notifications.NotificationDetails platformChannelSpecifics =
  notifications.NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Timer Running',
    'Remaining Time: $remainingTime',
    platformChannelSpecifics,
    payload: 'STOP_TIMER',
  );
}

Future<void> cancelNotification() async {
  await flutterLocalNotificationsPlugin.cancel(0);
}

Future<void> initializeBackgroundService() async {
  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "Timer Running",
    notificationText: "The timer will continue to run.",
    enableWifiLock: true,
  );

  await FlutterBackground.initialize(androidConfig: androidConfig);
}

class TimerApp extends StatefulWidget {
  const TimerApp({super.key});

  @override
  TimerAppState createState() => TimerAppState();
}

class TimerAppState extends State<TimerApp> with TickerProviderStateMixin, WidgetsBindingObserver {
  static TimerAppState? timerAppState;

  int selectedHour = 0;
  int selectedMinute = 0;
  int selectedSecond = 0;

  final List<int> hours = List.generate(24, (index) => index);
  final List<int> minutes = List.generate(60, (index) => index);
  final List<int> seconds = List.generate(60, (index) => index);

  int totalTimeInSeconds = 0;
  bool isTimerRunning = false;
  bool isTimerPaused = false;
  int initialTimeInSeconds = 0;

  late AnimationController animationController;
  late ConfettiController _confettiController;
  late Ticker _ticker;

  // Controllers for multiple fade transitions
  late AnimationController fadeController1;
  late AnimationController fadeController2;

  @override
  void initState() {
    super.initState();
    timerAppState = this;
    WidgetsBinding.instance.addObserver(this);

    animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    _ticker = Ticker((Duration elapsed) {
      if (isTimerRunning && !isTimerPaused && totalTimeInSeconds > 0) {
        setState(() {
          totalTimeInSeconds = initialTimeInSeconds - elapsed.inSeconds;
          showNotification(formatTime(totalTimeInSeconds));
        });

        if (totalTimeInSeconds <= 0) {
          _ticker.stop();
          setState(() {
            totalTimeInSeconds = 0;
            isTimerRunning = false;
            animationController.reverse();
            _confettiController.play();
            cancelNotification();
            triggerVibration(); // Trigger vibration on completion
          });
        }
      }
    });

    // Initialize the fade animation controllers
    fadeController1 = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    fadeController2 = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    animationController.dispose();
    _confettiController.dispose();
    _ticker.dispose();
    fadeController1.dispose();
    fadeController2.dispose();
    cancelNotification();
    FlutterBackground.disableBackgroundExecution();
    WidgetsBinding.instance.removeObserver(this);
    timerAppState = null;
    super.dispose();
  }

  void triggerVibration() {
    Vibration.vibrate(pattern: [500, 1000, 500]);
  }

  void startTimer() {
    setState(() {
      totalTimeInSeconds = (selectedHour * 3600) + (selectedMinute * 60) + selectedSecond;
      initialTimeInSeconds = totalTimeInSeconds;
      isTimerRunning = true;
      isTimerPaused = false;
    });

    animationController.forward();
    _ticker.start();
  }

  void stopTimer() {
    _ticker.stop();
    cancelNotification();
    setState(() {
      isTimerRunning = false;
      totalTimeInSeconds = 0;
    });
    animationController.reverse();
  }

  void pauseTimer() {
    setState(() {
      isTimerPaused = true;
    });
    _ticker.stop();
    showNotification(formatTime(totalTimeInSeconds));
  }

  void resetTimer() {
    setState(() {
      selectedHour = 0;
      selectedMinute = 0;
      selectedSecond = 0;
      totalTimeInSeconds = 0;
      isTimerRunning = false;
    });
    cancelNotification();
  }

  String formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progressPercentage {
    if (initialTimeInSeconds == 0) return 0;
    return totalTimeInSeconds / initialTimeInSeconds;
  }

  // Toggle animations for the fade transitions
  void toggleFadeAnimations() {
    if (fadeController1.isCompleted) {
      fadeController1.reverse();
      fadeController2.reverse();
    } else {
      fadeController1.forward();
      fadeController2.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Timer')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.red],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: animationController,
                  child: CircularProgressIndicator(
                    value: progressPercentage,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressPercentage > 0.5
                          ? Colors.green
                          : progressPercentage > 0.2
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                FadeTransition(
                  opacity: fadeController1, // Use dynamic fade controller
                  child: Text(
                    formatTime(totalTimeInSeconds),
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: progressPercentage > 0.2 ? Colors.white : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (!isTimerRunning)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildScrollableColumn('Hours', hours, (index) {
                        setState(() {
                          selectedHour = index;
                        });
                      }),
                      buildScrollableColumn('Minutes', minutes, (index) {
                        setState(() {
                          selectedMinute = index;
                        });
                      }),
                      buildScrollableColumn('Seconds', seconds, (index) {
                        setState(() {
                          selectedSecond = index;
                        });
                      }),
                    ],
                  ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!isTimerRunning)
                      buildAnimatedButton('Start Timer', startTimer, Colors.grey, textColor: Colors.black),
                    if (isTimerRunning)
                      buildAnimatedButton('Stop Timer', stopTimer, Colors.redAccent),
                    if (!isTimerRunning)
                      buildAnimatedButton('Reset', resetTimer, Colors.grey, textColor: Colors.black),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildAnimatedButton('5 Min', () => setPreset(5), Colors.black),
                    buildAnimatedButton('10 Min', () => setPreset(10), Colors.black),
                    buildAnimatedButton('30 Min', () => setPreset(30), Colors.black),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleFadeAnimations,
        child: const Icon(Icons.play_arrow),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget buildScrollableColumn(String label, List<int> values, ValueChanged<int> onSelectedItemChanged) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 18, color: Colors.white)),
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  physics: const FixedExtentScrollPhysics(),
                  diameterRatio: 1.5,
                  perspective: 0.003,
                  onSelectedItemChanged: onSelectedItemChanged,
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      final isSelected = index == values.indexOf(values.firstWhere((element) => element == values[index]));
                      return Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: isSelected ? 36 : 26,
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          child: Text(values[index].toString()),
                        ),
                      );
                    },
                    childCount: values.length,
                  ),
                ),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.5), width: 2),
                      bottom: BorderSide(color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAnimatedButton(String label, VoidCallback onPressed, Color color, {Color textColor = Colors.white}) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 18, color: textColor),
        ),
      ),
    );
  }

  void setPreset(int minutes) {
    setState(() {
      selectedHour = 0;
      selectedMinute = minutes;
      selectedSecond = 0;
      startTimer();
    });
  }
}
