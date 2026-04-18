import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'face_service_interface.dart';

class FaceService implements FaceServiceInterface {
  late FaceDetector _faceDetector;
  Interpreter? _interpreter;

  @override
  Future<void> init() async {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );
    await _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/mobile_face_net.tflite');
      debugPrint('Model loaded successfully');
    } catch (e) {
      debugPrint('Failed to load model: $e');
    }
  }

  @override
  Future<List<Face>> detectFaces(InputImage inputImage) async {
    return await _faceDetector.processImage(inputImage);
  }

  // Preprocess the face image and generate embedding
  @override
  Future<List<double>?> getEmbedding(CameraImage cameraImage, Face face) async {
    if (_interpreter == null) return null;

    // 1. Convert CameraImage to Image (img.Image)
    img.Image? image = _convertCameraImage(cameraImage);
    if (image == null) return null;

    // 2. Crop face
    Rect boundingBox = face.boundingBox;
    img.Image faceImage = img.copyCrop(
      image,
      x: boundingBox.left.toInt(),
      y: boundingBox.top.toInt(),
      width: boundingBox.width.toInt(),
      height: boundingBox.height.toInt(),
    );

    // 3. Resize to 112x112 (FaceNet requirement)
    img.Image resizedFace = img.copyResize(faceImage, width: 112, height: 112);

    // 4. Convert to Float32List and Normalize
    var input = _imageToByteListFloat32(resizedFace, 112, 128, 128);
    var output = List<double>.filled(192, 0).reshape([1, 192]); // FaceNet output is usually 128 or 192/512

    // Run inference
    _interpreter!.run(input, output);

    return List<double>.from(output[0]);
  }

  // Helper: CameraImage to img.Image
  img.Image? _convertCameraImage(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888(image);
      }
    } catch (e) {
      debugPrint("Conversion error: $e");
    }
    return null;
  }

  img.Image _convertBGRA8888(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  img.Image _convertYUV420(CameraImage image) {
    var width = image.width;
    var height = image.height;
    var yuvImage = img.Image(width: width, height: height);

    var yPlane = image.planes[0].bytes;
    var uPlane = image.planes[1].bytes;
    var vPlane = image.planes[2].bytes;

    var yRowStride = image.planes[0].bytesPerRow;
    var uvRowStride = image.planes[1].bytesPerRow;
    var uvPixelStride = image.planes[1].bytesPerPixel!;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        var index = y * yRowStride + x;

        var yp = yPlane[index];
        var up = uPlane[uvIndex];
        var vp = vPlane[uvIndex];

        int r = (yp + (1.370705 * (vp - 128))).toInt().clamp(0, 255);
        int g = (yp - (0.337633 * (up - 128)) - (0.698001 * (vp - 128))).toInt().clamp(0, 255);
        int b = (yp + (1.732446 * (up - 128))).toInt().clamp(0, 255);

        yuvImage.setPixelRgb(x, y, r, g, b);
      }
    }
    return yuvImage;
  }

  Float32List _imageToByteListFloat32(img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - mean) / std;
        buffer[pixelIndex++] = (pixel.g - mean) / std;
        buffer[pixelIndex++] = (pixel.b - mean) / std;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }

  // Matching logic: Euclidean distance
  @override
  double euclideanDistance(List<double> e1, List<double> e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }

  @override
  bool isMatch(List<double> e1, List<double> e2, [double threshold = 0.6]) {
    double distance = euclideanDistance(e1, e2);
    debugPrint("Distance: $distance");
    return distance < threshold;
  }

  @override
  void dispose() {
    _faceDetector.close();
    _interpreter?.close();
  }
}
