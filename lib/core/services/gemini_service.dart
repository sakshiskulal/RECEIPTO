import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/core/services/gemini_exception_handler.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class GeminiService {
  late final String _apiKey;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  GeminiService() {
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (_apiKey.isEmpty) {
      throw Exception('Missing GEMINI_API_KEY in environment variables (.env file).');
    }
  }

  /// Sends the receipt image URL to Gemini Vision REST API for scanning and data extraction.
  Future<ReceiptModel> analyzeReceipt({
    required String imageUrl,
  }) async {
    return _analyzeReceiptWithRetry(imageUrl: imageUrl, retryCount: 1);
  }

  Future<ReceiptModel> _analyzeReceiptWithRetry({
    required String imageUrl,
    required int retryCount,
  }) async {
    final startTime = DateTime.now();
    try {
      // 1. Download image bytes from the public Supabase URL
      final http.Response downloadRes = await http.get(Uri.parse(imageUrl));
      if (downloadRes.statusCode != 200) {
        throw GeminiException(
          'Failed to download image from storage bucket.',
          statusCode: downloadRes.statusCode,
        );
      }
      final bytes = downloadRes.bodyBytes;
      final String base64Image = base64.encode(bytes);

      // 2. Prepare detailed prompt tailored for Indian Receipts
      const prompt = '''
You are an expert AI receipt scanner.
Analyze the provided receipt image and extract the receipt details.

CRITICAL RULES FOR CURRENCY RESOLUTION:
- Assume all receipts are Indian by default unless another country's address, currency symbol, or tax format clearly proves otherwise.
- For all Indian receipts/merchants (including DMart, Reliance, Smart Bazaar, More, Vishal Mart, Big Bazaar, Apollo, MedPlus, Croma, Vijay Sales, JioMart, Indian petrol pumps, Indian restaurants, etc.), the currency MUST be "₹".
- Never return "\$" for Indian receipts. Never infer USD.
- Return INR ("₹") for all Indian merchants.
- Only return "\$", "€", "£", etc. when the receipt explicitly belongs to another country (e.g., US, Europe, UK).

Carefully extract common Indian receipt structures and formats from superstores, malls, pharmacies, petrol pumps, restaurants, and local markets (e.g. DMart, Reliance Smart, More, Vishal Mart, Big Bazaar, Apollo Pharmacy, MedPlus, Croma, Vijay Sales, Petrol Pumps, Restaurants, Cafes, Grocery Stores, Medical Stores, Shopping Malls, Supermarkets).

You must return ONLY a single, valid JSON object.
Do NOT wrap the JSON inside markdown code blocks or backticks (e.g. do NOT use ```json or ```). Return ONLY the raw JSON string.
If any field is unavailable or not present on the receipt, set it to null. Do NOT output placeholder text like "Unknown", "No Warranty", "N/A", or fake values.

JSON structure:
{
  "merchant_name": String or null,
  "invoice_number": String or null,
  "date": String (YYYY-MM-DD format preferred) or null,
  "time": String (HH:MM or HH:MM:SS format) or null,
  "gst_number": String or null (GSTIN number of the merchant),
  "currency": String ("₹" or other detected currency symbol) or null,
  "subtotal": double or null,
  "tax": double or null (GST / SGST / CGST total tax amount),
  "discount": double or null,
  "total": double or null (Grand Total),
  "payment_method": String or null (e.g. UPI, Cash, Card, Net Banking),
  "category": String or null,
  "merchant_address": String or null,
  "merchant_phone": String or null,
  "items": [
    {
      "name": String,
      "quantity": int or null,
      "unit_price": double or null,
      "total_price": double or null,
      "brand": String or null,
      "model": String or null,
      "serial_number": String or null,
      "warranty_available": bool (MUST be true or false. Set to false if not mentioned. Do NOT guess or assume warranty exists. Only set to true if receipt mentions warranty terms),
      "warranty_period": int or null (warranty length count, e.g. 12, 24, 1),
      "warranty_unit": String or null (warranty length unit, e.g. "days", "months", "years")
    }
  ]
}
''';

      // 3. Build REST request payload
      final Map<String, dynamic> requestPayload = {
        "contents": [
          {
            "parts": [
              {
                "text": prompt
              },
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ]
      };

      final String requestBody = jsonEncode(requestPayload);

      // 4. Call Google Gemini API endpoint via REST
      final http.Response response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (response.statusCode != 200) {
        final geminiExc = GeminiExceptionHandler.handleResponse(response);
        
        // Retriable codes check: 429, 500, 503
        final bool isRetriable = [429, 500, 503].contains(response.statusCode);
        if (isRetriable && retryCount > 0) {
          final waitSec = geminiExc.retryAfterSeconds ?? 5;
          GeminiExceptionHandler.logRequest(
            endpoint: _baseUrl,
            statusCode: response.statusCode,
            errorType: 'Retriable error. Waiting ${waitSec}s before retrying...',
            retryCount: 1 - retryCount + 1,
            responseTime: duration,
          );
          await Future.delayed(Duration(seconds: waitSec));
          return _analyzeReceiptWithRetry(imageUrl: imageUrl, retryCount: retryCount - 1);
        }

        GeminiExceptionHandler.logRequest(
          endpoint: _baseUrl,
          statusCode: response.statusCode,
          errorType: 'API Response Error',
          retryCount: 1 - retryCount,
          responseTime: duration,
        );
        throw geminiExc;
      }

      // Success branch
      GeminiExceptionHandler.logRequest(
        endpoint: _baseUrl,
        statusCode: 200,
        errorType: 'Success',
        retryCount: 1 - retryCount,
        responseTime: duration,
      );

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw GeminiException("Unexpected error occurred.");
      }
      final candidate = candidates.first as Map<String, dynamic>;
      final contentMap = candidate['content'] as Map<String, dynamic>?;
      if (contentMap == null) {
        throw GeminiException("Unexpected error occurred.");
      }
      final parts = contentMap['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw GeminiException("Unexpected error occurred.");
      }
      final part = parts.first as Map<String, dynamic>;
      final rawText = part['text'] as String?;

      if (rawText == null || rawText.trim().isEmpty) {
        throw GeminiException("Unexpected error occurred.");
      }

      final cleanedJson = _cleanJsonResponse(rawText);
      final Map<String, dynamic> jsonMap = jsonDecode(cleanedJson) as Map<String, dynamic>;
      return ReceiptModel.fromJson(jsonMap);
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      final mappedExc = GeminiExceptionHandler.handleException(e);

      // Handle standard exceptions retry (Socket/Timeout exceptions are retriable)
      final bool isNetworkErr = e is SocketException || e is TimeoutException;
      if (isNetworkErr && retryCount > 0) {
        GeminiExceptionHandler.logRequest(
          endpoint: _baseUrl,
          statusCode: null,
          errorType: 'Retriable Network Error: $e. Waiting 5s...',
          retryCount: 1 - retryCount + 1,
          responseTime: duration,
        );
        await Future.delayed(const Duration(seconds: 5));
        return _analyzeReceiptWithRetry(imageUrl: imageUrl, retryCount: retryCount - 1);
      }

      GeminiExceptionHandler.logRequest(
        endpoint: _baseUrl,
        statusCode: mappedExc.statusCode,
        errorType: mappedExc.message,
        retryCount: 1 - retryCount,
        responseTime: duration,
      );
      throw mappedExc;
    }
  }

  /// Sends the receipt plain text contents to Gemini REST API for scanning and data extraction.
  Future<ReceiptModel> analyzeReceiptText({
    required String text,
  }) async {
    return _analyzeReceiptTextWithRetry(text: text, retryCount: 1);
  }

  Future<ReceiptModel> _analyzeReceiptTextWithRetry({
    required String text,
    required int retryCount,
  }) async {
    final startTime = DateTime.now();
    try {
      const prompt = '''
You are an expert AI receipt scanner.
Analyze the provided receipt/invoice text contents and extract the receipt details.

CRITICAL RULES FOR CURRENCY RESOLUTION:
- Assume all receipts are Indian by default unless another country's address, currency symbol, or tax format clearly proves otherwise.
- For all Indian receipts/merchants (including DMart, Reliance, Smart Bazaar, More, Vishal Mart, Big Bazaar, Apollo, MedPlus, Croma, Vijay Sales, JioMart, Indian petrol pumps, Indian restaurants, etc.), the currency MUST be "₹".
- Never return "\$" for Indian receipts. Never infer USD.
- Return INR ("₹") for all Indian merchants.
- Only return "\$", "€", "£", etc. when the receipt explicitly belongs to another country (e.g., US, Europe, UK).

You must return ONLY a single, valid JSON object.
Do NOT wrap the JSON inside markdown code blocks or backticks (e.g. do NOT use ```json or ```). Return ONLY the raw JSON string.
If any field is unavailable or not present on the receipt, set it to null. Do NOT output placeholder text like "Unknown", "No Warranty", "N/A", or fake values.

JSON structure:
{
  "merchant_name": String or null,
  "invoice_number": String or null,
  "date": String (YYYY-MM-DD format preferred) or null,
  "time": String (HH:MM or HH:MM:SS format) or null,
  "gst_number": String or null (GSTIN number of the merchant),
  "currency": String ("₹" or other detected currency symbol) or null,
  "subtotal": double or null,
  "tax": double or null (GST / SGST / CGST total tax amount),
  "discount": double or null,
  "total": double or null (Grand Total),
  "payment_method": String or null (e.g. UPI, Cash, Card, Net Banking),
  "category": String or null,
  "merchant_address": String or null,
  "merchant_phone": String or null,
  "items": [
    {
      "name": String,
      "quantity": int or null,
      "unit_price": double or null,
      "total_price": double or null,
      "brand": String or null,
      "model": String or null,
      "serial_number": String or null,
      "warranty_available": bool (MUST be true or false. Set to false if not mentioned. Do NOT guess or assume warranty exists. Only set to true if receipt mentions warranty terms),
      "warranty_period": int or null (warranty length count, e.g. 12, 24, 1),
      "warranty_unit": String or null (warranty length unit, e.g. "days", "months", "years")
    }
  ]
}
''';

      // Build REST request payload
      final Map<String, dynamic> requestPayload = {
        "contents": [
          {
            "parts": [
              {
                "text": '$prompt\n\nRECEIPT TEXT:\n$text'
              }
            ]
          }
        ]
      };

      final String requestBody = jsonEncode(requestPayload);

      // Call Google Gemini API endpoint via REST
      final http.Response response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (response.statusCode != 200) {
        final geminiExc = GeminiExceptionHandler.handleResponse(response);

        // Retriable codes check: 429, 500, 503
        final bool isRetriable = [429, 500, 503].contains(response.statusCode);
        if (isRetriable && retryCount > 0) {
          final waitSec = geminiExc.retryAfterSeconds ?? 5;
          GeminiExceptionHandler.logRequest(
            endpoint: _baseUrl,
            statusCode: response.statusCode,
            errorType: 'Retriable text error. Waiting ${waitSec}s...',
            retryCount: 1 - retryCount + 1,
            responseTime: duration,
          );
          await Future.delayed(Duration(seconds: waitSec));
          return _analyzeReceiptTextWithRetry(text: text, retryCount: retryCount - 1);
        }

        GeminiExceptionHandler.logRequest(
          endpoint: _baseUrl,
          statusCode: response.statusCode,
          errorType: 'API Text Response Error',
          retryCount: 1 - retryCount,
          responseTime: duration,
        );
        throw geminiExc;
      }

      GeminiExceptionHandler.logRequest(
        endpoint: _baseUrl,
        statusCode: 200,
        errorType: 'Success',
        retryCount: 1 - retryCount,
        responseTime: duration,
      );

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw GeminiException("Unexpected error occurred.");
      }
      final candidate = candidates.first as Map<String, dynamic>;
      final contentMap = candidate['content'] as Map<String, dynamic>?;
      if (contentMap == null) {
        throw GeminiException("Unexpected error occurred.");
      }
      final parts = contentMap['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw GeminiException("Unexpected error occurred.");
      }
      final part = parts.first as Map<String, dynamic>;
      final rawText = part['text'] as String?;

      if (rawText == null || rawText.trim().isEmpty) {
        throw GeminiException("Unexpected error occurred.");
      }

      final cleanedJson = _cleanJsonResponse(rawText);
      final Map<String, dynamic> jsonMap = jsonDecode(cleanedJson) as Map<String, dynamic>;
      return ReceiptModel.fromJson(jsonMap);
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      final mappedExc = GeminiExceptionHandler.handleException(e);

      // Handle standard exceptions retry
      final bool isNetworkErr = e is SocketException || e is TimeoutException;
      if (isNetworkErr && retryCount > 0) {
        GeminiExceptionHandler.logRequest(
          endpoint: _baseUrl,
          statusCode: null,
          errorType: 'Retriable Text Network Error: $e. Waiting 5s...',
          retryCount: 1 - retryCount + 1,
          responseTime: duration,
        );
        await Future.delayed(const Duration(seconds: 5));
        return _analyzeReceiptTextWithRetry(text: text, retryCount: retryCount - 1);
      }

      GeminiExceptionHandler.logRequest(
        endpoint: _baseUrl,
        statusCode: mappedExc.statusCode,
        errorType: mappedExc.message,
        retryCount: 1 - retryCount,
        responseTime: duration,
      );
      throw mappedExc;
    }
  }

  /// Removes backticks and code block markers if returned by the model.
  String _cleanJsonResponse(String response) {
    String cleaned = response.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'^```[a-zA-Z]*\n'), '');
      cleaned = cleaned.replaceAll(RegExp(r'\n```$'), '');
      cleaned = cleaned.trim();
    }
    return cleaned;
  }
}
