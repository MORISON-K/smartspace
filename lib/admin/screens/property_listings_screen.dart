import 'package:flutter/material.dart';

class Property {
  final String title;
  final String location;
  final double price;
  final String status; // e.g. 'Pending', 'Approved', 'Rejected'

  Property({
    required this.title,
    required this.location,
    required this.price,
    required this.status,
  });
}







class PropertyListingsScreen extends StatefulWidget {
  const PropertyListingsScreen({super.key});

  @override
  State<PropertyListingsScreen> createState() => _PropertyListingsScreenState();
}

class _PropertyListingsScreenState extends State<PropertyListingsScreen> {
  List<Property> properties = [
    Property(
      title: '2 Bedroom Apartment',
      location: 'Kampala, Uganda',
      price: 50000,
      status: 'Pending',
    ),
    Property(
      title: 'Luxury Villa',
      location: 'Entebbe',
      price: 150000,
      status: 'Approved',
    ),
  ];

  void _updateStatus(Property property, String newStatus) {
    setState(() {
      final index = properties.indexOf(property);
      properties[index] = Property(
        title: property.title,
        location: property.location,
        price: property.price,
        status: newStatus,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Property Listings')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: properties.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final property = properties[index];
          return Card(
            child: ListTile(
              title: Text(property.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location: ${property.location}'),
                  Text('Price: UGX ${property.price.toStringAsFixed(0)}'),
                  Text(
                    'Status: ${property.status}',
                    style: TextStyle(
                      color: property.status == 'Approved'
                          ? Colors.green
                          : (property.status == 'Rejected'
                              ? Colors.red
                              : Colors.orange),
                    ),
                  ),
                ],
              ),
              trailing: property.status == 'Pending'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () =>
                              _updateStatus(property, 'Approved'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () =>
                              _updateStatus(property, 'Rejected'),
                        ),
                      ],
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
