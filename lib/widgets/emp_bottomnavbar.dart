import 'package:flutter/material.dart';
import 'package:shiftsmart/screens/chats/chatlist.dart';
import 'package:shiftsmart/screens/employee/employee_leave.dart';
import 'package:shiftsmart/screens/employee/employee_jobs.dart';
import 'package:shiftsmart/screens/employee/employee_dashboard.dart';
import 'package:shiftsmart/widgets/emp_slidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class EmpBottomnavbar extends StatefulWidget {
  final int selectedIndex;
  const EmpBottomnavbar({super.key, this.selectedIndex = 0});

  @override
  State<EmpBottomnavbar> createState() => _EmpBottomnavbarState();
}

class _EmpBottomnavbarState extends State<EmpBottomnavbar> {
  late int _selectedIndex;

  final List<Widget> _pages = [
    const Employeedashboard(),
    const Employeeshifts(),
    const Chatlist(isInsideBottomNav: true),
    const Employeeleave(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<String> icons = [
    'assets/Home.png',
    'assets/shifts.png',
    'assets/empChat.png',
    'assets/Leave.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2230),
      drawer: const EmpSidenav(currentScreen: 'Home'),
      appBar: Uppernavbar(),
      body: _pages[_selectedIndex],
      extendBody: true,
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipPath(
            clipper: RightCornerClipper(),
            child: Container(
              height: 100,
              color: const Color.fromARGB(252, 60, 82, 170),
            ),
          ),
          Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(icons.length, (index) {
                  final bool isSelected = index == _selectedIndex;
                  return GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isSelected)
                          Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..multiply(Matrix4.skewX(-0.4))
                              ..rotateZ(-15 * 3.1415927 / 180),
                            alignment: Alignment.center,
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          const Color.fromARGB(255, 32, 34, 36)
                                              .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]),
                            ),
                          ),
                        Image.asset(
                          icons[index],
                          width: isSelected ? 30 : 25,
                          height: isSelected ? 30 : 25,
                          color: isSelected ? Colors.white : Colors.grey[400],
                        )
                      ],
                    ),
                  );
                }),
              ))
        ],
      ),
    );
  }
}

class RightCornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.4); // Slant up from top-left
    path.lineTo(size.width, 0); // Top-right
    path.lineTo(size.width, size.height); // Bottom-right
    path.lineTo(0, size.height); // Bottom-left
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
