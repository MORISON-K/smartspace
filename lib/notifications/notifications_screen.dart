import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map?;
    final RemoteMessage? message = arguments?['message'];
    final String? role = arguments?['role'];
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 97, 113, 147),
        title: Text("Notifications ${role != null ? '($role)' : ''}"),
        actions: [
          if (message == null && user != null) // Only show when viewing history
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              onPressed: () => _markAllAsRead(user.uid),
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body:
          message != null
              ? _buildSingleNotificationView(context, message, role)
              : _buildNotificationsList(context, user),
    );
  }

  // Show single notification (when tapped from notification)
  Widget _buildSingleNotificationView(
    BuildContext context,
    RemoteMessage message,
    String? role,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Title:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.notification?.title ?? 'No title',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Message:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.notification?.body ?? 'No message',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (message.data.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Additional Data:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...message.data.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (role != null)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This notification was sent to $role users',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text('View All Notifications'),
            ),
          ),
        ],
      ),
    );
  }

  // Show notifications history list
  Widget _buildNotificationsList(BuildContext context, User? user) {
    if (user == null) {
      return const Center(child: Text('Please log in to view notifications'));
    }

    print('Building notifications list for user: ${user.uid}'); // Debug log

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .orderBy('receivedAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        print('StreamBuilder state: ${snapshot.connectionState}'); // Debug log
        print('Has data: ${snapshot.hasData}'); // Debug log
        if (snapshot.hasData) {
          print(
            'Number of notifications: ${snapshot.data!.docs.length}',
          ); // Debug log
        }
        if (snapshot.hasError) {
          print('Error: ${snapshot.error}'); // Debug log
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading notifications: ${snapshot.error}',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final isRead = data['isRead'] ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isRead ? null : Colors.blue.shade50,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isRead ? Colors.grey : Colors.blue,
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  data['title'] ?? 'No title',
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['body'] ?? 'No message'),
                    if (data['receivedAt'] != null)
                      Text(
                        _formatDate(data['receivedAt']),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                trailing:
                    !isRead
                        ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        )
                        : null,
                onTap: () {
                  if (!isRead) {
                    _markAsRead(user.uid, doc.id);
                  }
                  _showNotificationDetails(context, data);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _markAsRead(String userId, String notificationId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  void _markAllAsRead(String userId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get()
        .then((querySnapshot) {
          for (var doc in querySnapshot.docs) {
            doc.reference.update({'isRead': true});
          }
        });
  }

  void _showNotificationDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(data['title'] ?? 'Notification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['body'] ?? 'No message'),
                if (data['data'] != null &&
                    (data['data'] as Map).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Additional Data:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...((data['data'] as Map).entries.map(
                    (entry) => Text('${entry.key}: ${entry.value}'),
                  )),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
}
