
import 'package:image_picker/image_picker.dart';

class DocumentImportService {
  DocumentImportService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Select multiple handwritten page images from the gallery.
  Future<List<XFile>> pickImages({
    int maxImages = 100,
  }) async {
    if (maxImages < 1) {
      throw ArgumentError('maxImages must be at least 1.');
    }

    final List<XFile> selectedImages =
    await _picker.pickMultiImage();

    // The user may cancel the picker.
    if (selectedImages.isEmpty) {
      return [];
    }

    // Never silently discard extra pages.
    if (selectedImages.length > maxImages) {
      throw StateError(
        'You selected ${selectedImages.length} images. '
            'Please select no more than $maxImages.',
      );
    }

    return selectedImages;
  }

  /// Capture one page using the device camera.
  Future<XFile?> captureImage() async {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
  }
}
