// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

Widget menuWidget(
  BuildContext context, {
  required String label,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 8,
      shadowColor: Colors.black26,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            radius: 30,
            child: Icon(icon, color: color, size: 40),
          ),
          SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    ),
  );
}
