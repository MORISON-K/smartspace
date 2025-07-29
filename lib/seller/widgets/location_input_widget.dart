import 'package:flutter/material.dart';

class LocationInputWidget extends StatelessWidget {
  final TextEditingController locationController;
  final List<String> allowedLocations;
  final bool isLoadingLocations;
  final String? errorMessage;
  final Function(String) onLocationChanged;
  final Function(String) onLocationSelected;
  final InputDecoration Function(String, {IconData? prefixIcon})
  inputDecoration;

  const LocationInputWidget({
    super.key,
    required this.locationController,
    required this.allowedLocations,
    required this.isLoadingLocations,
    required this.errorMessage,
    required this.onLocationChanged,
    required this.onLocationSelected,
    required this.inputDecoration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Loading indicator
        if (isLoadingLocations)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text("Loading locations..."),
                ],
              ),
            ),
          )
        // Autocomplete field
        else if (allowedLocations.isNotEmpty)
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return allowedLocations.where((String option) {
                return option.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                );
              });
            },
            fieldViewBuilder: (
              context,
              controller,
              focusNode,
              onEditingComplete,
            ) {
              // Sync the autocomplete controller with our location controller
              if (locationController.text.isNotEmpty &&
                  controller.text.isEmpty) {
                controller.text = locationController.text;
              }
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: inputDecoration(
                  'Location',
                  prefixIcon: Icons.location_city,
                ).copyWith(
                  helperText:
                      "Select a location from the dropdown for AI prediction",
                  suffixIcon:
                      allowedLocations.contains(controller.text)
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : controller.text.isNotEmpty
                          ? Icon(Icons.error, color: Colors.red)
                          : null,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  if (!allowedLocations.contains(value)) {
                    return "Please select a valid location from the dropdown for AI prediction.";
                  }
                  return null;
                },
                onChanged: (value) {
                  // Only call onLocationChanged if the location is valid
                  if (allowedLocations.contains(value)) {
                    onLocationChanged(value);
                  }
                },
              );
            },
            onSelected: (selection) {
              locationController.text = selection;
              onLocationSelected(selection);
            },
          )
        // Fallback field when locations cannot be loaded
        else
          Column(
            children: [
              TextFormField(
                controller: locationController,
                decoration: inputDecoration(
                  'Location',
                  prefixIcon: Icons.location_city,
                ).copyWith(
                  helperText:
                      "Location entered manually (AI prediction unavailable)",
                  suffixIcon: Icon(Icons.warning, color: Colors.orange),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Don't trigger auto-prediction for manual entry
                  // as we can't validate against the allowed locations
                  locationController.text = value;
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI valuation is not available for manually entered locations.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
