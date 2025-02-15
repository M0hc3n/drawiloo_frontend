import 'package:flutter/material.dart';

class AnimatedSplashScreen extends StatefulWidget {
  @override
  _AnimatedSplashScreenState createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<Color?> _colorAnimation;
  bool showIconsScreen = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );

    _circleAnimation = Tween<double>(begin: 50, end: 1500).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(begin: Colors.white, end: Color(0xFF7A1FA0))
        .animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward().then((value) {
      setState(() {
        showIconsScreen = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ClipRRect(
  borderRadius: BorderRadius.only(
    bottomLeft: Radius.circular(200.0),
    bottomRight: Radius.circular(200.0),
  ),
  child:
           Container(
            
            color: _colorAnimation.value,
            child: Center(
              
              child: showIconsScreen
                  ? FinalScreen() // The last screen with icons
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        // Expanding Circle
                        Container(
                          width: _circleAnimation.value,
                          height: _circleAnimation.value,
                          decoration: BoxDecoration(
                            
                            shape: BoxShape.circle,
                            color: Color(0xFF7A1FA0),
                          ),
                        ),
                        // Text on the Circle
                        Image.asset(
  'assets/image/log.png', // Replace with the correct path to your logo
  height: 80, // Adjust the height as needed
  fit: BoxFit.contain, // Ensures the image scales properly
  color: _circleAnimation.value > 200 ? Colors.white : null, // Optional color effect
),

                      ],
                    ),
            ),
          ));
        },
      ),
    );
  }
}

class FinalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 20,
          children: [
            Image.asset('assets/image/splash.png', width: 600, height: 600),
          
          ],
        ),
        SizedBox(height: 40),
        Container(
          
          
          child: ElevatedButton(
            onPressed: () {
              // Navigate to the next screen
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.purple, backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Continue",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
