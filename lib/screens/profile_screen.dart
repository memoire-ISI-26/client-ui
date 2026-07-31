import 'package:flutter/material.dart';
import 'package:client_ui/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String myNumber;
  final String token;

  const ProfileScreen({
    super.key,
    required this.myNumber,
    required this.token,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoadingUser = true;
  bool _isSubmitting = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _firstName;
  String? _lastName;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetails() async {
    setState(() {
      _isLoadingUser = true;
      _errorMessage = null;
    });

    try {
      final accountData = await ApiService.getAccount(widget.myNumber, widget.token);
      setState(() {
        _firstName = accountData["firstName"] as String?;
        _lastName = accountData["lastName"] as String?;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Impossible de récupérer les informations du profil : ${e.toString().replaceAll('Exception:', '').trim()}";
      });
    } finally {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ApiService.updatePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        token: widget.token,
      );

      setState(() {
        _successMessage = "Mot de passe modifié avec succès !";
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
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
          "Mon Profil",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: _isLoadingUser
            ? const Center(child: CircularProgressIndicator(color: orangeColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User header info
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: orangeColor.withOpacity(0.15),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 48,
                                color: orangeColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "${_firstName ?? ''} ${_lastName ?? ''}".trim(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.myNumber,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        "Informations du compte",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12, width: 0.8),
                        ),
                        child: Column(
                          children: [
                            _buildProfileDetailRow("Prénom", _firstName ?? "N/A"),
                            const Divider(color: Colors.white12, height: 24),
                            _buildProfileDetailRow("Nom", _lastName ?? "N/A"),
                            const Divider(color: Colors.white12, height: 24),
                            _buildProfileDetailRow("Téléphone", widget.myNumber),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        "Modifier mon mot de passe",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Old Password
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: TextFormField(
                          controller: _oldPasswordController,
                          obscureText: _obscureOld,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Ancien mot de passe",
                            hintStyle: const TextStyle(color: Colors.white24),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureOld ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white30,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureOld = !_obscureOld),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Veuillez saisir votre ancien mot de passe.";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // New Password
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Nouveau mot de passe",
                            hintStyle: const TextStyle(color: Colors.white24),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNew ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white30,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureNew = !_obscureNew),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Veuillez saisir un nouveau mot de passe.";
                            }
                            if (value.length < 6) {
                              return "Le mot de passe doit contenir au moins 6 caractères.";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Confirmer le nouveau mot de passe",
                            hintStyle: const TextStyle(color: Colors.white24),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white30,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Veuillez confirmer votre nouveau mot de passe.";
                            }
                            if (value != _newPasswordController.text) {
                              return "Les mots de passe ne correspondent pas.";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_successMessage != null) ...[
                        Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],

                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _updatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "Enregistrer",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
