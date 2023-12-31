import 'dart:convert';
import 'package:http/http.dart' as http;

Map<String,dynamic> list = {};

void fetchBlogs() async {
  final String url = 'https://intent-kit-16.hasura.app/api/rest/blogs';
  final String adminSecret = '32qR4KmXOIpsGPQKMqEJHGJS27G5s7HdSKO3gdtQd2kv5e852SiYwWNfxkZOBuQ6';

  try {
    final response = await http.get(Uri.parse(url), headers: {
      'x-hasura-admin-secret': adminSecret,
    });

    if (response.statusCode == 200) {
      // Request successful, handle the response data here
      list = jsonDecode(response.body);
    } else {
      // Request failed
      print('Request failed with status code: ${response.statusCode}');
    }
  } catch (e) {
    // Handle any errors that occurred during the request
    print('Error: $e');
  }
}
