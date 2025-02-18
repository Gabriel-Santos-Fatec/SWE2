import 'package:flutter/material.dart';

import '../widgets/menu_widget.dart';
import 'engenheiros_screen.dart';
import 'relatorio_screen.dart';
import 'tarefas_alocadas_screen.dart';
import 'tarefas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade700,
                Colors.blue.shade400,
                Colors.blue.shade300,
              ],
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 50),
              Text(
                "Gerenciador de Tarefas",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: EdgeInsets.all(20),
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    menuWidget(
                      context,
                      label: "Engenheiros",
                      icon: Icons.engineering,
                      color: Colors.orange,
                      onTap: () => _navigateTo(context, EngenheirosScreen()),
                    ),
                    menuWidget(
                      context,
                      label: "Tarefas",
                      icon: Icons.task,
                      color: Colors.green,
                      onTap: () => _navigateTo(context, TarefasScreen()),
                    ),
                    menuWidget(
                      context,
                      label: "Gerenciamento",
                      icon: Icons.assignment_turned_in,
                      color: Colors.purple,
                      onTap:
                          () => _navigateTo(context, TarefasAlocadasScreen()),
                    ),
                    menuWidget(
                      context,
                      label: "Relatório",
                      icon: Icons.bar_chart,
                      color: Colors.red,
                      onTap:
                          () => _navigateTo(
                            context,
                            ProgressoEngenheirosScreen(),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
