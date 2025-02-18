import 'package:flutter/material.dart';

class CardWidget extends StatelessWidget {
  final String title;
  final String subtitle1;
  final String subtitle2;
  final String subtitle3;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CardWidget({
    super.key,
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
    required this.subtitle3,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 6,
      shadowColor: Colors.black26,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade200,
          child: Icon(icon, color: Colors.blue.shade800),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle1, style: TextStyle(color: Colors.black87)),
            Text(subtitle2, style: TextStyle(color: Colors.black87)),
            subtitle3 != ""
                ? Text(subtitle3, style: TextStyle(color: Colors.black87))
                : Center(),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
