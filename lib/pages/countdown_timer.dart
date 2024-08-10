import 'package:flutter/material.dart';
import 'dart:async';

class CountdownTimer extends StatefulWidget {
  final DateTime eventTime;

  CountdownTimer({required this.eventTime});

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _remainingTime = Duration();

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _startTimer();
  }

  void _updateRemainingTime() {
    setState(() {
      _remainingTime = widget.eventTime.difference(DateTime.now());
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateRemainingTime();
      
      // หยุดการทำงานถ้านับถอยหลังเสร็จแล้ว
      if (_remainingTime.isNegative) {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format the duration as readable text
    String formattedTime;
    if (_remainingTime.isNegative) {
      formattedTime = 'Event Started';
    } else {
      final days = _remainingTime.inDays;
      final hours = _remainingTime.inHours.remainder(24);
      final minutes = _remainingTime.inMinutes.remainder(60);
      final seconds = _remainingTime.inSeconds.remainder(60);

      if (days > 0) {
        formattedTime = 'อีก $days วัน $hours ชั่วโมง';
      } else if (hours > 0) {
        formattedTime = 'อีก $hours ชั่วโมง $minutes นาที';
      } else if (minutes > 0) {
        formattedTime = 'อีก $minutes นาที $seconds วินาที';
      } else {
        formattedTime = 'อีก $seconds วินาที';
      }
    }

    return Text(
      formattedTime,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
    );
  }
}

