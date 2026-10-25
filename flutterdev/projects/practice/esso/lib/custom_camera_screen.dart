
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:path_provider/path_provider.dart';
class CustomCameraScreen extends StatefulWidget {
  const CustomCameraScreen({super.key});

  @override
  State<CustomCameraScreen> createState() =>
      _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _errorMessage;
  Uint8List? _capturedBytes;
  bool _isCropping = false;

  final CropController _cropController = CropController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No camera was found on this device.');
      }

      final camera = _cameras.firstWhere(
            (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _controller = controller;
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _isInitializing = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final image = await controller.takePicture();
      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _capturedBytes = bytes;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not capture photo: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }
  Future<void> _handleCropResult(CropResult result) async {
    if (result is CropSuccess) {
      try {
        final directory = await getTemporaryDirectory();

        final file = File(
          '${directory.path}/inkora_page_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        await file.writeAsBytes(result.croppedImage);

        if (!mounted) return;

        Navigator.of(context).pop(XFile(file.path));
      } catch (error) {
        if (!mounted) return;

        setState(() => _isCropping = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save cropped page: $error'),
          ),
        );
      }
    } else if (result is CropFailure) {
      if (!mounted) return;

      setState(() => _isCropping = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not crop page: ${result.cause}'),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Capture a page'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
        body: SafeArea(
          child: _isInitializing
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isInitializing = true;
                        _errorMessage = null;
                      });
                      _initializeCamera();
                    },
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          )
              : _capturedBytes != null
              ? Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Adjust the corners to select your page.',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Crop(
                  image: _capturedBytes!,
                  controller: _cropController,
                  interactive: true,
                  baseColor: Colors.black,
                  maskColor: Colors.black54,
                  onCropped: _handleCropResult,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isCropping
                            ? null
                            : () {
                          setState(() {
                            _capturedBytes = null;
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isCropping
                            ? null
                            : () {
                          setState(() => _isCropping = true);
                          _cropController.crop();
                        },
                        icon: const Icon(Icons.check),
                        label: Text(
                          _isCropping ? 'Cropping...' : 'Use page',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
              : Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Place your handwritten page inside the frame.',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final previewSize =
                    _controller!.value.previewSize!;

                    return ClipRect(
                      child: SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: previewSize.height,
                            height: previewSize.width,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(_controller!),
                                Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: IconButton.filled(
                  onPressed:
                  _isCapturing ? null : _capturePhoto,
                  icon: const Icon(Icons.camera_alt),
                  iconSize: 38,
                  padding: const EdgeInsets.all(18),
                  tooltip: 'Capture page',
                ),
              ),
            ],
          ),
        ),
    );
  }
}
