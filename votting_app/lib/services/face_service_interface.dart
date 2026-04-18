import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

abstract class FaceServiceInterface {
  Future<void> init();
  Future<List<Face>> detectFaces(InputImage inputImage);
  Future<List<double>?> getEmbedding(CameraImage cameraImage, Face face);
  double euclideanDistance(List<double> e1, List<double> e2);
  bool isMatch(List<double> e1, List<double> e2, [double threshold = 0.6]);
  void dispose();
}
