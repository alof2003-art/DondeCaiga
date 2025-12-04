import 'package:flutter/material.dart';
import 'package:donde_caigav2/features/explorar/presentation/screens/explorar_screen.dart';
import 'package:donde_caigav2/features/anfitrion/presentation/screens/anfitrion_screen.dart';
import 'package:donde_caigav2/features/buzon/presentation/screens/chat_lista_screen.dart';
import 'package:donde_caigav2/features/perfil/presentation/screens/perfil_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ExplorarScreen(),
    AnfitrionScreen(),
    ChatListaScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4DB6AC),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explorar'),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work),
            label: 'Anfitrión',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
