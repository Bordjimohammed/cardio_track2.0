import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'screens/Screen1.dart';
import 'screens/Screen2.dart';
import 'screens/Screen3.dart';
import '/login_page.dart';

class IntroScreens extends StatefulWidget {
  const IntroScreens({super.key});

  @override
  State<IntroScreens> createState() => _IntroScreensState();
}

class _IntroScreensState extends State<IntroScreens> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
              _currentPageIndex = index;
              });
            },
            children: const [
              Screen1(),
              Screen2(),
              Screen3(),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  },
                  child: const Text("Précédent"),
                ),
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: const WormEffect(
                    activeDotColor: Color.fromARGB(255, 184, 14, 14),
                    dotColor: Colors.grey,
                  ),
                ),
                _currentPageIndex == 2
                    ? ElevatedButton(
                        onPressed: _goToLogin,
                        child: const Text("Commencer"),
                      )
                    : TextButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                        child: const Text("Suivant"),
                      ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}