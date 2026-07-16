import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class Timewidget extends StatefulWidget {
  const Timewidget({super.key});

  @override
  State<Timewidget> createState() => _TimewidgetState();
}

class _TimewidgetState extends State<Timewidget> {
  String formattedDate = "";
  String hour = "";
  String minute = "";
  Timer? _timer; // Store timer instance

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) { // Prevent setState() after dispose
        _updateTime();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      formattedDate = DateFormat('EEEE, d MMMM').format(now);
      hour = DateFormat('HH').format(now);
      minute = DateFormat('mm').format(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Today",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.normal,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
              decorationThickness: 0.5,
            ),
          ),
          
          Text(
            formattedDate,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeCircle(hour),
              const SizedBox(width: 4),
              const Column(
                children: [
                  Text(
                    "",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              _buildTimeCircle(minute),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCircle(String value) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 36, 36, 36),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            blurRadius: 2.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
