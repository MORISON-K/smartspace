import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Listings"),
        backgroundColor: Color.fromARGB(255, 164, 192, 221),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('listings').snapshots(),
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
              final imageUrl = data['image_url'] ?? '';
              final description = data['description'] ?? 'No description'; //
              // final title = data['title'] ?? 'No title';
              final price = data['price'] ?? 'N/A';
              final location = data['location'] ?? 'No location';

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  leading:
                      imageUrl.isNotEmpty
                          ? Image.network(
                            imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.error);
                            },
                          )
                          : Icon(Icons.home),
                  // title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description),
                      Text(
                        '📍 $location',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
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
