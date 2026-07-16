import 'package:circulito/circulito.dart';
import 'package:flutter/material.dart';

class Circleindicator extends StatefulWidget {
  final double value;
  final int total;
  final int count;
  final String label;

  const Circleindicator({
    super.key,
    required this.value,
    required this.total,
    required this.count,
    required this.label,
  });

  @override
  State<Circleindicator> createState() => _CircleindicatorState();
}

class _CircleindicatorState extends State<Circleindicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);

    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic,),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(Circleindicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Smoothly animate to new value when widget updates
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOutCubic,
        ),
      );
      
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsiveness
    double screenWidth = MediaQuery.of(context).size.width;
    // double screenHeight = MediaQuery.of(context).size.height;

    Color fullCircleColor = const Color.fromARGB(255, 3, 4, 94);
    Color belowCircleColor = const Color.fromARGB(255, 0, 119, 182);
    Color upperCircleColor = const Color.fromARGB(255, 0, 180, 216);

    switch (widget.label.toLowerCase()) {
      case 'completed':
        fullCircleColor = const Color(0xFF00695C);
        belowCircleColor = const Color(0xFF009688);
        upperCircleColor = const Color(0xFF00BCD4);
        break;
      case 'in progress':
        fullCircleColor = const Color(0xFF424242);
        belowCircleColor = const Color(0xFF5D4037);
        upperCircleColor = const Color(0xFFFFA500);
        break;
    }

    // Responsive circle size: base size scales with screen width and height
    double circleSize = screenWidth * 0.25; // 20% of screen width
    // double padding = screenWidth * 0.5;   // 5% padding of screen width
    double strokeWidth =
        circleSize * 0.1; // stroke width relative to circle size

    return SizedBox(
      width: circleSize,
      height: circleSize,
      child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                //full circle that won't move
                Circulito(
                    padding: 5,
                    strokeWidth: strokeWidth,
                    sections: [
                      CirculitoSection(
                        value: 10,
                        decoration:
                            CirculitoDecoration.fromColor(fullCircleColor),
                      )
                    ],
                    maxSize: circleSize),

                // below circle
                Circulito(
                    padding: 0,
                    strokeWidth: circleSize * 0.2,
                    isCentered: true,
                    startPoint: StartPoint.top,
                    strokeCap: CirculitoStrokeCap.butt,
                    sections: [
                      CirculitoSection(
                        value: _animation.value,
                        decoration:
                            CirculitoDecoration.fromColor(belowCircleColor),
                      )
                    ],
                    maxSize: circleSize - 10),

                //upper circle
                Circulito(
                  strokeWidth: strokeWidth,
                  padding: 0,
                  isCentered: true,
                  startPoint: StartPoint.top,
                  strokeCap: CirculitoStrokeCap.butt,
                  sections: [
                    CirculitoSection(
                      value: _animation.value,
                      decoration:
                          CirculitoDecoration.fromColor(upperCircleColor),
                    )
                  ],
                  maxSize: circleSize,
                ),

                //white circle
                Circulito(
                    strokeWidth: circleSize * 0.4,
                    sections: [
                      CirculitoSection(
                        value: 1,
                        decoration:
                            const CirculitoDecoration.fromColor(Colors.white),
                      )
                    ],
                    maxSize: circleSize * 0.6,
                    child: Text(
                      "${widget.count}/${widget.total}",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        fontSize: circleSize * 0.18,
                        color: Color.fromARGB(255, 5, 5, 5),
                      ),
                    ))
              ],
            );
          },
        ),
    );
  }
}
