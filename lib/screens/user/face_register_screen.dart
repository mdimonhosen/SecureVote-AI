import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/face_service.dart';
import '../../providers/auth_provider.dart';

class FaceRegisterScreen extends StatefulWidget {
  const FaceRegisterScreen({super.key});

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen> {
  CameraController? _cameraController;
  final FaceService _faceService = FaceService();
  bool _isProcessing = false;
  String _statusMessage = "Position your face in the frame";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Get the list of available cameras
      final cameras = await availableCameras();
      
      // Find the front-facing camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // Medium is good enough for Face ID and saves memory
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => _statusMessage = "Error initializing camera: $e");
    }
  }

  Future<void> _captureAndRegister() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "Scanning face...";
    });

    try {
      // 1. Take a picture
      final XFile picture = await _cameraController!.takePicture();
      final InputImage inputImage = InputImage.fromFilePath(picture.path);

      // 2. Detect face using Google ML Kit
      final face = await _faceService.detectFace(inputImage);
      
      if (face == null) {
        setState(() {
          _statusMessage = "No face detected. Please try again.";
          _isProcessing = false;
        });
        return;
      }

      // 3. Extract Embedding (Simulated in FaceService)
      // Note: CameraImage conversion to embedding requires TFLite integration in production
      setState(() => _statusMessage = "Generating secure biometric profile...");
      final embedding = await _faceService.extractEmbedding(face, null as dynamic);

      // 4. Save to Supabase
      if (!mounted) return;
      final user = Provider.of<AuthStateProvider>(context, listen: false).currentUser;
      if (user != null) {
        await Supabase.instance.client.from('users').update({
          'face_registered': true,
          'face_embedding': embedding,
        }).eq('id', user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face Registered Successfully!'), backgroundColor: AppColors.success),
          );
          // Return to the profile screen
          Navigator.pop(context); 
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Registration failed: ${e.toString().replaceAll('Exception:', '')}";
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
        title: const Text('Face Registration', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Camera Preview wrapped in a circular clip to look like a face scanner
            Center(
              child: Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 4),
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
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _captureAndRegister,
                  icon: _isProcessing 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.camera_alt),
                  label: Text(_isProcessing ? 'Processing...' : 'Scan My Face'),
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