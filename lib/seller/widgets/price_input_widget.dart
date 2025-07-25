import 'package:flutter/material.dart';
import 'package:smartspace/seller/widgets/price_choice_modal.dart';

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

  void _showPriceChoiceModal(BuildContext context) {
    if (predictedPrice == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => PriceChoiceModal(
            predictedPrice: predictedPrice!,
            useCustomPrice: useCustomPrice,
            onChoiceChanged: onUseCustomPriceChanged,
            predictionData: predictionData,
          ),
    );
  }

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
            suffixIcon:
                predictedPrice != null
                    ? IconButton(
                      icon: Icon(Icons.tune, color: Colors.blue[700]),
                      onPressed: () => _showPriceChoiceModal(context),
                      tooltip: 'Choose pricing option',
                    )
                    : null,
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
        const SizedBox(height: 8),

        // Compact prediction indicator
        if (predictedPrice != null) ...[
          InkWell(
            onTap: () => _showPriceChoiceModal(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(50, 67, 160, 151),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color.fromARGB(255, 67, 160, 151),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  if (isAutoPredicating)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color.fromARGB(255, 67, 160, 151),
                      ),
                    )
                  else
                    const Icon(
                      Icons.auto_awesome,
                      color: Color.fromARGB(255, 67, 160, 151),
                      size: 18,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          useCustomPrice
                              ? 'Using custom price'
                              : 'Using AI predicted price',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 67, 160, 151),
                          ),
                        ),
                        if (!useCustomPrice)
                          Text(
                            'UGX ${predictedPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 67, 160, 151),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.tune,
                    color: Color.fromARGB(255, 67, 160, 151),
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 67, 160, 151),
                    ),
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
