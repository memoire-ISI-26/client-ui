import 'package:flutter/material.dart';
import 'package:client_ui/services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  final String myNumber;
  final String token;

  const HistoryScreen({
    super.key,
    required this.myNumber,
    required this.token,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final txns = await ApiService.getTransactionHistory(widget.myNumber, widget.token);
      setState(() {
        // Sort transactions to put the newest first
        _transactions = List.from(txns)
          ..sort((a, b) {
            final dateA = DateTime.parse(a["createdAt"] as String);
            final dateB = DateTime.parse(b["createdAt"] as String);
            return dateB.compareTo(dateA);
          });
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case "DEPOT":
        return Icons.add_circle_outline_rounded;
      case "RETRAIT":
        return Icons.remove_circle_outline_rounded;
      case "TRANSFERT":
        return Icons.swap_horiz_rounded;
      case "ACHAT_CREDIT":
        return Icons.phone_android_rounded;
      case "ACHAT_INTERNET":
        return Icons.language_rounded;
      case "ACHAT_ILLIMIX":
        return Icons.all_inclusive_rounded;
      case "ACHAT_ILLIFLEX":
        return Icons.swap_calls_rounded;
      case "PAIEMENT_MARCHAND":
        return Icons.storefront_rounded;
      case "PAIEMENT_RAPIDO":
        return Icons.directions_car_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case "DEPOT":
        return "Dépôt Reçu";
      case "RETRAIT":
        return "Retrait";
      case "TRANSFERT":
        return "Transfert d'argent";
      case "ACHAT_CREDIT":
        return "Achat Crédit";
      case "ACHAT_INTERNET":
        return "Achat Pass Internet";
      case "ACHAT_ILLIMIX":
        return "Achat Pass Illimix";
      case "ACHAT_ILLIFLEX":
        return "Achat Pass Illiflex";
      case "PAIEMENT_MARCHAND":
        return "Paiement Marchand";
      case "PAIEMENT_RAPIDO":
        return "Recharge Rapido";
      default:
        return "Transaction";
    }
  }

  Color _getTypeColor(String type) {
    if (type == "DEPOT") {
      return Colors.greenAccent;
    } else if (type == "RETRAIT") {
      return Colors.redAccent;
    } else {
      return const Color(0xFFFF7900); // Orange
    }
  }

  String _formatDateTime(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return "$day/$month/$year à $hour:$minute";
    } catch (_) {
      return rawDate;
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          "Historique des Transactions",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchHistory,
          color: orangeColor,
          backgroundColor: darkCardColor,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: orangeColor))
              : _errorMessage != null
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: CenterAlignment.alignment, // Center content
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _fetchHistory,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orangeColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Réessayer"),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _transactions.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded, color: Colors.white24, size: 64),
                              SizedBox(height: 16),
                              Text(
                                "Aucune transaction enregistrée.",
                                style: TextStyle(color: Colors.grey, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final txn = _transactions[index];
                            final String type = txn["type"] as String? ?? "";
                            final String sender = txn["sender"] as String? ?? "";
                            final String receiver = txn["receiver"] as String? ?? "";
                            final double amount = (txn["amount"] as num?)?.toDouble() ?? 0.0;
                            final String dateStr = txn["createdAt"] as String? ?? "";

                            final bool isIncomingTransfer = type == "TRANSFERT" && receiver == widget.myNumber;
                            final color = (type == "DEPOT" || isIncomingTransfer) ? Colors.greenAccent : _getTypeColor(type);
                            final icon = _getTypeIcon(type);
                            final label = isIncomingTransfer ? "Transfert Reçu" : _getTypeLabel(type);

                            // Format transaction party
                            String directionLabel = "";
                            if (type == "DEPOT") {
                              directionLabel = "Depuis : Admin / Dépôt";
                            } else if (type == "RETRAIT") {
                              directionLabel = "Depuis : Distributeur";
                            } else {
                              directionLabel = receiver == widget.myNumber
                                  ? "Reçu de : $sender"
                                  : "Destinataire : $receiver";
                            }

                            final String prefixSymbol = (type == "DEPOT" || isIncomingTransfer) ? "+" : "-";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12.0),
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
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDateTime(dateStr),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 11,
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
                          },
                        ),
        ),
      ),
    );
  }
}

class CenterAlignment {
  static const alignment = Alignment.center;
}
