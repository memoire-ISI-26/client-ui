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

  @override
  void initState() {
    super.initState();
    _fetchLastTransaction();
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
      appBar: AppBar(
        backgroundColor: darkBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings_rounded, color: Colors.white),
          tooltip: "Paramètres",
          onPressed: () => _showSettingsBottomSheet(context, darkCardColor, orangeColor),
        ),
        title: const Text(
          "Tableau de Bord Client",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            tooltip: "Recherche",
            onPressed: () {
              showSearch(
                context: context,
                delegate: MaxItSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: darkCardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[800]!, width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: orangeColor.withOpacity(0.1),
                        child: const Icon(Icons.person_rounded, size: 48, color: orangeColor),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Bienvenue dans Max It",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Numéro : ${widget.identifier}",
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
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
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildServiceItem(
                    context,
                    "Achat Crédit",
                    Icons.phone_android_rounded,
                    orangeColor,
                    darkCardColor,
                    () => _handleAchatCreditTap(context),
                  ),
                  _buildServiceItem(
                    context,
                    "Achat Illiflex",
                    Icons.swap_calls_rounded,
                    orangeColor,
                    darkCardColor,
                    () => _handleAchatIlliflexTap(context),
                  ),
                  _buildServiceItem(
                    context,
                    "Achat Illimix",
                    Icons.all_inclusive_rounded,
                    orangeColor,
                    darkCardColor,
                    () => _handleAchatIllimixTap(context),
                  ),
                  _buildServiceItem(
                    context,
                    "Achat Internet",
                    Icons.language_rounded,
                    orangeColor,
                    darkCardColor,
                    () => _handleAchatInternetTap(context),
                  ),
                  _buildServiceItem(
                    context,
                    "Rapido",
                    Icons.directions_car_rounded,
                    orangeColor,
                    darkCardColor,
                    () => _handleRapidoTap(context),
                  ),
                  _buildServiceItem(
                    context,
                    "Transfert",
                    Icons.swap_horiz_rounded,
                    orangeColor,
                    darkCardColor,
                    () => _handleTransfertTap(context),
                  ),
                  _buildServiceItem(
                    context,
                    "Dépôt",
                    Icons.add_circle_outline_rounded,
                    orangeColor,
                    darkCardColor,
                    () => _handleDepositTap(context),
                  ),
                  _buildServiceItem(
                    context,
                    "Retrait",
                    Icons.remove_circle_outline_rounded,
                    orangeColor,
                    darkCardColor,
                    () => _handleWithdrawalTap(context),
                  ),
                ],
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
                    child: const Row(
                      children: [
                        Text(
                          "Voir l'historique",
                          style: TextStyle(color: orangeColor, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, color: orangeColor, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Display last transaction info
              if (_isLoadingLastTxn) ...[
                const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
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
        ),
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

  Widget _buildServiceItem(
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
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[800]!, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: orangeColor,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAchatCreditTap(BuildContext context) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AchatCreditScreen(
          myNumber: widget.identifier,
          token: widget.token,
        ),
      ),
    );

    if (success == true && context.mounted) {
      _fetchLastTransaction();
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
      _fetchLastTransaction();
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
      _fetchLastTransaction();
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
      _fetchLastTransaction();
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
      _fetchLastTransaction();
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
      _fetchLastTransaction();
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
      _fetchLastTransaction();
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
      _fetchLastTransaction();
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
    // Refresh last transaction when coming back
    _fetchLastTransaction();
  }
}

class MaxItSearchDelegate extends SearchDelegate<String> {
  final List<String> servicesList = [
    "Achat Crédit",
    "Achat Illiflex",
    "Achat Illimix",
    "Achat Internet",
    "Dépôt",
    "Retrait",
    "Rapido",
    "Transfert",
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
