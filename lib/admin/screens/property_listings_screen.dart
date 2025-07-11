import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'property_details_screen.dart';
import 'package:smartspace/admin/models/properties.dart';

class PropertyListingsScreen extends StatefulWidget {
  const PropertyListingsScreen({super.key});

  @override
  State<PropertyListingsScreen> createState() => _PropertyListingsScreenState();
}

class _PropertyListingsScreenState extends State<PropertyListingsScreen> {
  List<Property> properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('listings').get();
      final list = snapshot.docs
          .map((doc) => Property.fromFirestore(doc.data(), doc.id))
          .toList();

      setState(() {
        properties = list;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching properties: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updateStatus(Property property, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(property.id) // ✅ Use document ID
          .update({'status': newStatus.toLowerCase()});

      setState(() {
        final index = properties.indexOf(property);
        properties[index] = Property(
          id: property.id,
          title: property.title,
          description: property.description,
          location: property.location,
          category: property.category,
          price: property.price,
          images: property.images,
          pdfUrl: property.pdfUrl,
          status: newStatus.toLowerCase(),
        );
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Property ${newStatus.toLowerCase()} successfully.')),
      );
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  void _confirmAction(Property property, String status) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          '${status == 'approved' ? 'Approve' : 'Reject'} Property',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${status == 'approved' ? 'approve' : 'reject'} this property?',
            ),
            const SizedBox(height: 8),
            Text(
              'Property: ${property.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Location: ${property.location}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(property, status);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(status == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Property Listings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : properties.isEmpty
              ? const Center(child: Text('No listings found.'))
              : ListView.separated(
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
                            Text('Price: UGX ${property.price}'),
                            Text(
                              'Status: ${property.status}',
                              style: TextStyle(
                                color: property.status == 'approved'
                                    ? Colors.green
                                    : (property.status == 'rejected'
                                        ? Colors.red
                                        : Colors.orange),
                              ),
                            ),
                          ],
                        ),
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PropertyDetailsScreen(property: property),
                            ),
                          );

                          if (updated == true) {
                            _fetchProperties(); // refresh the list
                          }
                        },
                        trailing: property.status == 'pending'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                    onPressed: () =>
                                        _confirmAction(property, 'approved'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _confirmAction(property, 'rejected'),
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
