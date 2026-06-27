import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/face_service.dart';
import '../../providers/auth_provider.dart';

class FaceVerifyScreen extends StatefulWidget {
  const FaceVerifyScreen({super.key});

  @override
  State<FaceVerifyScreen> createState() => _FaceVerifyScreenState();
}

class _FaceVerifyScreenState extends State<FaceVerifyScreen> {
  CameraController? _cameraController;
  final FaceService _faceService = FaceService();
  bool _isProcessing = false;
  String _statusMessage = "Position your face to cast your vote";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, 
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => _statusMessage = "Camera Error: $e");
    }
  }

  Future<void> _verifyAndAuthenticate() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "Verifying biometric identity...";
    });

    try {
      // 1. Fetch user's securely stored embedding
      final user = Provider.of<AuthStateProvider>(context, listen: false).currentUser;
      if (user == null || user.faceEmbedding == null) {
        setState(() {
          _statusMessage = "No face profile found. Register in settings.";
          _isProcessing = false;
        });
        return;
      }

      // 2. Capture live image
      final XFile picture = await _cameraController!.takePicture();
      final InputImage inputImage = InputImage.fromFilePath(picture.path);

      // 3. Detect face
      final face = await _faceService.detectFace(inputImage);
      if (face == null) {
        setState(() {
          _statusMessage = "No face detected. Please try again.";
          _isProcessing = false;
        });
        return;
      }

      // 4. Extract live embedding
      final liveEmbedding = await _faceService.extractEmbedding(face, null as dynamic);
      final storedEmbedding = user.faceEmbedding!;

      // 5. Compare mathematically (Blueprint Section 10)
      final similarity = _faceService.cosineSimilarity(liveEmbedding, storedEmbedding);
      
      // Verification Threshold (0.85 as per blueprint)
      if (similarity > 0.85) {
        if (mounted) {
          // Success! Return true to the CastVoteScreen to authorize the transaction
          Navigator.pop(context, true); 
        }
      } else {
        setState(() {
          _statusMessage = "Verification failed. Identity mismatch.";
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error: ${e.toString().replaceAll('Exception:', '')}";
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Biometric Voting', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 4),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)
                  ]
                ),
                child: ClipOval(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _verifyAndAuthenticate,
                  icon: _isProcessing 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.how_to_vote),
                  label: Text(_isProcessing ? 'Verifying...' : 'Authorize Vote'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}