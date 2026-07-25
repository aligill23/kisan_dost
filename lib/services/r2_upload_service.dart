import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

class R2UploadService {
  // ── Credentials ──────────────────────────────
  static const _accountId = '7c5120a5844b8372a83ec031f2e17e32';
  static const _accessKey = 'a294731df00e2675eab398574c3510d4';
  static const _secretKey =
      '2a4eceb583c6460a92ead0c5c87902c83b9e8f4ba03a5b80097aefd91d84a94e';
  static const _bucket = 'kisandost-images';
  static const _publicUrl =
      'https://pub-fb0174c36556499f8c6707de5e444e75.r2.dev';
  static const _endpoint = '$_accountId.r2.cloudflarestorage.com';
  static const _region = 'auto';

  static const _uuid = Uuid();

  // ── Folders ───────────────────────────────────
  static const folderCrops = 'crops';
  static const folderProducts = 'products';
  static const folderReceipts = 'receipts';
  static const folderProfiles = 'profiles';
  static const String folderBanners = 'banners';
  // ── Compress ──────────────────────────────────
  static Future<File> _compress(
    File file, {
    int quality = 60,
    int maxW = 800,
    int maxH = 800,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${_uuid.v4()}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        path,
        quality: quality,
        minWidth: maxW,
        minHeight: maxH,
        keepExif: false,
        format: CompressFormat.jpeg,
      );

      if (result == null) return file;
      final compressed = File(result.path);
      return (await compressed.length()) < (await file.length())
          ? compressed
          : file;
    } catch (_) {
      return file;
    }
  }

  // ── AWS Signature V4 ──────────────────────────
  static String _hmacSha256Hex(String key, String data) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(data)).toString();
  }

  static List<int> _hmacSha256Bytes(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).bytes;
  }

  static String _sha256Hex(List<int> data) {
    return sha256.convert(data).toString();
  }

  static Map<String, String> _buildHeaders({
    required String objectKey,
    required Uint8List bytes,
    required DateTime now,
  }) {
    final dateStamp = '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final amzDate = '${dateStamp}T'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}Z';

    final payloadHash = _sha256Hex(bytes);
    final host = '$_endpoint';

    // ── Canonical Request ──
    final canonicalHeaders = 'content-type:image/jpeg\n'
        'host:$host\n'
        'x-amz-content-sha256:$payloadHash\n'
        'x-amz-date:$amzDate\n';

    final signedHeaders = 'content-type;host;x-amz-content-sha256;x-amz-date';

    final canonicalRequest = 'PUT\n'
        '/$_bucket/$objectKey\n'
        '\n'
        '$canonicalHeaders\n'
        '$signedHeaders\n'
        '$payloadHash';

    // ── String to Sign ──
    final credScope = '$dateStamp/$_region/s3/aws4_request';
    final stringToSign = 'AWS4-HMAC-SHA256\n'
        '$amzDate\n'
        '$credScope\n'
        '${_sha256Hex(utf8.encode(canonicalRequest))}';

    // ── Signing Key ──
    final kDate = _hmacSha256Bytes(utf8.encode('AWS4$_secretKey'), dateStamp);
    final kRegion = _hmacSha256Bytes(kDate, _region);
    final kService = _hmacSha256Bytes(kRegion, 's3');
    final kSigning = _hmacSha256Bytes(kService, 'aws4_request');

    final signature =
        Hmac(sha256, kSigning).convert(utf8.encode(stringToSign)).toString();

    final authorization = 'AWS4-HMAC-SHA256 '
        'Credential=$_accessKey/$credScope, '
        'SignedHeaders=$signedHeaders, '
        'Signature=$signature';

    return {
      'Authorization': authorization,
      'Content-Type': 'image/jpeg',
      'x-amz-date': amzDate,
      'x-amz-content-sha256': payloadHash,
      'Content-Length': bytes.length.toString(),
    };
  }

  // ── Core Upload ───────────────────────────────
  static Future<String?> uploadImage({
    required File file,
    required String folder,
    int quality = 60,
    int maxWidth = 800,
    int maxHeight = 800,
    void Function(double)? onProgress,
    int maxRetries = 3,
  }) async {
    try {
      onProgress?.call(0.05);

      final compressed = await _compress(file,
          quality: quality, maxW: maxWidth, maxH: maxHeight);

      onProgress?.call(0.3);

      final objectKey = '$folder/${_uuid.v4()}.jpg';
      final bytes = await compressed.readAsBytes();

      onProgress?.call(0.5);

      for (int i = 1; i <= maxRetries; i++) {
        final url = await _put(objectKey, bytes);
        if (url != null) {
          onProgress?.call(1.0);
          return url;
        }
        if (i < maxRetries) {
          await Future.delayed(Duration(seconds: i));
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _put(String objectKey, Uint8List bytes) async {
    try {
      final now = DateTime.now().toUtc();
      final headers = _buildHeaders(
        objectKey: objectKey,
        bytes: bytes,
        now: now,
      );

      final uri = Uri.https(_endpoint, '/$_bucket/$objectKey');

      final response = await http.put(uri, headers: headers, body: bytes);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return '$_publicUrl/$objectKey';
      }

      // Debug — remove before Play Store
      print('R2 Error ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('R2 Exception: $e');
      return null;
    }
  }

  // ── Convenience Methods ───────────────────────
  static Future<String?> uploadCropImage(File f,
          {void Function(double)? onProgress}) =>
      uploadImage(
          file: f,
          folder: folderCrops,
          quality: 65,
          maxWidth: 900,
          maxHeight: 900,
          onProgress: onProgress);

  static Future<String?> uploadProductImage(File f,
          {void Function(double)? onProgress}) =>
      uploadImage(
          file: f,
          folder: folderProducts,
          quality: 70,
          maxWidth: 800,
          maxHeight: 800,
          onProgress: onProgress);

  static Future<String?> uploadReceipt(File f,
          {void Function(double)? onProgress}) =>
      uploadImage(
          file: f,
          folder: folderReceipts,
          quality: 80,
          maxWidth: 1200,
          maxHeight: 1200,
          onProgress: onProgress);

  static Future<String?> uploadProfilePhoto(File f,
          {void Function(double)? onProgress}) =>
      uploadImage(
          file: f,
          folder: folderProfiles,
          quality: 75,
          maxWidth: 400,
          maxHeight: 400,
          onProgress: onProgress);
}
