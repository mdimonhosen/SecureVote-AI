import 'dart:math';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  /// 1. Detect if a valid face is in the camera frame
  Future<Face?> detectFace(InputImage inputImage) async {
    final List<Face> faces = await _faceDetector.processImage(inputImage);
    
    if (faces.isEmpty) return null; // No face found
    if (faces.length > 1) throw Exception("Multiple faces detected. Please ensure only one person is in frame.");
    
    return faces.first;
  }

  /// 2. Extract Embedding (Array of doubles) 
  /// NOTE: In a production app, you would pass the cropped Face bounding box 
  /// to a TFLite model (e.g., MobileFaceNet) here to get the actual 128-d vector.
  Future<List<double>> extractEmbedding(Face face, CameraImage image) async {
    // Placeholder logic for architectural completeness.
    // Replace with: return await _tfLiteService.getEmbedding(croppedImage);
    return List.generate(128, (index) => Random().nextDouble()); 
  }

  /// 3. Compare two embeddings using Cosine Similarity 
  double cosineSimilarity(List<double> vectorA, List<double> vectorB) {
    if (vectorA.length != vectorB.length) return 0.0;
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
      normA += pow(vectorA[i], 2);
      normB += pow(vectorB[i], 2);
    }
    
    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  void dispose() {
    _faceDetector.close();
  }
}