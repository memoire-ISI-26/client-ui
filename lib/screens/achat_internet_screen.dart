import 'package:flutter/material.dart';
import 'package:client_ui/services/api_service.dart';

class AchatInternetScreen extends StatefulWidget {
  final String myNumber;
  final String token;

  const AchatInternetScreen({
    super.key,
    required this.myNumber,
    required this.token,
  });

  @override
  State<AchatInternetScreen> createState() => _AchatInternetScreenState();
}

class _AchatInternetScreenState extends State<AchatInternetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _recipientController;

  // Track expanded category (accordion)
  String? _expandedCategory;

  // Selected pass object
  Map<String, dynamic>? _selectedPass;

  // State flags
  bool _isLoadingPasses = true;
  bool _isLoadingBalance = false;
  bool _isSubmitting = false;

  // Data lists
  List<Map<String, dynamic>> _allPasses = [];

  // Balances
  double? _currentWalletBalance; // solde compte principal (from API)
  double _creditBalance = 0.0; // solde crédit (from API)

  String? _errorMessage;

  // UI Categories mapped to periods
  final List<Map<String, String>> _categories = [
    {"title": "Pass Max it TV Plus", "period": "TV_PLUS"},
    {"title": "Accès Max it TV", "period": "TV_ACCESS"},
    {"title": "Jour", "period": "JOUR"},
    {"title": "Nuit", "period": "NUIT"},
    {"title": "Semaine", "period": "SEMAINE"},
    {"title": "Mois", "period": "MOIS"},
  ];

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(text: widget.myNumber);
    _loadPasses();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _loadPasses() async {
    setState(() {
      _isLoadingPasses = true;
      _errorMessage = null;
    });

    try {
      final passes = await ApiService.getPassInternet(widget.token);
      setState(() {
        _allPasses = passes.map((p) => {
          "id": p["id"] as int,
          "nom": p["nom"] as String,
          "prix": (p["prix"] as num).toDouble(),
          "periode": p["periode"] as String,
          "volumeDonneeMo": p["volumeDonneeMo"] as int,
        }).toList();
      });
      
      // Auto expand the first category that has passes
      for (var cat in _categories) {
        final period = cat["period"]!;
        final hasPasses = _allPasses.any((p) => p["periode"] == period);
        if (hasPasses) {
          _expandedCategory = cat["title"];
          break;
        }
      }
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
        _errorMessage = "Veuillez sélectionner un pass internet dans la liste.";
      });
      return;
    }

    setState(() {
      _isLoadingBalance = true;
      _errorMessage = null;
    });

    try {
      // Fetch entire account info to get real wallet balance and callCredit
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
    String selectedPaymentSource = "PRINCIPAL"; // PRINCIPAL or CREDIT

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
                  _buildInfoRow("Pass sélectionné", _selectedPass!["nom"]),
                  _buildInfoRow("Montant", "${_selectedPass!["prix"]} F CFA"),
                  const Divider(color: Colors.white12, height: 24),
                  
                  // Styled payment source options
                  const Text(
                    "Mode de paiement :",
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  
                  // Principal Wallet Option Card
                  GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedPaymentSource = "PRINCIPAL";
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedPaymentSource == "PRINCIPAL" ? orangeColor.withOpacity(0.08) : Colors.transparent,
                        border: Border.all(
                          color: selectedPaymentSource == "PRINCIPAL" ? orangeColor : Colors.white24,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedPaymentSource == "PRINCIPAL" ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: selectedPaymentSource == "PRINCIPAL" ? orangeColor : Colors.white54,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Compte Principal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text("Solde: ${_currentWalletBalance?.toStringAsFixed(2) ?? '0.00'} F CFA", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Phone Credit Option Card
                  GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedPaymentSource = "CREDIT";
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedPaymentSource == "CREDIT" ? orangeColor.withOpacity(0.08) : Colors.transparent,
                        border: Border.all(
                          color: selectedPaymentSource == "CREDIT" ? orangeColor : Colors.white24,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedPaymentSource == "CREDIT" ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: selectedPaymentSource == "CREDIT" ? orangeColor : Colors.white54,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Solde Crédit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text("Solde: ${_creditBalance.toStringAsFixed(2)} F CFA", style: const TextStyle(color: Colors.grey, fontSize: 11)),
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
                                Navigator.pop(context); // Close confirmation dialog, preserving outer fields
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
                        onPressed: _isSubmitting ? null : () => _confirmPurchase(setDialogState, selectedPaymentSource),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          foregroundColor: Colors.white,
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
      await ApiService.purchasePassInternet(
        receiverNumber: _recipientController.text.trim(),
        passId: _selectedPass!["id"],
        passName: _selectedPass!["nom"],
        amount: price,
        paymentMethod: method,
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

  String _getValidityDescription(String period) {
    switch (period.toUpperCase()) {
      case "NUIT":
        return "Valable 23h-6h";
      case "JOUR":
        return "Valable 24 heures";
      case "SEMAINE":
        return "Valable 7 jours";
      case "MOIS":
        return "Valable 30 jours";
      default:
        return "Valable selon conditions";
    }
  }

  Widget _buildCategoryAccordion(String title, String period) {
    const orangeColor = Color(0xFFFF7900);
    final isExpanded = _expandedCategory == title;
    final categoryPasses = _allPasses.where((p) => p["periode"] == period).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedCategory = isExpanded ? null : title;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Row(
              children: [
                const Icon(Icons.public, color: orangeColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: orangeColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        if (isExpanded)
          Container(
            color: Colors.black12,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: categoryPasses.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      "Aucun pass disponible",
                      style: TextStyle(color: Colors.white30, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: categoryPasses.map((pass) {
                      final isSelected = _selectedPass != null && _selectedPass!["id"] == pass["id"];
                      final volumeMo = pass["volumeDonneeMo"] as int;
                      final volumeText = volumeMo >= 1024 
                          ? "${(volumeMo / 1024).toStringAsFixed(0)} Go" 
                          : "$volumeMo Mo";
                          
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPass = pass;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? orangeColor : Colors.grey[800]!,
                              width: isSelected ? 1.5 : 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left column: Pass name and validity
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${pass["nom"]} ${pass["prix"].toStringAsFixed(0)} FCFA",
                                      style: const TextStyle(
                                        color: orangeColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getValidityDescription(pass["periode"]),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Right column: Blue globe icon & Volume data
                              Column(
                                children: [
                                  const Icon(Icons.language, color: Colors.blueAccent, size: 20),
                                  const SizedBox(height: 4),
                                  Text(
                                    volumeText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
      ],
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
          "Achat de pass internet",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: _isLoadingPasses
            ? const Center(child: CircularProgressIndicator(color: orangeColor))
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Recipient Number Entry matching Orange style
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
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
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white30, size: 18),
                              onPressed: () {
                                _recipientController.clear();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Middle Categories scrollable area
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadPasses,
                        color: orangeColor,
                        child: ListView(
                          children: _categories.map((cat) {
                            return _buildCategoryAccordion(cat["title"]!, cat["period"]!);
                          }).toList(),
                        ),
                      ),
                    ),

                    // Bottom navigation/buy actions matching mock
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
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
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
