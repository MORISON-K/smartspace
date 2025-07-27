import 'package:flutter/material.dart';

class BasicInfoWidget extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController acreageController;
  final TextEditingController descriptionController;
  final String? selectedTenure;
  final String? selectedLandUse;
  final List<String> tenureOptions;
  final Function(String?) onTenureChanged;
  final Function(String?) onLandUseChanged;
  final Function(String) onAcreageChanged;
  final InputDecoration Function(String, {IconData? prefixIcon})
  inputDecoration;

  const BasicInfoWidget({
    super.key,
    required this.phoneController,
    required this.acreageController,
    required this.descriptionController,
    required this.selectedTenure,
    required this.selectedLandUse,
    required this.tenureOptions,
    required this.onTenureChanged,
    required this.onLandUseChanged,
    required this.onAcreageChanged,
    required this.inputDecoration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Phone number field
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: inputDecoration(
            'Mobile Number',
            prefixIcon: Icons.phone,
          ).copyWith(
            prefixText: '256 ',
            prefixStyle: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            hintText: '700123456',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Mobile Number is required';
            }
            // Remove any spaces and check if it's a valid phone number
            String cleanedValue = value.replaceAll(' ', '');
            if (cleanedValue.length < 9 || cleanedValue.length > 10) {
              return 'Enter a valid mobile number (9-10 digits)';
            }
            if (!RegExp(r'^[0-9]+$').hasMatch(cleanedValue)) {
              return 'Enter only numbers';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Tenure dropdown
        DropdownButtonFormField<String>(
          decoration: inputDecoration(
            'Land Tenure Type',
            prefixIcon: Icons.gavel,
          ).copyWith(helperText: "Select the type of land ownership"),
          value: selectedTenure,
          items:
              tenureOptions.map((String tenure) {
                return DropdownMenuItem<String>(
                  value: tenure,
                  child: Text(tenure),
                );
              }).toList(),
          onChanged: onTenureChanged,
          validator:
              (value) =>
                  value == null ? 'Please select land tenure type' : null,
        ),
        const SizedBox(height: 12),

        // Acreage field
        TextFormField(
          controller: acreageController,
          keyboardType: TextInputType.number,
          decoration: inputDecoration(
            'Acreage (in acres)',
            prefixIcon: Icons.crop_free,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Acreage is required';
            }
            if (double.tryParse(value) == null) {
              return 'Enter a valid number';
            }
            return null;
          },
          onChanged: (value) {
            // Trigger auto-prediction after user stops typing for 1 second
            Future.delayed(const Duration(seconds: 1), () {
              if (acreageController.text == value &&
                  double.tryParse(value) != null) {
                onAcreageChanged(value);
              }
            });
          },
        ),
        const SizedBox(height: 12),

        // Land Use dropdown
        DropdownButtonFormField<String>(
          decoration: inputDecoration('Land Use', prefixIcon: Icons.business),
          value: selectedLandUse,
          items:
              [
                    'Residential',
                    'Commercial',
                    'Agricultural',
                    'Industrial',
                    'Mixed',
                  ]
                  .map((use) => DropdownMenuItem(value: use, child: Text(use)))
                  .toList(),
          onChanged: onLandUseChanged,
          validator: (value) => value == null ? 'Please select land use' : null,
        ),
        const SizedBox(height: 12),

        // Description field
        TextFormField(
          controller: descriptionController,
          decoration: inputDecoration(
            'Description (max 30 words)',
            prefixIcon: Icons.description,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Description is required';
            }
            // Count words by splitting on whitespace and filtering empty strings
            final words =
                value
                    .trim()
                    .split(RegExp(r'\s+'))
                    .where((word) => word.isNotEmpty)
                    .toList();
            if (words.length > 30) {
              return 'Description must be 30 words or less (currently ${words.length} words)';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
