import 'dart:convert';

import 'dart:io';

import 'package:get/state_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:weather_app/resources/local%20storage/local_storage.dart';
import 'package:weather_app/resources/local%20storage/local_storage_keys.dart';
import 'package:weather_app/utils/utils.dart';

class NetworkApiService extends GetxService {
  /// Retrieves the authorization token from local storage.
  String _getToken() => "Bearer ${LocalStorage.readJson(key: lsk.authToken)}";

  /// Default headers for all requests.
  Map<String, String> _defaultHeaders() => {
    'Content-type': 'application/json',
    'authorization': _getToken(),
  };

  /// Logs detailed response information for debugging purposes.
  void _logResponse(http.Response response) {
    Utils.logSuccess(
      "[${response.request?.method}] Request URL: ${response.request?.url}",
      name: "APIX",
    );
    Utils.logInfo("Status Code: ${response.statusCode}", name: "APIX");
    Utils.logInfo("Response Headers: ${response.headers}", name: "APIX");
    Utils.logSuccess("Response Body: ${response.body}", name: "APIX");
  }

  /// Handles HTTP responses and processes JSON data or throws appropriate exceptions.
  dynamic _processResponse(http.Response response) {
    final responseJson = jsonDecode(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        return responseJson;
      case 400:
        throw Exception(responseJson['message'] ?? "Bad Request");
      case 401:
        // _handleUnauthorized(responseJson['message']);
        throw Exception(responseJson['message'] ?? "Unauthorized");

      case 403:
        throw Exception(responseJson['message'] ?? "Forbidden");
      case 404:
        throw Exception(responseJson['message'] ?? "Not Found");
      case 409:
        throw Exception(responseJson['message'] ?? "Conflict");
      case 429:
        throw Exception(responseJson['message'] ?? "Too Many Requests");
      case 500:
        throw Exception(responseJson['message'] ?? "Internal Server Error");
      case 503:
        throw Exception(responseJson['message'] ?? "Service Unavailable");
      default:
        throw Exception("Unhandled Status Code: ${response.statusCode}");
    }
  }

  /// Handles unauthorized responses by logging the user out.
  // void _handleUnauthorized(String? message) {
  //   Future.microtask(() {
  //     AuthService().logout({
  //       "refreshToken":
  //           LocalStorage.readJson(key: LocalStorageKeys.refreshToken),
  //       "deviceToken": "abc"
  //     });
  //   });
  //   throw Exception(message ?? "Unauthorized");
  // }

  /// Centralized method to send requests and handle common exceptions.
  Future<dynamic> _sendRequest(
    Future<http.Response> Function() requestFunc,
  ) async {
    try {
      final response = await requestFunc();
      _logResponse(response);
      return _processResponse(response);
    } on SocketException {
      Utils.logInfo("SocketException: No Internet Connection");
      throw const SocketException("No Internet Connection");
    } catch (e) {
      Utils.logInfo("Exception during request: $e");
      rethrow;
    }
  }

  /// Generic HTTP methods for GET, POST, PUT, DELETE requests.
  Future<dynamic> get(String url, {Map<String, dynamic>? params}) async {
    final uri = Uri.parse(url).replace(queryParameters: params);
    return _sendRequest(() => http.get(uri, headers: _defaultHeaders()));
  }

  Future<dynamic> post(String url, dynamic data) async {
    return _sendRequest(
      () => http.post(
        Uri.parse(url),
        headers: _defaultHeaders(),
        body: jsonEncode(data),
      ),
    );
  }

  Future<dynamic> put(String url, dynamic data) async {
    return _sendRequest(
      () => http.put(
        Uri.parse(url),
        headers: _defaultHeaders(),
        body: jsonEncode(data),
      ),
    );
  }

  Future<dynamic> patch(String url, dynamic data) async {
    return _sendRequest(
      () => http.patch(
        Uri.parse(url),
        headers: _defaultHeaders(),
        body: jsonEncode(data),
      ),
    );
  }

  Future<dynamic> delete(String url) async {
    return _sendRequest(
      () => http.delete(Uri.parse(url), headers: _defaultHeaders()),
    );
  }

  /// Multipart POST request
  Future<dynamic> postMultipart({
    required String url,
    required Map<String, dynamic> fields,
    required Map<String, List<File>> files,
    Map<String, String>? headers,
  }) async {
    return sendMultipart('POST', url, fields, files);
  }

  Future<dynamic> patchMultipart({
    required String url,
    required Map<String, dynamic> fields,
    required Map<String, List<File>> files,
    Map<String, String>? headers,
  }) async {
    return sendMultipart('PATCH', url, fields, files);
  }

  /// Handles multipart requests for both POST and PUT methods.
  Future<dynamic> sendMultipart(
    String method,
    String url,
    Map<String, dynamic> fields,
    Map<String, List<File>> files,
  ) async {
    final request = http.MultipartRequest(method, Uri.parse(url))
      ..headers.addAll(_defaultHeaders());

    // Add form fields to the request
    fields.forEach((key, value) {
      if (value is List && key.endsWith('[]')) {
        final newKey = key.replaceFirst('[]', '');
        for (var i = 0; i < value.length; i++) {
          request.fields["$newKey[$i]"] = value[i].toString();
        }
      } else {
        request.fields[key] = value.toString();
      }
    });

    // Add files to the request
    for (var entry in files.entries) {
      for (var file in entry.value) {
        final fileStream = http.ByteStream(file.openRead());
        final length = await file.length();
        final contentType = _getContentType(file.path.split('.').last);
        final multipartFile = http.MultipartFile(
          entry.key,
          fileStream,
          length,
          filename: file.path.split('/').last,
          contentType: contentType,
        );
        request.files.add(multipartFile);
      }
    }

    return _sendRequest(() => request.send().then(http.Response.fromStream));
  }

  /// Determines the content type based on the file extension.
  http_parser.MediaType _getContentType(String extension) {
    final mediaMap = {
      'video': ['mp4', 'mov', 'avi', 'wmv'],
      'image': ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
    };

    for (var entry in mediaMap.entries) {
      if (entry.value.contains(extension.toLowerCase())) {
        return http_parser.MediaType(entry.key, extension);
      }
    }
    return http_parser.MediaType("application", "octet-stream");
  }
}
