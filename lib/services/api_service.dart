import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String? _cachedBaseUrl;

  /// Récupère l'URL de base dynamiquement.
  /// Si kDebugMode est actif sur mobile, il tente de scanner le sous-réseau
  /// pour détecter le PC hôte (port 8765) de manière totalement automatique.
  static Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }

    // 1. Vérification d'une variable d'environnement (ex: --dart-define=API_URL=...)
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      _cachedBaseUrl = envUrl;
      return _cachedBaseUrl!;
    }

    // 2. Si Web, utiliser localhost
    if (kIsWeb) {
      _cachedBaseUrl = 'http://localhost:8765';
      return _cachedBaseUrl!;
    }

    // 3. En mode Debug sur mobile, scanner le sous-réseau pour trouver le PC
    if (kDebugMode) {
      try {
        final hostIp = await _discoverHostIP();
        if (hostIp != null) {
          _cachedBaseUrl = 'http://$hostIp:8765';
          debugPrint('Hôte détecté dynamiquement : $_cachedBaseUrl');
          return _cachedBaseUrl!;
        }
      } catch (e) {
        debugPrint('Échec de la détection dynamique de l\'hôte : $e');
      }
    }

    // 4. Repli par défaut selon la plateforme (ex: émulateur Android)
    try {
      if (Platform.isAndroid) {
        _cachedBaseUrl = 'http://10.96.18.217:8765';
        return _cachedBaseUrl!;
      }
    } catch (_) {}

    _cachedBaseUrl = 'http://localhost:8765';
    return _cachedBaseUrl!;
  }

  /// Scanne le sous-réseau local (port 8765) pour trouver l'adresse IP du PC hôte
  static Future<String?> _discoverHostIP() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
        includeLoopback: false,
      );

      String? deviceIP;
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          final ipStr = addr.address;
          // Ignorer localhost et les sous-réseaux virtuels Docker/émulateurs
          if (!ipStr.startsWith('127.') &&
              !ipStr.startsWith('172.') &&
              !ipStr.startsWith('10.0.2.')) {
            deviceIP = ipStr;
            break;
          }
        }
        if (deviceIP != null) break;
      }

      if (deviceIP == null) return null;

      final parts = deviceIP.split('.');
      if (parts.length != 4) return null;
      final subnet = '${parts[0]}.${parts[1]}.${parts[2]}.';

      final port = 8765;
      final futures = <Future<String?>>[];

      // Scanner en parallèle les IPs du sous-réseau (ex: 192.168.1.1 à 192.168.1.254)
      for (var i = 1; i < 255; i++) {
        final targetIP = '$subnet$i';
        futures.add(() async {
          try {
            final socket = await Socket.connect(targetIP, port, timeout: const Duration(milliseconds: 300));
            socket.destroy();
            return targetIP;
          } catch (_) {
            return null;
          }
        }());
      }

      final results = await Future.wait(futures);
      for (var result in results) {
        if (result != null) {
          return result;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Tente de connecter l'utilisateur avec ses identifiants
  static Future<Map<String, dynamic>> login(String identifier, String password) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Échec de la connexion (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la connexion réseau : $e');
    }
  }

  /// Inscrit un nouveau client avec les champs requis
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String number,
    required String password,
    required String birthdate,
  }) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/users/client/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'number': number,
          'password': password,
          'birthdate': birthdate,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Échec de l\'inscription (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur réseau lors de l\'inscription : $e');
    }
  }
}
