import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

// Define your scopes here
const _scopes = [
  'https://www.googleapis.com/auth/cloud-platform',
  // Add other required scopes here
];

Future<String> getAccessToken() async {
  // Load the service-account.json file from assets
  final jsonString = await rootBundle.loadString('assets/');
  final accountCredentials = ServiceAccountCredentials.fromJson(json.decode(jsonString));

  final authClient = await clientViaServiceAccount(accountCredentials, _scopes);

  // Retrieve the access token
  final accessToken = (await authClient.credentials).accessToken;

  return accessToken.data;
}

// void main() async {
//   try {
//     final token = await getAccessToken();
//     print('Access Token: $token');
//   } catch (e) {
//     print('Error: $e');
//   }
// }
