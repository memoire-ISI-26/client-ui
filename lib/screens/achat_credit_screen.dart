import 'package:flutter/material.dart';
import 'package:client_ui/services/api_service.dart';
import 'package:client_ui/services/favorites_service.dart';

class AchatCreditScreen extends StatefulWidget {
  final String myNumber;
  final String token;

  const AchatCreditScreen({
    super.key,
    required this.myNumber,
    required this.token,
  });

  @override
  State<AchatCreditScreen> createState() => _AchatCreditScreenState();
}

class _AchatCreditScreenState extends State<AchatCreditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _recipientController;
  final _amountController = TextEditingController();

  bool _isLoadingBalance = false;
  bool _isSubmitting = false;
  double? _currentBalance;
  String? _errorMessage;

  // Preset quick credit values
  final List<int> _quickAmounts = [500, 1000, 2000, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(text: widget.myNumber);
    _recipientController.addListener(_onRecipientChanged);
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _recipientController.removeListener(_onRecipientChanged);
    _recipientController.dispose();
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onRecipientChanged() {
    setState(() {});
  }

  void _onAmountChanged() {
    // Rebuild to update selected quick chips highlight
    setState(() {});
  }

  void _goToConfirmation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoadingBalance = true;
      _errorMessage = null;
    });

    try {
      final balance = await ApiService.getBalance(widget.myNumber, widget.token);
      setState(() {
        _currentBalance = balance;
      });
      _showConfirmationDialog();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      setState(() {
        _isLoadingBalance = false;
      });
    }
  }

  void _showConfirmationDialog() {
    const orangeColor = Color(0xFFFF7900);
    final double purchaseAmount = double.tryParse(_amountController.text) ?? 0.0;
    final bool isWalletSufficient = (_currentBalance ?? 0.0) >= purchaseAmount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF121212),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey[800]!, width: 0.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: orangeColor, size: 26),
                  SizedBox(width: 10),
                  Text(
                    "Validation de l'achat",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Détails de la transaction :",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow("Destinataire", _recipientController.text),
                  _buildInfoRow("Montant acheté", "${purchaseAmount.toStringAsFixed(0)} F CFA"),
                  const Divider(color: Colors.white12, height: 24),

                  const Text(
                    "Mode de paiement :",
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // Principal Wallet Option Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: !isWalletSufficient
                          ? Colors.white.withOpacity(0.02)
                          : orangeColor.withOpacity(0.08),
                      border: Border.all(
                        color: !isWalletSufficient ? Colors.white12 : orangeColor,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.radio_button_checked,
                          color: !isWalletSufficient ? Colors.white24 : orangeColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Compte Principal",
                                    style: TextStyle(
                                      color: !isWalletSufficient ? Colors.white38 : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (!isWalletSufficient)
                                    const Text(
                                      "Solde insuffisant",
                                      style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Solde: ${_currentBalance?.toStringAsFixed(2) ?? '0.00'} F CFA",
                                style: TextStyle(
                                  color: !isWalletSufficient ? Colors.white24 : Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                ],
              ),
              actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                Navigator.pop(context); // Close confirmation dialog only
                              },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Annuler",
                          style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_isSubmitting || !isWalletSufficient)
                            ? null
                            : () => _confirmPurchase(setDialogState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: orangeColor.withOpacity(0.3),
                          disabledForegroundColor: Colors.white24,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Confirmer", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmPurchase(StateSetter setDialogState) async {
    setDialogState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text);
      await ApiService.purchaseCredit(
        sender: widget.myNumber,
        receiver: _recipientController.text.trim(),
        amount: amount,
        token: widget.token,
      );

      if (mounted) {
        Navigator.pop(context); // Close confirmation dialog
        Navigator.pop(context, true); // Return to home screen indicating success
      }
    } catch (e) {
      final errorText = e.toString().replaceAll('Exception:', '').trim();
      setDialogState(() {
        _errorMessage = errorText;
        _isSubmitting = false;
      });
      setState(() {
        _errorMessage = errorText;
      });
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF7900);
    const darkBgColor = Color(0xFF121212);

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
          "Achat de crédit",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Recipient capsule input
                const Text(
                  "Numéro du destinataire",
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Text("🇸🇳", style: TextStyle(fontSize: 16)),
                            SizedBox(width: 4),
                            Text("+221", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _recipientController,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "77XXXXXXX",
                            hintStyle: TextStyle(color: Colors.white24),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Veuillez saisir le numéro.";
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_recipientController.text.trim().isNotEmpty && _recipientController.text.trim() != widget.myNumber) ...[
                        IconButton(
                          icon: Icon(
                            FavoritesService.isFavorite(_recipientController.text.trim()) ? Icons.favorite : Icons.favorite_border,
                            color: FavoritesService.isFavorite(_recipientController.text.trim()) ? orangeColor : Colors.white30,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              final numStr = _recipientController.text.trim();
                              if (FavoritesService.isFavorite(numStr)) {
                                FavoritesService.removeFavorite(numStr);
                              } else {
                                FavoritesService.addFavorite(numStr);
                              }
                            });
                          },
                        ),
                      ],
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white30, size: 18),
                        onPressed: () {
                          _recipientController.clear();
                        },
                      ),
                    ],
                  ),
                ),
                if (FavoritesService.favoriteNumbers.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: FavoritesService.favoriteNumbers.length,
                      itemBuilder: (context, index) {
                        final numStr = FavoritesService.favoriteNumbers[index];
                        final isSelected = _recipientController.text.trim() == numStr;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            backgroundColor: const Color(0xFF1E1E1E),
                            side: BorderSide(
                              color: isSelected ? orangeColor : Colors.white12,
                              width: 0.8,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            label: Row(
                              children: [
                                const Icon(Icons.favorite, color: orangeColor, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  numStr,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            onPressed: () {
                              setState(() {
                                _recipientController.text = numStr;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // 2. Amount capsule input
                const Text(
                  "Montant de la recharge",
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money_rounded, color: orangeColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Saisir le montant (F CFA)",
                            hintStyle: TextStyle(color: Colors.white24),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Veuillez saisir un montant.";
                            }
                            final val = double.tryParse(value);
                            if (val == null || val <= 0) {
                              return "Le montant doit être supérieur à 0.";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Quick select chips
                const Text(
                  "Montants rapides",
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _quickAmounts.map((amount) {
                    final isSelected = _amountController.text == amount.toString();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _amountController.text = amount.toString();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? orangeColor : const Color(0xFF1E1E1E),
                          border: Border.all(color: isSelected ? orangeColor : Colors.white24, width: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "$amount F CFA",
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 48),

                // 4. Bottom action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          "Quitter",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoadingBalance ? null : _goToConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoadingBalance
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "Acheter",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
