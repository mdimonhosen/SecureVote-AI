import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class FaceRecognitionService {
  static const String _apiKey = Constants.faceApiKey;
  static const String _endpoint = Constants.faceApiEndpoint;
  static const String _personGroupId = Constants.personGroupId;

  // Create person group if not exists
  static Future<void> createPersonGroup() async {
    final url = Uri.parse('$_endpoint/face/v1.0/persongroups/$_personGroupId');
    final response = await http.put(
      url,
      headers: {
        'Ocp-Apim-Subscription-Key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': 'Voters',
        'userData': 'Group for voter face recognition',
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 409) {
      throw Exception('Failed to create person group: ${response.body}');
    }
  }

  // Create person in person group
  static Future<String> createPerson(String name) async {
    final url = Uri.parse('$_endpoint/face/v1.0/persongroups/$_personGroupId/persons');
    final response = await http.post(
      url,
      headers: {
        'Ocp-Apim-Subscription-Key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'userData': 'Voter: $name',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create person: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['personId'];
  }

  // Add face to person
  static Future<void> addFaceToPerson(String personId, String imageUrl) async {
    final url = Uri.parse('$_endpoint/face/v1.0/persongroups/$_personGroupId/persons/$personId/persistedFaces');
    final response = await http.post(
      url,
      headers: {
        'Ocp-Apim-Subscription-Key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'url': imageUrl,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add face: ${response.body}');
    }
  }

  // Train person group
  static Future<void> trainPersonGroup() async {
    final url = Uri.parse('$_endpoint/face/v1.0/persongroups/$_personGroupId/train');
    final response = await http.post(
      url,
      headers: {
        'Ocp-Apim-Subscription-Key': _apiKey,
      },
    );

    if (response.statusCode != 202) {
      throw Exception('Failed to train person group: ${response.body}');
    }
  }

  // Detect faces in image
  static Future<List<String>> detectFaces(String imageUrl) async {
    final url = Uri.parse('$_endpoint/face/v1.0/detect?detectionModel=detection_03&returnFaceId=true');
    final response = await http.post(
      url,
      headers: {
        'Ocp-Apim-Subscription-Key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'url': imageUrl,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to detect faces: ${response.body}');
    }

    final data = jsonDecode(response.body) as List;
    return data.map((face) => face['faceId'] as String).toList();
  }

  // Identify person
  static Future<List<Map<String, dynamic>>> identifyPerson(List<String> faceIds) async {
    final url = Uri.parse('$_endpoint/face/v1.0/identify');
    final response = await http.post(
      url,
      headers: {
        'Ocp-Apim-Subscription-Key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'personGroupId': _personGroupId,
        'faceIds': faceIds,
        'maxNumOfCandidatesReturned': 1,
        'confidenceThreshold': 0.5,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to identify person: ${response.body}');
    }

    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  // Verify face
  static Future<bool> verifyFace(String faceId, String personId) async {
    final url = Uri.parse('$_endpoint/face/v1.0/verify');
    final response = await http.post(
      url,
      headers: {
        'Ocp-Apim-Subscription-Key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'faceId': faceId,
        'personId': personId,
        'personGroupId': _personGroupId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to verify face: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['isIdentical'] ?? false;
  }
}