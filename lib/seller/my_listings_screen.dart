import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {

  final user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Listings"),
        backgroundColor: Color.fromARGB(255, 164, 192, 221),
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
        .collection('listings')
        .where('user_id', isEqualTo: user?.uid)
        .snapshots(),
        builder: (context, snapshot) {
          // Show loading indicator while data is being fetched
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle errors
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Handle case when no data is available
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No listings found'));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final images = data['images'] as List<dynamic>? ?? [];
              final imageUrl = images.isNotEmpty ? images[0] as String : '';
              final description = data['description'] ?? 'No description';
              final title =
                  data['title'] ?? 'Property Listing'; // Better fallback title
              final price = data['price'] ?? 'N/A';
              final location = data['location'] ?? 'No location';

              // Debug print to check image URL and data
              print('Listing $index has ${images.length} images');
              print('First image URL for listing $index: "$imageUrl"');
              print('Image URL isEmpty: ${imageUrl.isEmpty}');

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          imageUrl.isNotEmpty
                              ? Image.network(
                                imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading image: $error');
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: 30,
                                    ),
                                  );
                                },
                              )
                              : Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.home,
                                  color: Colors.grey,
                                  size: 30,
                                ),
                              ),
                    ),
                  ),
                  title: Text(title),
                  subtitle: Text(
                    '$description\n📍 $location',
                    style: TextStyle(height: 1.3),
                  ),
                  isThreeLine: true,
                  trailing: Text('\$$price'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}