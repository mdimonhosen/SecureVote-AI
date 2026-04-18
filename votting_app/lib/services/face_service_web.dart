import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_service_interface.dart';

class FaceService implements FaceServiceInterface {
  @override
  Future<void> init() async {
    print('FaceService Web: Initialized (Mock)');
  }

  @override
  Future<List<Face>> detectFaces(InputImage inputImage) async {
    return []; // Mock: No faces detected via ML Kit on web
  }

  @override
  Future<List<double>?> getEmbedding(CameraImage cameraImage, Face face) async {
    return [0.0]; // Mock
  }

  @override
  double euclideanDistance(List<double> e1, List<double> e2) => 0.0;

  @override
  bool isMatch(List<double> e1, List<double> e2, [double threshold = 0.6]) => true;

  @override
  void dispose() {}
}
