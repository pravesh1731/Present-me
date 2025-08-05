
import 'package:flutter/material.dart';


class Button extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final List<Color>? gradientColors;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const Button({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradientColors = const [Color(0xff0BCCEB), Color(0xff0A80F5)],
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),

  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? [Color(0xff0BCCEB), Color(0xff0A80F5)],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}


class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xff0BCCEB), Color(0xff0A80F5)], // Customize colors
              begin: Alignment.bottomLeft,
              end: Alignment.topCenter,
            ),
          ),
        ),

        // Centered Image
        SizedBox(
          width: 60,
          height: 60,
          child: Image.asset("assets/image/logo.png"), // Replace with your avatar image
        ),
      ],
    );
  }
}

class Button1 extends StatelessWidget {
  final String text;
  final Widget icon;
  final VoidCallback onPressed;

  const Button1({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
       // Needed for ripple to show on custom background
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.grey.withOpacity(0.3),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



