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
                  helperText: "Start typing to choose a valid location",
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  if (!allowedLocations.contains(value)) {
                    return "Invalid location. Please select from the suggestions.";
                  }
                  return null;
                },
                onChanged: onLocationChanged,
              );
            },
            onSelected: onLocationSelected,
          )
        // Fallback field
        else
          TextFormField(
            controller: locationController,
            decoration: inputDecoration(
              'Location',
              prefixIcon: Icons.location_city,
            ).copyWith(
              helperText: "Enter the location (auto-suggestions unavailable)",
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Location is required';
              }
              return null;
            },
            onChanged: (value) {
              // Trigger auto-prediction after user stops typing for 1 second
              Future.delayed(const Duration(seconds: 1), () {
                if (locationController.text == value) {
                  onLocationChanged(value);
                }
              });
            },
          ),
        const SizedBox(height: 12),

        // Error message
        if (errorMessage != null && !isLoadingLocations) ...[
          Card(
            elevation: 2,
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location suggestions unavailable. You can still enter location manually.',
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
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
