import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ReferralResult {
  final bool valid;
  final String ambassadorId;
  final String ambassadorName;
  final String referralCode;
  final String message;

  const ReferralResult({
    required this.valid,
    this.ambassadorId = '',
    this.ambassadorName = '',
    this.referralCode = '',
    this.message = '',
  });
}

class ReferralService {
  //   Replace with your actual backend URL
  static const String _baseUrl = 'https://kisan-dost-web.kisandost.workers.dev';

  static Future<ReferralResult> validateCode({
    required String userId,
    required String referralCode,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/referrals/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'referralCode': referralCode.trim().toUpperCase(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
          '=== REFERRAL TIMING: ${stopwatch.elapsedMilliseconds}ms, status: ${response.statusCode} ===');
      debugPrint('=== REFERRAL BODY: ${response.body} ===');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final valid = data['valid'] == true && data['success'] == true;

        return ReferralResult(
          valid: valid,
          ambassadorId: data['ambassadorId'] ?? '',
          ambassadorName: data['ambassadorName'] ?? '',
          referralCode: data['referralCode'] ?? '',
          message: data['message'] ?? '',
        );
      }

      // Server error response
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ReferralResult(
        valid: false,
        message: data['message'] ?? 'Server error. Try again.',
      );
    } on SocketException {
      debugPrint(
          '=== REFERRAL SocketException after ${stopwatch.elapsedMilliseconds}ms ===');
      return const ReferralResult(
        valid: false,
        message: 'انٹرنیٹ کنکشن نہیں ہے',
      );
    } on HttpException {
      debugPrint(
          '=== REFERRAL HttpException after ${stopwatch.elapsedMilliseconds}ms ===');
      return const ReferralResult(
        valid: false,
        message: 'سرور سے رابطہ نہیں ہو سکا',
      );
    } on FormatException {
      debugPrint(
          '=== REFERRAL FormatException after ${stopwatch.elapsedMilliseconds}ms ===');
      return const ReferralResult(
        valid: false,
        message: 'سرور کا جواب درست نہیں',
      );
    } catch (e) {
      debugPrint(
          '=== REFERRAL ERROR after ${stopwatch.elapsedMilliseconds}ms: $e ===');
      if (e.toString().contains('TimeoutException')) {
        return const ReferralResult(
          valid: false,
          message: 'درخواست ختم ہو گئی، دوبارہ کوشش کریں',
        );
      }
      return const ReferralResult(
        valid: false,
        message: 'کچھ غلط ہو گیا، دوبارہ کوشش کریں',
      );
    }
  }
}
