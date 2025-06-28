import 'package:flutter/material.dart';
import 'package:sist_tickets/constants.dart';

// Reusable button widget
class StandardIconButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const StandardIconButton({
    Key? key,
    required this.icon,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        //shape: RoundedRectangleBorder(
        //borderRadius: BorderRadius.circular(20),
        //),
      ),
    );
  }
}
