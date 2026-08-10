import 'package:flutter/material.dart';
import 'package:client_ui/services/api_service.dart';

class WithdrawalScreen extends StatefulWidget {
  final String myNumber;
  final String token;

  const WithdrawalScreen({
    super.key,
    required this.myNumber,
    required this.token,
  });

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  bool _isLoadingBalance = false;
  bool _isSubmitting = false;
  double? _currentWalletBalance;
  String? _errorMessage;

  final List<double> _quickAmounts = [1000, 2000, 5000, 10000, 20000, 50000];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  void _goToConfirmation() async {
    if (!_formKey.currentState!.validate()) return;

    final double withdrawAmount = double.parse(_amountController.text.trim());

    setState(() {
      _isLoadingBalance = true;
      _errorMessage = null;
    });

    try {
      final accountData = await ApiService.getAccount(widget.myNumber, widget.token);
      final double currentBalance = (accountData["balance"] as num?)?.toDouble() ?? 0.0;

      setState(() {
        _currentWalletBalance = currentBalance;
      });

      if (withdrawAmount > currentBalance) {
        setState(() {
          _errorMessage = "Solde insuffisant pour effectuer ce retrait (Solde : ${currentBalance.toStringAsFixed(2)} F CFA).";
        });
        return;
      }

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
    final double withdrawAmount = double.parse(_amountController.text.trim());
    final double initialBalance = _currentWalletBalance ?? 0.0;
    final double expectedFinalBalance = initialBalance - withdrawAmount;

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
                  Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 26),
                  SizedBox(width: 10),
                  Text(
                    "Confirmation du Retrait",
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
                  _buildInfoRow("Compte débité", widget.myNumber),
                  _buildInfoRow("Type d'opération", "Retrait d'argent"),
                  _buildInfoRow("Montant à retirer", "${withdrawAmount.toStringAsFixed(0)} F CFA"),
                  const Divider(color: Colors.white12, height: 24),
                  _buildInfoRow("Solde actuel", "${initialBalance.toStringAsFixed(2)} F CFA"),
                  _buildInfoRow("Solde après retrait", "${expectedFinalBalance.toStringAsFixed(2)} F CFA"),
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
                                Navigator.pop(context);
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
                        onPressed: _isSubmitting
                            ? null
                            : () => _confirmWithdraw(setDialogState, withdrawAmount),
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

  void _confirmWithdraw(StateSetter setDialogState, double amount) async {
    setDialogState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ApiService.withdraw(
        number: widget.myNumber,
        amount: amount,
        token: widget.token,
      );

      // DQN Reward (+1.0 pour transaction effectuée)
      ApiService.sendDqnReward(
        msisdn: widget.myNumber,
        serviceId: "OMY.SERVICES.RETRAIT",
        reward: 1.0,
        token: widget.token,
        univers: ApiService.activeUniverse,
        mode: ApiService.activeMode,
      );

      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context, true); // Return to home with success
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
          "Retrait d'argent",
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
                // 1. Beneficiary non-editable card
                const Text(
                  "Compte débité",
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 0.8),
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
                      const SizedBox(width: 16),
                      Text(
                        widget.myNumber,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const Icon(Icons.lock_outline_rounded, color: Colors.white30, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Amount field
                const Text(
                  "Saisir le montant du retrait (F CFA)",
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: TextFormField(
                    controller: _amountController,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Ex : 5000",
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Veuillez saisir le montant.";
                      }
                      final amt = double.tryParse(value.trim());
                      if (amt == null || amt <= 0) {
                        return "Veuillez saisir un montant valide (> 0).";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Quick Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickAmounts.map((amt) {
                    final isSelected = _amountController.text.trim() == amt.toStringAsFixed(0);
                    return ActionChip(
                      backgroundColor: const Color(0xFF1E1E1E),
                      side: BorderSide(
                        color: isSelected ? orangeColor : Colors.white12,
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      label: Text(
                        "${amt.toStringAsFixed(0)} F",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        setState(() {
                          _amountController.text = amt.toStringAsFixed(0);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 36),

                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],

                // 4. Action buttons
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
                                "Retirer",
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
