import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Activity {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String type; // 'listing_created', 'inquiry_received', 'view_count', 'price_update', etc.
  final String sellerId;
  final String? propertyId;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.sellerId,
    this.propertyId,
  });

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: data['type'] ?? '',
      sellerId: data['sellerId'] ?? '',
      propertyId: data['propertyId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'sellerId': sellerId,
      'propertyId': propertyId,
    };
  }

  IconData get icon {
    switch (type) {
      case 'listing_created':
        return Icons.add_home;
      case 'inquiry_received':
        return Icons.message;
      case 'view_count':
        return Icons.visibility;
      case 'price_update':
        return Icons.update;
      case 'listing_approved':
        return Icons.check_circle;
      case 'listing_rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color get color {
    switch (type) {
      case 'listing_created':
        return Colors.green;
      case 'inquiry_received':
        return Colors.blue;
      case 'view_count':
        return Colors.orange;
      case 'price_update':
        return Colors.purple;
      case 'listing_approved':
        return Colors.green;
      case 'listing_rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
}