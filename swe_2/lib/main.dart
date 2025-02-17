import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/tarefa_monitor.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Garante que o monitor seja iniciado assim que o app abrir
  TarefaMonitor();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gerenciador de Tarefas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}
