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
  List<Property> filteredProperties = [];

  bool _isLoading = true;

  String _selectedStatus = 'All';
  String _searchQuery = '';

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('listings').orderBy('createdAt', descending: true).get();
      final list =
          snapshot.docs
              .map((doc) => Property.fromFirestore(doc.data(), doc.id))
              .toList();

      if (!mounted) return;

      setState(() {
        properties = list;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      print('Error fetching properties: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Property> filtered = properties;

    if (_selectedStatus != 'All') {
      filtered =
          filtered
              .where(
                (p) => p.status.toLowerCase() == _selectedStatus.toLowerCase(),
              )
              .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (p) => p.location.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
    }

    setState(() {
      filteredProperties = filtered;
    });
  }

  void _updateStatus(Property property, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(property.id)
          .update({'status': newStatus.toLowerCase()});

      if (!mounted) return;

        setState(() {
          final index = properties.indexOf(property);
          properties[index] = Property(
            id: property.id,
            title: property.title,
            description: property.description,
            location: property.location,
            category: property.category,
            sellerPrice: property.sellerPrice,
            predictedPrice: property.predictedPrice,
            images: property.images,
            pdfUrl: property.pdfUrl,
            status: newStatus.toLowerCase(),
          );
        });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Property ${newStatus.toLowerCase()} successfully.'),
        ),
      );

      _applyFilters(); // Refresh filtered list
    } catch (e) {
      print('Error updating status: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  void _confirmAction(Property property, String status) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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
                  backgroundColor:
                      status == 'approved' ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(status == 'approved' ? 'Approve' : 'Reject'),
              ),
            ],
          ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Property Listings')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.filter_alt_outlined,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<String>(
                                  value: _selectedStatus,
                                  underline: const SizedBox(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                  items:
                                      _statusOptions
                                          .map(
                                            (status) => DropdownMenuItem(
                                              value: status,
                                              child: Text(status),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedStatus = value);
                                      _applyFilters();
                                    }
                                  },
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.search,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: 'Search location',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                    ),
                                    onChanged: (value) {
                                      _searchQuery = value;
                                      _applyFilters();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child:
                        filteredProperties.isEmpty
                            ? const Center(child: Text('No matching listings.'))
                            : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredProperties.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final property = filteredProperties[index];
                                return GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => PropertyDetailsScreen(
                                              property: property,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            property.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            property.location,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Seller Price: UGX ${property.sellerPrice}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                'Predicted Price: UGX ${property.predictedPrice}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildStatusBadge(
                                                property.status,
                                              ),
                                              if (property.status == 'pending')
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.check,
                                                        color: Colors.green,
                                                      ),
                                                      onPressed:
                                                          () => _confirmAction(
                                                            property,
                                                            'approved',
                                                          ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.close,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed:
                                                          () => _confirmAction(
                                                            property,
                                                            'rejected',
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
