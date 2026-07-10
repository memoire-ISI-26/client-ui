import 'package:flutter/material.dart';
import 'package:client_ui/services/api_service.dart';
import 'package:client_ui/services/favorites_service.dart';

class AchatIlliflexScreen extends StatefulWidget {
  final String myNumber;
  final String token;

  const AchatIlliflexScreen({
    super.key,
    required this.myNumber,
    required this.token,
  });

  @override
  State<AchatIlliflexScreen> createState() => _AchatIlliflexScreenState();
}

class _AchatIlliflexScreenState extends State<AchatIlliflexScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _recipientController;

  // Selected state
  String? _selectedPeriod; // "JOUR", "SEMAINE", "MOIS"
  Map<String, dynamic>? _selectedPass;
  Map<String, dynamic>? _selectedPalier;

  // State flags
  bool _isLoadingPasses = true;
  bool _isLoadingBalance = false;
  bool _isSubmitting = false;

  // Loaded data
  List<Map<String, dynamic>> _allPasses = [];

  // Balances
  double? _currentWalletBalance;
  double _creditBalance = 0.0;

  String? _errorMessage;

  final List<Map<String, String>> _periods = [
    {"label": "Jour", "value": "JOUR"},
    {"label": "Semaine", "value": "SEMAINE"},
    {"label": "Mois", "value": "MOIS"},
  ];

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(text: widget.myNumber);
    _recipientController.addListener(_onRecipientChanged);
    _loadPasses();
  }

  @override
  void dispose() {
    _recipientController.removeListener(_onRecipientChanged);
    _recipientController.dispose();
    super.dispose();
  }

  void _onRecipientChanged() {
    setState(() {});
  }

  Future<void> _loadPasses() async {
    setState(() {
      _isLoadingPasses = true;
      _errorMessage = null;
    });

    try {
      final passes = await ApiService.getPassIlliflex(widget.token);
      setState(() {
        _allPasses = passes.map((p) => {
          "id": p["id"] as int,
          "nom": p["nom"] as String,
          "prix": (p["prix"] as num).toDouble(),
          "periode": p["periode"] as String,
          "nbMessagesFixe": p["nbMessagesFixe"] as int,
          "paliers": (p["paliers"] as List<dynamic>?)?.map((pal) => {
            "id": pal["id"] as int,
            "nomPalier": pal["nomPalier"] as String,
            "volumeDonneeMo": pal["volumeDonneeMo"] as int,
            "minutesAppels": pal["minutesAppels"] as int,
          }).toList() ?? [],
        }).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _allPasses = [];
      });
    } finally {
      setState(() {
        _isLoadingPasses = false;
      });
    }
  }

  void _goToConfirmation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPass == null) {
      setState(() {
        _errorMessage = "Veuillez sélectionner un pass Illiflex.";
      });
      return;
    }
    if (_selectedPalier == null) {
      setState(() {
        _errorMessage = "Veuillez sélectionner une formule (option).";
      });
      return;
    }

    setState(() {
      _isLoadingBalance = true;
      _errorMessage = null;
    });

    try {
      final accountData = await ApiService.getAccount(widget.myNumber, widget.token);
      setState(() {
        _currentWalletBalance = (accountData["balance"] as num?)?.toDouble() ?? 0.0;
        _creditBalance = (accountData["callCredit"] as num?)?.toDouble() ?? 0.0;
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
    final double price = _selectedPass!["prix"];
    final bool isWalletSufficient = (_currentWalletBalance ?? 0.0) >= price;
    final bool isCreditSufficient = _creditBalance >= price;

    String selectedPaymentSource = "PRINCIPAL";
    if (!isWalletSufficient && isCreditSufficient) {
      selectedPaymentSource = "CREDIT";
    }

    final bool canConfirm = isWalletSufficient || isCreditSufficient;

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
                  _buildInfoRow("Destinataire", _recipientController.text.trim()),
                  _buildInfoRow("Pass Illiflex", _selectedPass!["nom"]),
                  _buildInfoRow("Formule choisie", _selectedPalier!["nomPalier"]),
                  _buildInfoRow("Appels", "${_selectedPalier!["minutesAppels"]} min"),
                  _buildInfoRow("Internet", "${_selectedPalier!["volumeDonneeMo"]} Mo"),
                  _buildInfoRow("SMS inclus", "${_selectedPass!["nbMessagesFixe"]} SMS"),
                  _buildInfoRow("Montant", "${price.toStringAsFixed(0)} F CFA"),
                  const Divider(color: Colors.white12, height: 24),

                  const Text(
                    "Mode de paiement :",
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // Wallet Option Card
                  GestureDetector(
                    onTap: !isWalletSufficient
                        ? null
                        : () {
                            setDialogState(() {
                              selectedPaymentSource = "PRINCIPAL";
                            });
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: !isWalletSufficient
                            ? Colors.white.withOpacity(0.02)
                            : (selectedPaymentSource == "PRINCIPAL" ? orangeColor.withOpacity(0.08) : Colors.transparent),
                        border: Border.all(
                          color: !isWalletSufficient
                              ? Colors.white12
                              : (selectedPaymentSource == "PRINCIPAL" ? orangeColor : Colors.white24),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedPaymentSource == "PRINCIPAL" ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: !isWalletSufficient
                                ? Colors.white24
                                : (selectedPaymentSource == "PRINCIPAL" ? orangeColor : Colors.white54),
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
                                    const Text("Compte Principal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    if (!isWalletSufficient)
                                      const Text(
                                        "Solde insuffisant",
                                        style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Solde: ${_currentWalletBalance?.toStringAsFixed(2) ?? '0.00'} F CFA",
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
                  ),
                  const SizedBox(height: 10),

                  // Credit Option Card
                  GestureDetector(
                    onTap: !isCreditSufficient
                        ? null
                        : () {
                            setDialogState(() {
                              selectedPaymentSource = "CREDIT";
                            });
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: !isCreditSufficient
                            ? Colors.white.withOpacity(0.02)
                            : (selectedPaymentSource == "CREDIT" ? orangeColor.withOpacity(0.08) : Colors.transparent),
                        border: Border.all(
                          color: !isCreditSufficient
                              ? Colors.white12
                              : (selectedPaymentSource == "CREDIT" ? orangeColor : Colors.white24),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedPaymentSource == "CREDIT" ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: !isCreditSufficient
                                ? Colors.white24
                                : (selectedPaymentSource == "CREDIT" ? orangeColor : Colors.white54),
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
                                    const Text("Solde Crédit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    if (!isCreditSufficient)
                                      const Text(
                                        "Solde insuffisant",
                                        style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Solde: ${_creditBalance.toStringAsFixed(2)} F CFA",
                                  style: TextStyle(
                                    color: !isCreditSufficient ? Colors.white24 : Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                        onPressed: (_isSubmitting || !canConfirm)
                            ? null
                            : () => _confirmPurchase(setDialogState, selectedPaymentSource),
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

  void _confirmPurchase(StateSetter setDialogState, String paymentSource) async {
    setDialogState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final double price = _selectedPass!["prix"];
    final String method = paymentSource == "CREDIT" ? "CREDIT" : "WALLET";

    try {
      await ApiService.purchasePassIlliflex(
        receiverNumber: _recipientController.text.trim(),
        passId: _selectedPass!["id"] as int,
        passName: _selectedPass!["nom"] as String,
        amount: price,
        paymentMethod: method,
        token: widget.token,
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

    // Filter passes by selected period
    final List<Map<String, dynamic>> filteredPasses = _selectedPeriod == null
        ? []
        : _allPasses.where((p) => p["periode"] == _selectedPeriod).toList();

    // Get paliers of the selected pass
    final List<Map<String, dynamic>> paliers = _selectedPass == null
        ? []
        : List<Map<String, dynamic>>.from(_selectedPass!["paliers"]);

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
          "Achat Pass Illiflex",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: _isLoadingPasses
            ? const Center(child: CircularProgressIndicator(color: orangeColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Recipient input capsule
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
                                  hintText: "770000000",
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

                      // 2. Select Period Dropdown
                      const Text(
                        "Choisir la période",
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: const Color(0xFF1E1E1E),
                            value: _selectedPeriod,
                            hint: const Text("Sélectionner la période", style: TextStyle(color: Colors.white30, fontSize: 14)),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                            isExpanded: true,
                            items: _periods.map((p) {
                              return DropdownMenuItem<String>(
                                value: p["value"],
                                child: Text(p["label"]!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedPeriod = val;
                                _selectedPass = null;
                                _selectedPalier = null;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Select Pass Dropdown
                      if (_selectedPeriod != null) ...[
                        const Text(
                          "Choisir le pass",
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Map<String, dynamic>>(
                              dropdownColor: const Color(0xFF1E1E1E),
                              value: _selectedPass,
                              hint: const Text("Sélectionner le pass", style: TextStyle(color: Colors.white30, fontSize: 14)),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                              isExpanded: true,
                              items: filteredPasses.map((p) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: p,
                                  child: Text(
                                    "${p["nom"]} - ${p["prix"].toStringAsFixed(0)} F CFA",
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedPass = val;
                                  _selectedPalier = null;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 4. Select Palier Dropdown
                      if (_selectedPass != null) ...[
                        const Text(
                          "Choisir votre formule",
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Map<String, dynamic>>(
                              dropdownColor: const Color(0xFF1E1E1E),
                              value: _selectedPalier,
                              hint: const Text("Sélectionner la formule", style: TextStyle(color: Colors.white30, fontSize: 14)),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                              isExpanded: true,
                              items: paliers.map((pal) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: pal,
                                  child: Text(
                                    "${pal["nomPalier"]} (${pal["minutesAppels"]} min / ${pal["volumeDonneeMo"]} Mo)",
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedPalier = val;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 5. Formula Details display card
                      if (_selectedPalier != null) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                "Détails de la formule sélectionnée :",
                                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow("Appels", "${_selectedPalier!["minutesAppels"]} minutes"),
                              _buildInfoRow("Internet", "${_selectedPalier!["volumeDonneeMo"]} Mo"),
                              _buildInfoRow("SMS inclus", "${_selectedPass!["nbMessagesFixe"]} SMS"),
                              _buildInfoRow("Période de validité", _selectedPeriod == "JOUR" ? "1 Jour" : (_selectedPeriod == "SEMAINE" ? "7 Jours" : "30 Jours")),
                              const Divider(color: Colors.white12, height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Prix total", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(
                                    "${_selectedPass!["prix"].toStringAsFixed(0)} F CFA",
                                    style: const TextStyle(color: orangeColor, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 6. Action buttons
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
