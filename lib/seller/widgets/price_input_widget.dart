import 'package:flutter/material.dart';

class PriceInputWidget extends StatelessWidget {
  final TextEditingController priceController;
  final double? predictedPrice;
  final bool useCustomPrice;
  final bool isAutoPredicating;
  final bool hasAutoPredicted;
  final Function(bool) onUseCustomPriceChanged;
  final InputDecoration Function(String, {IconData? prefixIcon})
  inputDecoration;
  final dynamic predictionData;

  const PriceInputWidget({
    super.key,
    required this.priceController,
    required this.predictedPrice,
    required this.useCustomPrice,
    required this.isAutoPredicating,
    required this.hasAutoPredicted,
    required this.onUseCustomPriceChanged,
    required this.inputDecoration,
    this.predictionData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Price input field
        TextFormField(
          controller: priceController,
          keyboardType: TextInputType.number,
          enabled: predictedPrice == null || useCustomPrice,
          decoration: inputDecoration(
            'Price (UGX)',
            prefixIcon: Icons.attach_money,
          ).copyWith(
            filled: predictedPrice != null && !useCustomPrice,
            fillColor:
                predictedPrice != null && !useCustomPrice
                    ? Colors.grey[100]
                    : null,
            helperText:
                predictedPrice != null && !useCustomPrice
                    ? 'Using AI predicted price'
                    : 'Enter your desired price',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Price is required';
            }
            if (double.tryParse(value) == null) {
              return 'Enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Prediction info card
        if (predictedPrice != null) ...[
          Card(
            elevation: 2,
            color: const Color.fromARGB(147, 247, 246, 246),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          predictionData != null
                              ? 'AI Predicted Value'
                              : 'Auto-Generated Value',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isAutoPredicating)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Text(
                      'UGX ${predictedPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Choose your pricing option:',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      RadioListTile<bool>(
                        title: const Text(
                          'Use AI predicted price',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'UGX ${predictedPrice!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 10, 27, 11),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: false,
                        groupValue: useCustomPrice,
                        onChanged: (value) => onUseCustomPriceChanged(value!),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<bool>(
                        title: const Text(
                          'Set my own price',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Enter your preferred price below',
                          style: TextStyle(
                            color: Color.fromARGB(255, 26, 48, 5),
                            fontSize: 12,
                          ),
                        ),
                        value: true,
                        groupValue: useCustomPrice,
                        onChanged: (value) => onUseCustomPriceChanged(value!),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
