import 'package:flutter/material.dart';
import 'package:client_ui/screens/login_screen.dart';
import 'package:client_ui/screens/achat_credit_screen.dart';
import 'package:client_ui/screens/achat_internet_screen.dart';
import 'package:client_ui/screens/achat_illimix_screen.dart';
import 'package:client_ui/screens/achat_illiflex_screen.dart';
import 'package:client_ui/screens/rapido_screen.dart';
import 'package:client_ui/screens/transfert_screen.dart';

class HomeScreen extends StatelessWidget {
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
        child: Padding(
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
                        "Numéro : $identifier",
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
              Expanded(
                child: GridView.count(
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
                  ],
                ),
              ),
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
          myNumber: identifier,
          token: token,
        ),
      ),
    );

    if (success == true && context.mounted) {
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
          myNumber: identifier,
          token: token,
        ),
      ),
    );

    if (success == true && context.mounted) {
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
          myNumber: identifier,
          token: token,
        ),
      ),
    );

    if (success == true && context.mounted) {
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
          myNumber: identifier,
          token: token,
        ),
      ),
    );

    if (success == true && context.mounted) {
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
          myNumber: identifier,
          token: token,
        ),
      ),
    );

    if (success == true && context.mounted) {
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
          myNumber: identifier,
          token: token,
        ),
      ),
    );

    if (success == true && context.mounted) {
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
}

class MaxItSearchDelegate extends SearchDelegate<String> {
  final List<String> servicesList = [
    "Achat Crédit",
    "Achat Illiflex",
    "Achat Illimix",
    "Achat Internet",
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
