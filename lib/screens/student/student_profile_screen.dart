import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onProfileUpdated;

  const StudentProfileScreen({
    super.key,
    required this.user,
    this.onProfileUpdated,
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _roomNumberController;
  late TextEditingController _phoneController;
  late String _selectedHostel;

  final AuthService _authService = AuthService();
  bool _isSaving = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _roomNumberController = TextEditingController(text: widget.user.roomNumber);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _selectedHostel = AppConstants.hostelBlocks.contains(widget.user.hostel)
        ? widget.user.hostel
        : AppConstants.hostelBlocks.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    try {
      await _authService.updateStudentProfile(
        uid: widget.user.uid,
        name: _nameController.text,
        hostel: _selectedHostel,
        roomNumber: _roomNumberController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );

      widget.onProfileUpdated?.call();

      if (mounted) {
        setState(() {
          _isSuccess = true;
          _statusMessage = 'Profile updated successfully!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSuccess = false;
          _statusMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejectedBg,
              foregroundColor: AppColors.statusRejected,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Hero
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              gradient: AppColors.avatarGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'S',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.user.name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user.studentId,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'STUDENT',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Status / Alert banner
                    if (_statusMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSuccess ? AppColors.statusApprovedBg : AppColors.statusRejectedBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _isSuccess ? AppColors.statusApproved : AppColors.statusRejected,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Student Details Panel
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.shadowSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STUDENT DETAILS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildKv('Email', widget.user.email),
                          _buildKv('Student ID', widget.user.studentId),
                          _buildKv('Role', 'Student'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Editable Information Panel
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.shadowSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EDIT PROFILE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildFieldLabel('Full Name'),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => Validators.validateRequired(v, 'Full Name'),
                          ),
                          const SizedBox(height: 12),

                          _buildFieldLabel('Hostel'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedHostel,
                                isExpanded: true,
                                items: AppConstants.hostelBlocks.map((hostel) {
                                  return DropdownMenuItem<String>(
                                    value: hostel,
                                    child: Text(
                                      hostel,
                                      style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedHostel = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildFieldLabel('Room Number'),
                          TextFormField(
                            controller: _roomNumberController,
                            validator: Validators.validateRoomNumber,
                          ),
                          const SizedBox(height: 12),

                          _buildFieldLabel('Phone Number'),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: _handleSave,
                      isLoading: _isSaving,
                      type: ButtonType.primary,
                      height: 48,
                    ),
                    const SizedBox(height: 12),

                    // Sign Out Button (danger variant)
                    CustomButton(
                      text: 'Log Out',
                      onPressed: _handleLogout,
                      type: ButtonType.danger,
                      height: 48,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildKv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
