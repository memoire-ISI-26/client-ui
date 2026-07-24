import 'package:flutter/material.dart';
import 'package:client_ui/services/api_service.dart';
import 'package:client_ui/screens/login_screen.dart';
import 'package:client_ui/screens/achat_credit_screen.dart';
import 'package:client_ui/screens/achat_internet_screen.dart';
import 'package:client_ui/screens/achat_illimix_screen.dart';
import 'package:client_ui/screens/achat_illiflex_screen.dart';
import 'package:client_ui/screens/history_screen.dart';
import 'package:client_ui/screens/deposit_screen.dart';
import 'package:client_ui/screens/withdrawal_screen.dart';
import 'package:client_ui/screens/rapido_screen.dart';
import 'package:client_ui/screens/transfert_screen.dart';

class ServiceItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String key;

  ServiceItem({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.key,
  });
}

class HomeScreen extends StatefulWidget {
  final String token;
  final String role;
  final String identifier;

  const HomeScreen({
    super.key,
    required this.token,
    required this.role,
    required this.identifier,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingLastTxn = true;
  Map<String, dynamic>? _lastTransaction;
  String? _txnError;

  late PageController _pageController;
  int _activeUniverseIndex = 0; // 0 = TELCO, 1 = OMY

  bool _isBalanceVisible = false;
  bool _isSimpleMode = true;
  double? _currentWalletBalance;
  double _creditBalance = 0.0;

  double _simulatedDataGb = 0;
  int _simulatedCallMinutes = 0;
  int _simulatedSms = 0;

  List<ServiceItem> _telcoServices = [];
  List<ServiceItem> _omyServices = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _activeUniverseIndex);
    ApiService.activeMode = _isSimpleMode ? "SIMPLE" : "ADVANCE";
    ApiService.activeUniverse = _activeUniverseIndex == 1 ? "OMY" : "TELCO";
    _initServices();
    _fetchLastTransaction();
    _fetchAccountDetails();
    _fetchPersonalization();
  }

  void _initServices() {
    _telcoServices = [
      ServiceItem(
        title: "Achat Crédit",
        icon: Icons.phone_android_rounded,
        onTap: () => _handleAchatCreditTap(context, "TELCO.SERVICES.PASS.VOICE"),
        key: "TELCO.SERVICES.PASS.VOICE",
      ),
      ServiceItem(
        title: "Achat Illiflex",
        icon: Icons.swap_calls_rounded,
        onTap: () => _handleAchatIlliflexTap(context),
        key: "TELCO.SERVICES.PASS.ILLIFLEX",
      ),
      ServiceItem(
        title: "Achat Illimix",
        icon: Icons.all_inclusive_rounded,
        onTap: () => _handleAchatIllimixTap(context),
        key: "TELCO.SERVICES.PASS.ILLIMIX",
      ),
      ServiceItem(
        title: "Achat Internet",
        icon: Icons.language_rounded,
        onTap: () => _handleAchatInternetTap(context),
        key: "TELCO.SERVICES.PASS.DATA",
      ),
    ];

    _omyServices = [
      ServiceItem(
        title: "Achat Crédit",
        icon: Icons.phone_android_rounded,
        onTap: () => _handleAchatCreditTap(context, "OMY.SERVICES.VOICEBUNDLE"),
        key: "OMY.SERVICES.VOICEBUNDLE",
      ),
      ServiceItem(
        title: "Achat Illiflex",
        icon: Icons.swap_calls_rounded,
        onTap: () => _handleAchatIlliflexTap(context),
        key: "OMY.SERVICES.VOICEBUNDLE",
      ),
      ServiceItem(
        title: "Achat Illimix",
        icon: Icons.all_inclusive_rounded,
        onTap: () => _handleAchatIllimixTap(context),
        key: "OMY.SERVICES.VOICEBUNDLE",
      ),
      ServiceItem(
        title: "Achat Internet",
        icon: Icons.language_rounded,
        onTap: () => _handleAchatInternetTap(context),
        key: "OMY.SERVICES.VOICEBUNDLE",
      ),
      ServiceItem(
        title: "Rapido",
        icon: Icons.directions_car_rounded,
        onTap: () => _handleRapidoTap(context),
        key: "RAPIDO",
      ),
      ServiceItem(
        title: "Transfert",
        icon: Icons.swap_horiz_rounded,
        onTap: () => _handleTransfertTap(context),
        key: "OMY.SERVICES.TRANSFERT",
      ),
      ServiceItem(
        title: "Dépôt",
        icon: Icons.add_circle_outline_rounded,
        onTap: () => _handleDepositTap(context),
        key: "DEPOT",
      ),
      ServiceItem(
        title: "Retrait",
        icon: Icons.remove_circle_outline_rounded,
        onTap: () => _handleWithdrawalTap(context),
        key: "OMY.SERVICES.RETRAIT",
      ),
    ];
  }

  Future<void> _fetchPersonalization() async {
    try {
      final res = await ApiService.getPersonalization(widget.identifier, widget.token);
      final dataList = res["data"] as List<dynamic>?;
      if (dataList != null && dataList.isNotEmpty) {
        final profile = dataList.first as Map<String, dynamic>;
        final source = profile["_source"] as Map<String, dynamic>?;
        if (source != null) {
          final String? univers = source["univers"] as String?;
          final String? mode = source["mode"] as String?;
          final List<dynamic>? servicesList = source["liste_de_services"] as List<dynamic>?;

          if (!mounted) return;
          setState(() {
            if (univers == "OMY") {
              _activeUniverseIndex = 1;
              _pageController.jumpToPage(1);
              ApiService.activeUniverse = "OMY";
            } else if (univers == "TELCO") {
              _activeUniverseIndex = 0;
              _pageController.jumpToPage(0);
              ApiService.activeUniverse = "TELCO";
            }

            if (mode == "SIMPLE") {
              _isSimpleMode = true;
              ApiService.activeMode = "SIMPLE";
            } else if (mode == "ADVANCE") {
              _isSimpleMode = false;
              ApiService.activeMode = "ADVANCE";
            }

            if (servicesList != null && servicesList.isNotEmpty) {
              final preferredServiceIds = servicesList.map((s) => s.toString()).toList();
              
              // Trier les services selon les préférences HDFS
              _sortServices(_telcoServices, preferredServiceIds);
              _sortServices(_omyServices, preferredServiceIds);
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la recuperation de la personnalisation: $e");
    }
  }

  void _sortServices(List<ServiceItem> services, List<String> preferredServiceIds) {
    services.sort((a, b) {
      int indexA = preferredServiceIds.indexOf(a.key);
      int indexB = preferredServiceIds.indexOf(b.key);

      if (indexA != -1 && indexB != -1) {
        return indexA.compareTo(indexB);
      }
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;
      return 0;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchAccountDetails() async {
    try {
      final accountData = await ApiService.getAccount(widget.identifier, widget.token);
      final txns = await ApiService.getTransactionHistory(widget.identifier, widget.token);

      final catalogs = await Future.wait([
        ApiService.getPassInternet(widget.token).catchError((_) => []),
        ApiService.getPassIllimix(widget.token).catchError((_) => []),
        ApiService.getPassIlliflex(widget.token).catchError((_) => []),
      ]);

      final internetList = catalogs[0];
      final illimixList = catalogs[1];
      final illiflexList = catalogs[2];

      double aggregatedDataMo = 0.0;
      int aggregatedMinutes = 0;
      int aggregatedSms = 0;

      final receivedTxns = txns.where((t) => t["receiver"] == widget.identifier).toList();

      for (final txn in receivedTxns) {
        final double amount = (txn["amount"] as num?)?.toDouble() ?? 0.0;
        final String type = txn["type"] as String? ?? "";

        if (type == "ACHAT_INTERNET") {
          final pass = internetList.firstWhere(
            (p) => (p["prix"] as num?)?.toDouble() == amount,
            orElse: () => null,
          );
          if (pass != null) {
            aggregatedDataMo += pass["volumeDonneeMo"] as int? ?? 0;
          }
        } else if (type == "ACHAT_ILLIMIX") {
          final pass = illimixList.firstWhere(
            (p) => (p["prix"] as num?)?.toDouble() == amount,
            orElse: () => null,
          );
          if (pass != null) {
            aggregatedDataMo += pass["volumeDonneeMo"] as int? ?? 0;
            aggregatedMinutes += pass["minutesAppels"] as int? ?? 0;
            aggregatedSms += pass["nbMessages"] as int? ?? 0;
          }
        } else if (type == "ACHAT_ILLIFLEX") {
          final pass = illiflexList.firstWhere(
            (p) => (p["prix"] as num?)?.toDouble() == amount,
            orElse: () => null,
          );
          if (pass != null) {
            final paliersList = pass["paliers"] as List<dynamic>? ?? [];
            if (paliersList.isNotEmpty) {
              final pal = paliersList.first;
              aggregatedDataMo += pal["volumeDonneeMo"] as int? ?? 0;
              aggregatedMinutes += pal["minutesAppels"] as int? ?? 0;
            }
            aggregatedSms += pass["nbMessagesFixe"] as int? ?? 0;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _currentWalletBalance = (accountData["balance"] as num?)?.toDouble() ?? 0.0;
        _creditBalance = (accountData["callCredit"] as num?)?.toDouble() ?? 0.0;
        _simulatedDataGb = aggregatedDataMo / 1000.0;
        _simulatedCallMinutes = aggregatedMinutes;
        _simulatedSms = aggregatedSms;
      });
    } catch (_) {
      // Ignore
    }
  }

  Future<void> _fetchLastTransaction() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLastTxn = true;
      _txnError = null;
    });

    try {
      final txns = await ApiService.getTransactionHistory(widget.identifier, widget.token);
      if (!mounted) return;
      setState(() {
        if (txns.isNotEmpty) {
          // Sort to find the newest one
          final sorted = List.from(txns)
            ..sort((a, b) {
              final dateA = DateTime.parse(a["createdAt"] as String);
              final dateB = DateTime.parse(b["createdAt"] as String);
              return dateB.compareTo(dateA);
            });
          _lastTransaction = sorted.first as Map<String, dynamic>;
        } else {
          _lastTransaction = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _txnError = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLastTxn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF7900);
    const darkBgColor = Color(0xFF121212);
    const darkCardColor = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: darkBgColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8C3200), // Premium dark orange gradient
              Color(0xFF121212),
              Color(0xFF121212),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Custom Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Settings gear button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.settings_rounded, color: Colors.white),
                            onPressed: () => _showSettingsBottomSheet(context, darkCardColor, orangeColor),
                          ),
                        ),

                        // Center: Slider Switch (Simple / Avancé)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSimpleMode = !_isSimpleMode;
                              ApiService.activeMode = _isSimpleMode ? "SIMPLE" : "ADVANCE";
                            });
                          },
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isSimpleMode) ...[
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF222222),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.double_arrow_rounded, color: Colors.white, size: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  const Padding(
                                    padding: EdgeInsets.only(right: 12.0),
                                    child: Text(
                                      "Simple",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ] else ...[
                                  const Padding(
                                    padding: EdgeInsets.only(left: 12.0),
                                    child: Text(
                                      "Avancé",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF222222),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.keyboard_double_arrow_left_rounded, color: Colors.white, size: 14),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Right: Search Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.search_rounded, color: Colors.white),
                            onPressed: () {
                              showSearch(
                                context: context,
                                delegate: MaxItSearchDelegate(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Phone number dropdown row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getObfuscatedPhone(widget.identifier),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // PageView
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _activeUniverseIndex = index;
                          ApiService.activeUniverse = index == 1 ? "OMY" : "TELCO";
                        });
                      },
                      children: [
                        _buildTelcoUniversePage(context, orangeColor, darkCardColor),
                        _buildOmyUniversePage(context, orangeColor, darkCardColor),
                      ],
                    ),
                  ),
                ],
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildFloatingUniverseSelector(orangeColor, darkCardColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingUniverseSelector(Color orangeColor, Color darkCardColor) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF121212).withOpacity(0.0),
            const Color(0xFF121212).withOpacity(0.8),
            const Color(0xFF121212),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 120,
        height: 48,
        decoration: BoxDecoration(
          color: darkCardColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _activeUniverseIndex == 0 ? orangeColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.phone_android_rounded,
                    color: _activeUniverseIndex == 0 ? Colors.white : Colors.grey[500],
                    size: 20,
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _activeUniverseIndex == 1 ? orangeColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.wallet_rounded,
                    color: _activeUniverseIndex == 1 ? Colors.white : Colors.grey[500],
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelcoUniversePage(BuildContext context, Color orangeColor, Color darkCardColor) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0, bottom: 90.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TELCO Top Card: Credit and Internet Data
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12, width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone_android_rounded, color: orangeColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Crédit d'appel",
                            style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${_creditBalance.toStringAsFixed(0)} F CFA",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 0.8,
                  height: 40,
                  color: Colors.white24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.language_rounded, color: orangeColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Internet",
                            style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${_simulatedDataGb.toStringAsFixed(1)} Go",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            "NOS SERVICES",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _isSimpleMode
              ? GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                  children: [
                    ..._telcoServices.take(3).map((service) {
                      return _buildSimpleServiceItem(
                        context,
                        service.title,
                        service.icon,
                        orangeColor,
                        darkCardColor,
                        service.onTap,
                      );
                    }),
                    _buildSimpleServiceItem(
                      context,
                      "Services",
                      Icons.apps_rounded,
                      orangeColor,
                      darkCardColor,
                      () {
                        _showAllServicesModal(
                          context,
                          "TELCO",
                          _telcoServices,
                          orangeColor,
                          darkCardColor,
                        );
                      },
                    ),
                  ],
                )
              : GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                  children: _telcoServices.map((service) {
                    return _buildSimpleServiceItem(
                      context,
                      service.title,
                      service.icon,
                      orangeColor,
                      darkCardColor,
                      service.onTap,
                    );
                  }).toList(),
                ),
          const SizedBox(height: 24),

          // TELCO Bottom Card: Call Minutes and SMS
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: darkCardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12, width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: orangeColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Minutes d'appels",
                            style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$_simulatedCallMinutes minutes",
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 0.8,
                  height: 40,
                  color: Colors.white24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mail_outline_rounded, color: orangeColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "SMS",
                            style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$_simulatedSms SMS",
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOmyUniversePage(BuildContext context, Color orangeColor, Color darkCardColor) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0, bottom: 90.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // OMY Balance Card with mock QR code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12, width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isBalanceVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () {
                              setState(() {
                                _isBalanceVisible = !_isBalanceVisible;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isBalanceVisible
                                  ? "${_currentWalletBalance?.toStringAsFixed(0) ?? '0'} F"
                                  : "****** F",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildMockQrCode(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            "NOS SERVICES",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _isSimpleMode
              ? GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                  children: [
                    ..._omyServices.take(3).map((service) {
                      return _buildSimpleServiceItem(
                        context,
                        service.title,
                        service.icon,
                        orangeColor,
                        darkCardColor,
                        service.onTap,
                      );
                    }),
                    _buildSimpleServiceItem(
                      context,
                      "Services",
                      Icons.apps_rounded,
                      orangeColor,
                      darkCardColor,
                      () {
                        _showAllServicesModal(
                          context,
                          "OMY",
                          _omyServices,
                          orangeColor,
                          darkCardColor,
                        );
                      },
                    ),
                  ],
                )
              : GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                  children: _omyServices.map((service) {
                    return _buildSimpleServiceItem(
                      context,
                      service.title,
                      service.icon,
                      orangeColor,
                      darkCardColor,
                      service.onTap,
                    );
                  }).toList(),
                ),
          const SizedBox(height: 24),

            // Title of last transaction with navigation link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "DERNIÈRE TRANSACTION",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.5,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToHistory(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Voir l'historique",
                        style: TextStyle(color: orangeColor, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, color: orangeColor, size: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Display last transaction info
            if (_isLoadingLastTxn) ...[
              Center(child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: orangeColor),
              )),
            ] else if (_txnError != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _txnError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else if (_lastTransaction == null) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: darkCardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12, width: 0.8),
                ),
                child: const Text(
                  "Aucune transaction récente.",
                  style: TextStyle(color: Colors.white30, fontSize: 13),
                ),
              ),
            ] else ...[
              () {
                final String type = _lastTransaction!["type"] as String? ?? "";
                final String sender = _lastTransaction!["sender"] as String? ?? "";
                final String receiver = _lastTransaction!["receiver"] as String? ?? "";
                final double amount = (_lastTransaction!["amount"] as num?)?.toDouble() ?? 0.0;

                final bool isIncomingTransfer = type == "TRANSFERT" && receiver == widget.identifier;

                IconData icon = Icons.payment_rounded;
                String label = "Transaction";
                Color color = orangeColor;
                if (type == "DEPOT" || isIncomingTransfer) {
                  icon = type == "DEPOT" ? Icons.add_circle_outline_rounded : Icons.swap_horiz_rounded;
                  label = type == "DEPOT" ? "Dépôt Reçu" : "Transfert Reçu";
                  color = Colors.greenAccent;
                } else if (type == "RETRAIT") {
                  icon = Icons.remove_circle_outline_rounded;
                  label = "Retrait";
                  color = Colors.redAccent;
                } else if (type == "TRANSFERT") {
                  icon = Icons.swap_horiz_rounded;
                  label = "Transfert d'argent";
                } else if (type == "ACHAT_CREDIT") {
                  icon = Icons.phone_android_rounded;
                  label = "Achat Crédit";
                } else if (type == "ACHAT_INTERNET") {
                  icon = Icons.language_rounded;
                  label = "Pass Internet";
                } else if (type == "ACHAT_ILLIMIX") {
                  icon = Icons.all_inclusive_rounded;
                  label = "Pass Illimix";
                } else if (type == "ACHAT_ILLIFLEX") {
                  icon = Icons.swap_calls_rounded;
                  label = "Pass Illiflex";
                } else if (type == "PAIEMENT_RAPIDO") {
                  icon = Icons.directions_car_rounded;
                  label = "Recharge Rapido";
                }

                final String directionLabel = (type == "DEPOT")
                    ? "Depuis : Admin / Dépôt"
                    : (type == "RETRAIT")
                        ? "Depuis : Distributeur"
                        : (receiver == widget.identifier)
                            ? "Reçu de : $sender"
                            : "Destinataire : $receiver";

                final String prefixSymbol = (type == "DEPOT" || isIncomingTransfer) ? "+" : "-";

                return Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: darkCardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withOpacity(0.08),
                        radius: 22,
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              directionLabel,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "$prefixSymbol ${amount.toStringAsFixed(0)} F",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }(),
            ],
        ],
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context, Color darkCardColor, Color orangeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: darkCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  "Paramètres",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: Colors.white70),
                  title: const Text("Mon Profil", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Profil bientôt disponible"),
                        backgroundColor: Colors.white24,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
                  title: const Text("Notifications", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Notifications bientôt disponibles"),
                        backgroundColor: Colors.white24,
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text(
                    "Déconnexion",
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    _showLogoutConfirmation(context, orangeColor);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context, Color orangeColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[800]!, width: 0.5),
          ),
          title: const Text(
            "Confirmation",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Voulez-vous vraiment vous déconnecter ?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Annuler",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: Text(
                "Se déconnecter",
                style: TextStyle(color: orangeColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSimpleServiceItem(
    BuildContext context,
    String title,
    IconData icon,
    Color orangeColor,
    Color darkCardColor,
    VoidCallback onTap,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      color: darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: orangeColor,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllServicesModal(
    BuildContext context,
    String universeName,
    List<ServiceItem> services,
    Color orangeColor,
    Color darkCardColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "SERVICES $universeName",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: services.map((service) {
                    return _buildSimpleServiceItem(
                      context,
                      service.title,
                      service.icon,
                      orangeColor,
                      darkCardColor,
                      () {
                        Navigator.pop(context); // Fermer le modal
                        service.onTap(); // Executer l'action
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  void _refreshData() {
    _fetchLastTransaction();
    _fetchAccountDetails();
  }

  void _handleAchatCreditTap(BuildContext context, String serviceKey) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AchatCreditScreen(
          myNumber: widget.identifier,
          token: widget.token,
          serviceKey: serviceKey,
        ),
      ),
    );

    if (success == true && context.mounted) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Achat de crédit effectué avec succès !"),
          backgroundColor: const Color(0xFFFF7900),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _handleAchatInternetTap(BuildContext context) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AchatInternetScreen(
          myNumber: widget.identifier,
          token: widget.token,
        ),
      ),
    );

    if (success == true && context.mounted) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Achat de Pass Internet effectué avec succès !"),
          backgroundColor: const Color(0xFFFF7900),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _handleAchatIllimixTap(BuildContext context) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AchatIllimixScreen(
          myNumber: widget.identifier,
          token: widget.token,
        ),
      ),
    );

    if (success == true && context.mounted) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Achat de Pass Illimix effectué avec succès !"),
          backgroundColor: const Color(0xFFFF7900),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _handleAchatIlliflexTap(BuildContext context) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AchatIlliflexScreen(
          myNumber: widget.identifier,
          token: widget.token,
        ),
      ),
    );

    if (success == true && context.mounted) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Achat de Pass Illiflex effectué avec succès !"),
          backgroundColor: const Color(0xFFFF7900),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _handleRapidoTap(BuildContext context) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RapidoScreen(
          myNumber: widget.identifier,
          token: widget.token,
        ),
      ),
    );

    if (success == true && context.mounted) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Recharge de carte Rapido effectuée avec succès !"),
          backgroundColor: const Color(0xFFFF7900),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _handleTransfertTap(BuildContext context) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TransfertScreen(
          myNumber: widget.identifier,
          token: widget.token,
        ),
      ),
    );

    if (success == true && context.mounted) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Transfert d'argent effectué avec succès !"),
          backgroundColor: const Color(0xFFFF7900),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _handleDepositTap(BuildContext context) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DepositScreen(
          myNumber: widget.identifier,
          token: widget.token,
        ),
      ),
    );

    if (success == true && context.mounted) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Dépôt d'argent effectué avec succès !"),
          backgroundColor: const Color(0xFFFF7900),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _handleWithdrawalTap(BuildContext context) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawalScreen(
          myNumber: widget.identifier,
          token: widget.token,
        ),
      ),
    );

    if (success == true && context.mounted) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Retrait d'argent effectué avec succès !"),
          backgroundColor: const Color(0xFFFF7900),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _navigateToHistory(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          myNumber: widget.identifier,
          token: widget.token,
        ),
      ),
    );
    // Refresh last transaction and account balance when coming back
    _fetchLastTransaction();
    _fetchAccountDetails();
  }

  String _getObfuscatedPhone(String raw) {
    if (raw.length < 9) return raw;
    final first = raw.substring(0, 2);
    final last = raw.substring(raw.length - 2);
    return "$first *** ** $last";
  }

  Widget _buildMockQrCode() {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: 49,
            itemBuilder: (context, index) {
              bool isCorner = (index < 3 && index % 7 < 3) ||
                  (index < 3 && index % 7 > 4) ||
                  (index > 45 && index % 7 < 3);
              bool isDark = (index * 31 + 17) % 3 == 0 || isCorner;
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black87 : Colors.transparent,
                  borderRadius: BorderRadius.circular(isCorner ? 2 : 1),
                ),
              );
            },
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF7900), width: 1.5),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFFFF7900),
                size: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MaxItSearchDelegate extends SearchDelegate<String> {
  final List<String> servicesList = [
  ];

  @override
  String get searchFieldLabel => 'Rechercher un service...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded, color: Colors.white70),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = servicesList
        .where((service) => service.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Container(
      color: const Color(0xFF121212),
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(results[index], style: const TextStyle(color: Colors.white)),
            leading: const Icon(Icons.bolt_rounded, color: Color(0xFFFF7900)),
            onTap: () {
              close(context, results[index]);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Service sélectionné : ${results[index]}'),
                  backgroundColor: const Color(0xFFFF7900),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = servicesList
        .where((service) => service.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Container(
      color: const Color(0xFF121212),
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(suggestions[index], style: const TextStyle(color: Colors.white)),
            leading: const Icon(Icons.search_rounded, color: Colors.grey),
            onTap: () {
              query = suggestions[index];
              showResults(context);
            },
          );
        },
      ),
    );
  }
}
