import 'package:flutter/material.dart';

class ListingDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String location;
  final String description;

  const ListingDetailScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.location,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Listing Details"),
        backgroundColor: Color.fromARGB(255, 164, 192, 221),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Color.fromARGB(255, 164, 192, 221),
                  ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.attach_money, color: Color.fromARGB(255, 164, 192, 221)),
                const SizedBox(width: 6),
                Text(
                  'Price: \$$price',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Color.fromARGB(255, 164, 192, 221)),
                const SizedBox(width: 6),
                Text(
                  'Location: $location',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.description, color: Color.fromARGB(255, 164, 192, 221)),
                const SizedBox(width: 6),
                Text(
                  'Description:',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
