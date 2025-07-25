import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MediaUploadWidget extends StatelessWidget {
  final List<XFile> images;
  final File? pdfFile;
  final VoidCallback onPickImages;
  final VoidCallback onPickPDF;
  final ButtonStyle Function() buttonStyle;

  const MediaUploadWidget({
    super.key,
    required this.images,
    required this.pdfFile,
    required this.onPickImages,
    required this.onPickPDF,
    required this.buttonStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Upload Images button
        ElevatedButton.icon(
          onPressed: onPickImages,
          icon: const Icon(Icons.photo_library),
          label: const Text("Upload Images"),
          style: buttonStyle(),
        ),

        // Display selected images as thumbnails
        if (images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  images
                      .map(
                        (img) => Image.file(
                          File(img.path),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                      .toList(),
            ),
          ),
        const SizedBox(height: 12),

        // Upload PDF button
        ElevatedButton.icon(
          onPressed: onPickPDF,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text("Attach Land Title (PDF)"),
          style: buttonStyle(),
        ),

        // Display selected PDF file name
        if (pdfFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Attached: ${pdfFile!.path.split('/').last}",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
