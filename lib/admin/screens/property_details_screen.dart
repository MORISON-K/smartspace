import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartspace/admin/models/properties.dart';
import 'pdf_viewer_screen.dart';


class PropertyDetailsScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  String? currentStatus;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.property.status; // Assuming Property model has a status field
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    IconData? icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed, // Made nullable to handle disabled state
    bool isDisabled = false,
  }) {
    final buttonColor = isDisabled ? Colors.grey : color;
    
    if (icon == null) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openPdf(BuildContext context, String url) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(pdfUrl: url, title: 'Property Document'),
      ),
    );
  }

  void _updateStatus(BuildContext context, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.property.id)
          .update({'status': status});

      setState(() {
        currentStatus = status;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Property $status successfully.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  void _confirmAction(BuildContext context, String status) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          '${status == 'approved' ? 'Approve' : 'Reject'} Property',
        ),
        content: Text(
          'Are you sure you want to ${status == 'approved' ? 'approve' : 'reject'} this property?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(context, status);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    if (currentStatus == null) return const SizedBox.shrink();
    
    Color chipColor;
    IconData chipIcon;
    
    switch (currentStatus) {
      case 'approved':
        chipColor = Colors.green;
        chipIcon = Icons.check_circle;
        break;
      case 'rejected':
        chipColor = Colors.red;
        chipIcon = Icons.cancel;
        break;
      case 'pending':
        chipColor = Colors.orange;
        chipIcon = Icons.pending;
        break;
      default:
        chipColor = Colors.grey;
        chipIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Chip(
        avatar: Icon(chipIcon, color: Colors.white, size: 18),
        label: Text(
          'Status: ${currentStatus!.toUpperCase()}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: chipColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property.category, overflow: TextOverflow.ellipsis),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Status Chip
            _buildStatusChip(),
            
            // Property Details
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      Icons.location_on,
                      'Location:',
                      widget.property.location,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.currency_exchange,
                      'Price:',
                      widget.property.price,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.description,
                      'Description:',
                      widget.property.description,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Images
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Images:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.property.images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.property.images[index],
                                width: MediaQuery.of(context).size.width * 0.8,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width * 0.8,
                                    height: 200,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // PDF
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attached PDF:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf,
                            size: 32,
                            color: Colors.red.shade600,
                          ),
                        ),
                        title: const Text(
                          'Property Document',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text('Tap to view PDF'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _openPdf(context, widget.property.pdfUrl),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Property Actions:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: currentStatus == 'approved' ? 'Approved' : 'Approve',
                      color: Colors.green,
                      onPressed: currentStatus == 'approved' 
                          ? null 
                          : () => _confirmAction(context, 'approved'),
                      isDisabled: currentStatus == 'approved',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: 'Request document',
                      color: Colors.blue,
                      onPressed: () => _showDocumentRequestDialog(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: currentStatus == 'rejected' ? 'Rejected' : 'Reject',
                      color: Colors.red,
                      onPressed: currentStatus == 'rejected' 
                          ? null 
                          : () => _confirmAction(context, 'rejected'),
                      isDisabled: currentStatus == 'rejected',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentRequestDialog(BuildContext context) {
    final TextEditingController requestController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Request Additional Document'),
        content: TextField(
          controller: requestController,
          decoration: const InputDecoration(
            hintText: 'Describe what document is needed',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendDocumentRequest(context, requestController.text);
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _sendDocumentRequest(BuildContext context, String message) async {
    try {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.property.id)
          .collection('documentRequests')
          .add({
            'message': message,
            'status': 'pending',
            'timestamp': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document request sent to seller.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    }
  }
}
