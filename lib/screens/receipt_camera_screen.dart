import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/receipt_ocr_service.dart';
import 'receipt_review_screen.dart';

/// Camera screen for capturing receipt images with OCR processing
class ReceiptCameraScreen extends StatefulWidget {
  final String userId;

  const ReceiptCameraScreen({super.key, required this.userId});

  @override
  State<ReceiptCameraScreen> createState() => _ReceiptCameraScreenState();
}

class _ReceiptCameraScreenState extends State<ReceiptCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isFlashOn = false;
  bool _showGrid = true;
  bool _isProcessing = false;
  final ImagePicker _imagePicker = ImagePicker();
  final ReceiptOCRService _ocrService = ReceiptOCRService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  /// Initialize camera
  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isInitializing = true;
      });

      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
        }
        return;
      }

      // Use back camera by default
      _selectedCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

      // Initialize camera controller
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Set flash mode
      await _cameraController!.setFlashMode(FlashMode.off);

      // Enable auto-focus
      if (_cameraController!.value.isInitialized) {
        await _cameraController!.setFocusMode(FocusMode.auto);
      }

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _showErrorSnackBar('Failed to initialize camera: $e');
      }
    }
  }

  /// Toggle flash on/off
  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(newFlashMode);
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      print('Error toggling flash: $e');
      _showErrorSnackBar('Failed to toggle flash');
    }
  }

  /// Toggle grid overlay
  void _toggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
    });
  }

  /// Capture image from camera
  Future<void> _captureImage() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      // Capture image
      final XFile image = await _cameraController!.takePicture();

      // Save to temp directory
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savePath = path.join(tempDir.path, fileName);

      // Copy file to temp directory
      await File(image.path).copy(savePath);

      // Process with OCR
      await _processImage(savePath);
    } catch (e) {
      print('Error capturing image: $e');
      _showErrorSnackBar('Failed to capture image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        // Save to temp directory
        final Directory tempDir = await getTemporaryDirectory();
        final String fileName =
            'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String savePath = path.join(tempDir.path, fileName);

        // Copy file to temp directory
        await File(image.path).copy(savePath);

        // Process with OCR
        await _processImage(savePath);
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Process image with OCR and navigate to review screen
  Future<void> _processImage(String imagePath) async {
    try {
      // Show processing indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Processing receipt...'),
              ],
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Run OCR
      final ExtractedReceipt receipt = await _ocrService.scanReceipt(imagePath);

      if (mounted) {
        // Hide processing indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Navigate to review screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ReceiptReviewScreen(
              userId: widget.userId,
              imagePath: imagePath,
              extractedReceipt: receipt,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorSnackBar('Failed to process receipt: $e');
      }
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          _buildCameraPreview(),

          // Grid overlay
          if (_showGrid) _buildGridOverlay(),

          // Top controls
          _buildTopControls(),

          // Bottom controls
          _buildBottomControls(),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build camera preview
  Widget _buildCameraPreview() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera not available',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick from Gallery'),
            ),
          ],
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  /// Build grid overlay (Rule of thirds)
  Widget _buildGridOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildGridCell(),
                  _buildGridCell(),
                  _buildGridCell(),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  _buildGridCell(),
                  _buildGridCell(),
                  _buildGridCell(),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  _buildGridCell(),
                  _buildGridCell(),
                  _buildGridCell(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build single grid cell
  Widget _buildGridCell() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white12, width: 0.5),
        ),
      ),
    );
  }

  /// Build top controls (Flash, Grid, Close)
  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            _buildControlButton(
              icon: Icons.close,
              onPressed: () => Navigator.of(context).pop(),
            ),

            Row(
              children: [
                // Flash toggle
                _buildControlButton(
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  onPressed: _toggleFlash,
                  isActive: _isFlashOn,
                ),
                const SizedBox(width: 12),

                // Grid toggle
                _buildControlButton(
                  icon: Icons.grid_on,
                  onPressed: _toggleGrid,
                  isActive: _showGrid,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build bottom controls (Gallery, Capture, Info)
  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gallery button
              _buildGalleryButton(),

              // Capture button
              _buildCaptureButton(),

              // Info button
              _buildInfoButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build control button
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.white24 : Colors.black45,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon),
        color: isActive ? Colors.amber : Colors.white,
        onPressed: onPressed,
      ),
    );
  }

  /// Build gallery button
  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: _pickFromGallery,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: const Icon(
          Icons.photo_library,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  /// Build capture button
  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _captureImage,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12, width: 2),
          ),
        ),
      ),
    );
  }

  /// Build info button
  Widget _buildInfoButton() {
    return GestureDetector(
      onTap: _showHelpDialog,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: const Icon(
          Icons.info_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  /// Show help dialog
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text('Receipt Scanning Tips'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📸 Camera Tips:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Ensure receipt is well-lit and flat'),
              Text('• Avoid shadows and glare'),
              Text('• Use grid to align receipt'),
              Text('• Fill frame with receipt'),
              SizedBox(height: 16),
              Text(
                '💡 Best Results:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Clean, uncrumpled receipts'),
              Text('• Good contrast and lighting'),
              Text('• Horizontal orientation'),
              Text('• Printed receipts (not handwritten)'),
              SizedBox(height: 16),
              Text(
                '⚡ Flash:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Use flash in low light'),
              Text('• Avoid direct flash on glossy receipts'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
