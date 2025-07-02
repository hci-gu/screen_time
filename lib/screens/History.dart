import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historik'),
      ),
      body: const Center(
        child: Text('Här kommer en lista med ifyllda formulär'),
      ),
    );
  }
}
