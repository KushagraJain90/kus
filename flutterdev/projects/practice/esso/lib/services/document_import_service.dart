
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class DocumentImportService {
  DocumentImportService({
    ImagePicker? picker,
    ImageCropper? cropper,
  })  : _picker = picker ?? ImagePicker(),
        _cropper = cropper ?? ImageCropper();

  final ImagePicker _picker;
  final ImageCropper _cropper;

  /// Select handwritten page images from the gallery.
  Future<List<XFile>> pickImages({
    int maxImages = 100,
  }) async {
    if (maxImages < 1) {
      throw ArgumentError('maxImages must be at least 1.');
    }

    final selectedImages = await _picker.pickMultiImage();

    if (selectedImages.isEmpty) {
      return [];
    }

    if (selectedImages.length > maxImages) {
      throw StateError(
        'You selected ${selectedImages.length} images. '
            'Please select no more than $maxImages.',
      );
    }

    return selectedImages;
  }

  /// Capture one page and open the crop interface.
  Future<XFile?> captureImage() async {
    final capturedImage = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );

    if (capturedImage == null) {
      return null;
    }

    final croppedImage = await _cropper.cropImage(
      sourcePath: capturedImage.path,
      compressQuality: 95,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop your page',
          toolbarColor: const Color(0xFF536DFE),
          toolbarWidgetColor: const Color(0xFFFFFFFF),
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
      ],
    );

    // The user may cancel cropping.
    if (croppedImage == null) {
      return null;
    }

    return XFile(croppedImage.path);
  }
}

