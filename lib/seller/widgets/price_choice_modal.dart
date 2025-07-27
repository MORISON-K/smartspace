import 'package:flutter/material.dart';

class PriceChoiceModal extends StatefulWidget {
  final double predictedPrice;
  final bool useCustomPrice;
  final Function(bool) onChoiceChanged;
  final dynamic predictionData;

  const PriceChoiceModal({
    super.key,
    required this.predictedPrice,
    required this.useCustomPrice,
    required this.onChoiceChanged,
    this.predictionData,
  });

  @override
  State<PriceChoiceModal> createState() => _PriceChoiceModalState();
}

class _PriceChoiceModalState extends State<PriceChoiceModal> {
  late bool _tempUseCustomPrice;

  @override
  void initState() {
    super.initState();
    _tempUseCustomPrice = widget.useCustomPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width < 400 ? 16 : 24,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.predictionData != null
                          ? 'AI Predicted Value'
                          : 'Auto-Generated Value',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Predicted value display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'Predicted Value',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UGX ${widget.predictedPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Options
              Text(
                'Choose your pricing option:',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Option 1: Use AI predicted price
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        !_tempUseCustomPrice ? Colors.blue : Colors.grey[300]!,
                    width: !_tempUseCustomPrice ? 2 : 1,
                  ),
                  color: !_tempUseCustomPrice ? Colors.blue[50] : Colors.white,
                ),
                child: RadioListTile<bool>(
                  title: const Text(
                    'Use AI predicted price',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        'UGX ${widget.predictedPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Recommended based on market analysis',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                  value: false,
                  groupValue: _tempUseCustomPrice,
                  onChanged: (value) {
                    setState(() {
                      _tempUseCustomPrice = value!;
                    });
                  },
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 8),

              // Option 2: Set custom price
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _tempUseCustomPrice ? Colors.orange : Colors.grey[300]!,
                    width: _tempUseCustomPrice ? 2 : 1,
                  ),
                  color: _tempUseCustomPrice ? Colors.orange[50] : Colors.white,
                ),
                child: RadioListTile<bool>(
                  title: const Text(
                    'Set my own price',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2),
                      Text(
                        'Enter your preferred price',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                  value: true,
                  groupValue: _tempUseCustomPrice,
                  onChanged: (value) {
                    setState(() {
                      _tempUseCustomPrice = value!;
                    });
                  },
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onChoiceChanged(_tempUseCustomPrice);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 23, 149, 99),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Apply Choice',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
