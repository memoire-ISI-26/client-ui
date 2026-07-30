import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String activeMode = "SIMPLE";
  static String activeUniverse = "TELCO";
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
        _cachedBaseUrl = 'http://your_ip_address:8765';
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

  /// Récupère le solde du compte principal pour un numéro donné.
  static Future<double> getBalance(String number, String token) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/accounts/number/$number/balance');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return double.parse(response.body);
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Impossible de récupérer le solde (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la récupération du solde : $e');
    }
  }

  /// Effectue un achat de crédit.
  static Future<Map<String, dynamic>> purchaseCredit({
    required String sender,
    required String receiver,
    required double amount,
    required String paymentMethod,
    required String token,
  }) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/pricing/purchase/credit');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Mode': activeMode,
          'X-User-Universe': activeUniverse,
        },
        body: jsonEncode({
          'receiverNumber': receiver,
          'amount': amount,
          'paymentMethod': paymentMethod,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Échec de l\'achat (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la validation de la transaction : $e');
    }
  }

  /// Récupère tous les pass internet.
  static Future<List<dynamic>> getPassInternet(String token) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/pricing/pass-internet');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] as List<dynamic>; // ApiResponse wraps list in 'data' field
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Impossible de récupérer les pass (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la récupération des pass : $e');
    }
  }

  /// Achète un pass internet.
  static Future<Map<String, dynamic>> purchasePassInternet({
    required String receiverNumber,
    required int passId,
    required String passName,
    required double amount,
    required String paymentMethod, // "WALLET" or "CREDIT"
    required String token,
  }) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/pricing/purchase/pass-internet');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Mode': activeMode,
          'X-User-Universe': activeUniverse,
        },
        body: jsonEncode({
          'receiverNumber': receiverNumber,
          'passId': passId,
          'passName': passName,
          'amount': amount,
          'paymentMethod': paymentMethod,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Échec de l\'achat (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la validation de la transaction : $e');
    }
  }

  /// Récupère tous les pass illimix.
  static Future<List<dynamic>> getPassIllimix(String token) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/pricing/pass-illimix');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] as List<dynamic>; // ApiResponse wraps list in 'data' field
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Impossible de récupérer les pass Illimix (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la récupération des pass Illimix : $e');
    }
  }

  /// Récupère la liste des pass Illiflex disponibles.
  static Future<List<dynamic>> getPassIlliflex(String token) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/pricing/pass-illiflex');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] as List<dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Impossible de récupérer les pass Illiflex (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la récupération des pass Illiflex : $e');
    }
  }

  /// Achète un pass illiflex.
  static Future<Map<String, dynamic>> purchasePassIlliflex({
    required String receiverNumber,
    required int passId,
    required String passName,
    required double amount,
    required String paymentMethod, // "WALLET" or "CREDIT"
    required String token,
  }) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/pricing/purchase/pass-illiflex');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Mode': activeMode,
          'X-User-Universe': activeUniverse,
        },
        body: jsonEncode({
          'receiverNumber': receiverNumber,
          'passId': passId,
          'passName': passName,
          'amount': amount,
          'paymentMethod': paymentMethod,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Échec de l\'achat (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la validation de la transaction : $e');
    }
  }

  /// Achète un pass illimix.
  static Future<Map<String, dynamic>> purchasePassIllimix({
    required String receiverNumber,
    required int passId,
    required String passName,
    required double amount,
    required String paymentMethod, // "WALLET" or "CREDIT"
    required String token,
  }) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/pricing/purchase/pass-illimix');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Mode': activeMode,
          'X-User-Universe': activeUniverse,
        },
        body: jsonEncode({
          'receiverNumber': receiverNumber,
          'passId': passId,
          'passName': passName,
          'amount': amount,
          'paymentMethod': paymentMethod,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Échec de l\'achat (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la validation de la transaction : $e');
    }
  }

  /// Récupère tous les pass internationaux.
  static Future<List<dynamic>> getPassInternational(String token) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/pricing/pass-international');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] as List<dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Impossible de récupérer les pass internationaux (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la récupération des pass internationaux : $e');
    }
  }

  /// Achète un pass international.
  static Future<Map<String, dynamic>> purchasePassInternational({
    required String receiverNumber,
    required int passId,
    required String passName,
    required double amount,
    required String paymentMethod, // "WALLET" or "CREDIT"
    required String token,
  }) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/pricing/purchase/pass-international');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Mode': activeMode,
          'X-User-Universe': activeUniverse,
        },
        body: jsonEncode({
          'receiverNumber': receiverNumber,
          'passId': passId,
          'passName': passName,
          'amount': amount,
          'paymentMethod': paymentMethod,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Échec de l\'achat (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la validation de la transaction : $e');
    }
  }

  /// Récupère les détails d'une carte Rapido par son numéro.
  static Future<Map<String, dynamic>> getRapidoCard(String cardNumber, String token) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/pricing/rapido/card/$cardNumber');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception("La carte Rapido n'existe pas dans le système.");
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Impossible de récupérer la carte Rapido (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la récupération de la carte Rapido : $e');
    }
  }

  /// Enregistre/Crée une nouvelle carte Rapido.
  static Future<Map<String, dynamic>> registerRapidoCard({
    required String cardNumber,
    required double initialBalance,
    required String token,
  }) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/pricing/rapido/register');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'numeroCarte': cardNumber,
          'soldeInitial': initialBalance,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Échec de l\'enregistrement (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de l\'enregistrement de la carte Rapido : $e');
    }
  }

  /// Recharge une carte Rapido via le compte principal.
  static Future<Map<String, dynamic>> purchaseRapido({
    required String cardNumber,
    required double amount,
    required String token,
  }) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/pricing/purchase/rapido');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Mode': activeMode,
          'X-User-Universe': activeUniverse,
        },
        body: jsonEncode({
          'receiverNumber': cardNumber,
          'amount': amount,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Échec de la recharge (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la recharge Rapido : $e');
    }
  }

  /// Effectue un transfert d'argent (Wallet à Wallet).
  static Future<Map<String, dynamic>> transfer({
    required String sender,
    required String receiver,
    required double amount,
    required String token,
  }) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/transactions/transfer');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Mode': activeMode,
          'X-User-Universe': activeUniverse,
        },
        body: jsonEncode({
          'sender': sender,
          'receiver': receiver,
          'amount': amount,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Échec du transfert (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors du transfert : $e');
    }
  }

  /// Effectue un dépôt d'argent sur le compte principal (Wallet).
  static Future<Map<String, dynamic>> deposit({
    required String number,
    required double amount,
    required String token,
  }) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/transactions/deposit');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Mode': activeMode,
          'X-User-Universe': activeUniverse,
        },
        body: jsonEncode({
          'number': number,
          'amount': amount,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Échec du dépôt (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors du dépôt : $e');
    }
  }

  /// Effectue un retrait d'argent depuis le compte principal (Wallet).
  static Future<Map<String, dynamic>> withdraw({
    required String number,
    required double amount,
    required String token,
  }) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/transactions/withdraw');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Mode': activeMode,
          'X-User-Universe': activeUniverse,
        },
        body: jsonEncode({
          'number': number,
          'amount': amount,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Échec du retrait (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors du retrait : $e');
    }
  }

  /// Récupère l'historique des transactions pour un numéro donné.
  static Future<List<dynamic>> getTransactionHistory(String number, String token) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/transactions/history/$number');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Impossible de récupérer l\'historique (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la récupération de l\'historique des transactions : $e');
    }
  }

  /// Récupère les détails complets du compte (dont balance et callCredit).
  static Future<Map<String, dynamic>> getAccount(String number, String token) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/accounts/number/$number');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Impossible de récupérer le compte (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la récupération des détails du compte : $e');
    }
  }

  /// Récupère le profil de personnalisation utilisateur HDFS (Univers, Services, Mode).
  static Future<Map<String, dynamic>> getPersonalization(String number, String token) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/personnalisation/usages/$number');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Phone': number,
          'X-User-Role': 'CLIENT',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Impossible de récupérer la personnalisation (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la récupération de la personnalisation : $e');
    }
  }

  /// Récupère la liste des services par défaut (mode simple) pour OMY et TELCO.
  static Future<List<dynamic>> getDefaultServices(String token) async {
    final baseUrlResolved = await getBaseUrl();
    final url = Uri.parse('$baseUrlResolved/personnalisation/default-services');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body["data"] as List<dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Impossible de récupérer les services par défaut (Code ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la récupération des services par défaut : $e');
    }
  }
}
