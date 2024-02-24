import 'package:app/audioscreen.dart';
import 'package:app/chat.dart';

import 'package:app/main.dart';
import 'package:app/sign_talk.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import 'home.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.w600);
  static List<Widget> widgetList = <Widget>[
    HomePage(),
    const SignTalk(),
    const ChatBot(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: widgetList,
        ),
        bottomNavigationBar: Container(
          color: kColourScheme.onPrimaryContainer,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: GNav(
                  backgroundColor: kColourScheme.onPrimaryContainer,
                  color: Colors.white,
                  tabBackgroundColor: kColourScheme.onSecondaryContainer,
                  activeColor: Colors.white,
                  gap: 15,
                  padding: const EdgeInsets.all(8),
                  tabs: const [
                    GButton(
                      icon: Icons.home,
                      text: "Home",
                    ),
                    GButton(
                      icon: Icons.chat_outlined,
                      text: "SignTalk",
                    ),
                    GButton(
                      icon: Icons.miscellaneous_services_outlined,
                      text: "SignBot",
                    ),
                  ],
                  selectedIndex: _selectedIndex,
                  onTabChange: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  })),
        ));
  }
}
