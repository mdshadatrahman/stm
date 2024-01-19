import 'package:flutter/material.dart';
import 'package:stm/stm.dart';

final counter = Setme<int>((ref, self) => 0);

void main() {
  runApp(SetmeGraph(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('STM Example'),
        ),
        body: Center(
          child: Listenme((context, ref, self) {
            return Text('${ref.watch(counter, self)}');
          }),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.ref.update<int>(counter, (count) => count + 1);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
