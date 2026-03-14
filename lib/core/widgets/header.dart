import 'package:flutter/material.dart';



class Header extends StatelessWidget {
  final String heading;
  final String subheading;
  final Color? backgroundColor1;
  final Color? backgroundColor2;

  const Header({
    super.key, required this.heading, required this.subheading, this.backgroundColor1,  this.backgroundColor2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      decoration:  BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor1 ?? Color(0xFF06B6D4),
             backgroundColor2 ??  Color(0xFF2563EB)
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),

                Text(
                  heading,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                 Text(
                  subheading,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}