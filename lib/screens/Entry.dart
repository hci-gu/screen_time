import 'package:flutter/material.dart';

class NewEntryPage extends StatelessWidget {
  const NewEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ny sömndagboksanteckning'),
      ),
      body: const Center(
        child: Text('Här kommer formuläret'),
      ),
    );
  }
}
