import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class CloudinaryHelper {
  static const String cloudName = 'dyvdmvudt';
  static const String uploadPreset = 'presentMe';
  static const String apiKey = '863752197995197';
  static const String apiSecret = 'dMl3wkE0UUXbQyU9VmSB1c-qv4E';

  static Future<Map<String, String>?> uploadImage(File file) async {
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final res = await http.Response.fromStream(response);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return {
        'url': data['secure_url'],
        'public_id': data['public_id'],
      };
    } else {
      print("Upload error: ${res.body}");
      return null;
    }
  }

  static Future<bool> deleteImage(String publicId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final signatureRaw = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    final signature = sha1.convert(utf8.encode(signatureRaw)).toString();

    final body = {
      'public_id': publicId,
      'api_key': apiKey,
      'timestamp': '$timestamp',
      'signature': signature,
    };

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');
    final response = await http.post(uri, body: body);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['result'] == 'ok';
    } else {
      print('Delete error: ${response.body}');
      return false;
    }
  }
}


