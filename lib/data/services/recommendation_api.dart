import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class RecommendationApi {
  final String baseUrl;
  final FirebaseAuth _auth;

  RecommendationApi({
    required this.baseUrl,
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  Future<List<String>> fetchRecommendations({int limit = 50}) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$baseUrl/recommendations?limit=$limit');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch recommendations: ${resp.body}');
    }
    final List data = json.decode(resp.body) as List;
    return data.map((e) => e['id'] as String).toList();
  }

  Future<List<String>> fetchTopPicks({int limit = 10}) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$baseUrl/top-picks?limit=$limit');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch top picks: ${resp.body}');
    }
    final List data = json.decode(resp.body) as List;
    return data.map((e) => e['id'] as String).toList();
  }

  Future<List<String>> fetchLikesYou({int limit = 50}) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$baseUrl/likes-you?limit=$limit');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch likes you: ${resp.body}');
    }
    final List data = json.decode(resp.body) as List;
    return data.map((e) => e['id'] as String).toList();
  }
}

const String kRecoBaseUrl = 'https://crushhour-reco-XXXX-uc.a.run.app';
