import 'package:flutter/material.dart';

class ActivityTile extends StatelessWidget {
  final String user;
  final String action;
  final String time;

  const ActivityTile({
    super.key,
    required this.user,
    required this.action,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.deepPurple,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          "$user $action",
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(time),
      ),
    );
  }
}
