
import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFFE74C3C);
const kSecondaryColor = Color(0xFFF1948A);
const kBackgroundColor = Color(0xFFF5F5F5);
const kTextColor = Color(0xFF333333);
const kErrorColor = Color(0xFFE57373);
const kSuccessColor = Color(0xFF81C784);
const kWarningColor = Color(0xFFFFB74D);

const Color kAccentColor = Color(0xFFE74C3C);
const Color kLightTextColor = Color(0xFF7F8C8D);

final kButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: kPrimaryColor,
  foregroundColor: Colors.white,
  minimumSize: const Size(double.infinity, 50),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
  elevation: 0,
);

final kTextFieldDecoration = InputDecoration(
  filled: true,
  fillColor: Colors.white,
  hintStyle: TextStyle(color: Colors.grey[500]),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: kPrimaryColor, width: 1),
  ),
);