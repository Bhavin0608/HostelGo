import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import 'request_details_screen.dart';

enum OutingType { sameDay, multiDay }

class ApplyOutingScreen extends StatefulWidget {
  final UserModel student;

  const ApplyOutingScreen({
    super.key,
    required this.student,
  });

  @override
  State<ApplyOutingScreen> createState() => _ApplyOutingScreenState();
}

class _ApplyOutingScreenState extends State<ApplyOutingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _remarksController = TextEditingController();
  final _customPurposeController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

  OutingType _outingType = OutingType.sameDay;
  DateTime _leavingDate = DateTime.now();
  DateTime _returnDate = DateTime.now();
  TimeOfDay _leavingTimeOfDay = const TimeOfDay(hour: 17, minute: 0); // 05:00 PM
  TimeOfDay _returnTimeOfDay = const TimeOfDay(hour: 21, minute: 0); // 09:00 PM
  String _selectedPurpose = AppConstants.commonPurposes.first;
  bool _isCustomPurpose = false;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _destinationController.dispose();
    _remarksController.dispose();
    _customPurposeController.dispose();
    super.dispose();
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _selectLeavingDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _leavingDate.isBefore(today) ? today : _leavingDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)), // Support long vacations, festivals, semester leaves
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _leavingDate = picked;
        if (_outingType == OutingType.sameDay || _returnDate.isBefore(_leavingDate)) {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _selectReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate.isBefore(_leavingDate) ? _leavingDate : _returnDate,
      firstDate: _leavingDate,
      lastDate: _leavingDate.add(const Duration(days: 365)), // Support long vacation/festival leaves
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _returnDate = picked;
      });
    }
  }

  Future<void> _selectLeavingTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _leavingTimeOfDay,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _leavingTimeOfDay = picked;
      });
    }
  }

  Future<void> _selectReturnTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _returnTimeOfDay,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _returnTimeOfDay = picked;
      });
    }
  }

  int _calculateDays() {
    final start = DateTime(_leavingDate.year, _leavingDate.month, _leavingDate.day);
    final end = DateTime(_returnDate.year, _returnDate.month, _returnDate.day);
    final diff = end.difference(start).inDays;
    return diff <= 0 ? 1 : diff + 1;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final targetReturnDate = _outingType == OutingType.sameDay ? _leavingDate : _returnDate;
    final leavingDateTime = _combineDateAndTime(_leavingDate, _leavingTimeOfDay);
    final returnDateTime = _combineDateAndTime(targetReturnDate, _returnTimeOfDay);

    // Validate Chronological Times across dates
    final timeError = Validators.validateTimes(
      leavingTime: leavingDateTime,
      returnTime: returnDateTime,
    );

    if (timeError != null) {
      setState(() {
        _errorMessage = timeError;
      });
      return;
    }

    final finalPurpose = _isCustomPurpose
        ? _customPurposeController.text.trim()
        : _selectedPurpose;

    if (finalPurpose.isEmpty) {
      setState(() {
        _errorMessage = 'Please specify the purpose of the outing.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final request = await _firestoreService.createOutingRequest(
        studentUid: widget.student.uid,
        studentName: widget.student.name,
        studentId: widget.student.studentId,
        hostel: widget.student.hostel,
        roomNumber: widget.student.roomNumber,
        outingDate: _leavingDate,
        leavingTime: _leavingDateTime(leavingDateTime),
        expectedReturnTime: returnDateTime,
        destination: _destinationController.text.trim(),
        purpose: finalPurpose,
        remarks: _remarksController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outing request submitted successfully! Waiting for warden review.'),
          backgroundColor: AppColors.statusApproved,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RequestDetailsScreen(
            requestId: request.id,
            isWarden: false,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  DateTime _leavingDateTime(DateTime val) => val;

  @override
  Widget build(BuildContext context) {
    final formatTime = DateFormat('hh:mm a');
    final refDate = DateTime(2026, 1, 1);
    final formattedLeaving = formatTime.format(
      DateTime(refDate.year, refDate.month, refDate.day, _leavingTimeOfDay.hour, _leavingTimeOfDay.minute),
    );
    final formattedReturn = formatTime.format(
      DateTime(refDate.year, refDate.month, refDate.day, _returnTimeOfDay.hour, _returnTimeOfDay.minute),
    );

    final isMulti = _outingType == OutingType.multiDay;
    final totalDays = _calculateDays();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with back button
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.textPrimary),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'New Outing Request',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Text(
                        "Apply for daily outings, festival holidays, or extended home leaves.",
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Error Alert
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statusRejectedBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.statusRejected.withAlpha((0.2 * 255).round()),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.statusRejected, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.statusRejected,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Outing Type Toggle (Local vs Multi-Day Leave)
                    _buildFormSectionTitle('OUTING TYPE'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _outingType = OutingType.sameDay;
                                  _returnDate = _leavingDate;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _outingType == OutingType.sameDay ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'Local Outing (Same Day)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: _outingType == OutingType.sameDay ? Colors.white : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _outingType = OutingType.multiDay;
                                  if (_returnDate.isBefore(_leavingDate) || _returnDate == _leavingDate) {
                                    _returnDate = _leavingDate.add(const Duration(days: 3));
                                  }
                                  if (_selectedPurpose == 'Shopping') {
                                    _selectedPurpose = 'Home Visit';
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _outingType == OutingType.multiDay ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'Festival / Home Leave',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: _outingType == OutingType.multiDay ? Colors.white : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Outing Details Section
                    _buildFormSectionTitle('OUTING SCHEDULE & DURATION'),
                    const SizedBox(height: 8),

                    // Multi-day Leave Duration Badge
                    if (isMulti) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.beach_access_rounded, size: 18, color: AppColors.primaryDark),
                                SizedBox(width: 8),
                                Text(
                                  'Total Leave Duration',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$totalDays ${totalDays == 1 ? 'Day' : 'Days'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Outing Leaving Date & Time
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(isMulti ? 'Departure Date' : 'Outing Date'),
                              InkWell(
                                onTap: _selectLeavingDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border, width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM yyyy').format(_leavingDate),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Out Time'),
                              InkWell(
                                onTap: _selectLeavingTime,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border, width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formattedLeaving,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const Icon(Icons.access_time_rounded, size: 15, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Expected Return Date & Time
                    Row(
                      children: [
                        if (isMulti) ...[
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Return Date'),
                                InkWell(
                                  onTap: _selectReturnDate,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border, width: 1.5),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('dd MMM yyyy').format(_returnDate),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.textMuted),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          flex: isMulti ? 2 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(isMulti ? 'In Time' : 'Expected Return Time'),
                              InkWell(
                                onTap: _selectReturnTime,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border, width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formattedReturn,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const Icon(Icons.access_time_rounded, size: 15, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Warden Review & Discretion Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.shield_outlined, size: 18, color: AppColors.primaryDark),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Warden Discretion: All outing schedules, late returns, and multi-day festival/home leaves are reviewed and decided by the Warden.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryDark,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Location & Purpose Section
                    _buildFormSectionTitle('DESTINATION & PURPOSE'),
                    const SizedBox(height: 8),

                    // Destination
                    _buildFieldLabel(isMulti ? 'Home / Travel Destination' : 'Destination / Location'),
                    TextFormField(
                      controller: _destinationController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) => Validators.validateRequired(v, 'Destination'),
                      decoration: InputDecoration(
                        hintText: isMulti ? 'e.g. Home (Surat / Mumbai / Rajkot)' : 'e.g. City Centre Mall / Station',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Purpose
                    _buildFieldLabel('Purpose'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPurpose,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                          items: AppConstants.commonPurposes.map((p) {
                            return DropdownMenuItem<String>(
                              value: p,
                              child: Text(
                                p,
                                style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPurpose = val;
                                _isCustomPurpose = (val == 'Personal / Other');
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    if (_isCustomPurpose) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _customPurposeController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Specify reason (e.g. Diwali Vacation / Family Wedding / Project)...',
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Remarks
                    _buildFieldLabel(isMulti ? 'Guardian Contact & Travel Notes (Optional)' : 'Remarks / Special Notes (Optional)'),
                    TextFormField(
                      controller: _remarksController,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: isMulti
                            ? 'e.g. Attending sister wedding / Traveling with parents (Contact: +91 98765 43210)'
                            : 'Provide any important reason or work details for the warden...',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Personal Information Section
                    _buildFormSectionTitle('STUDENT INFORMATION'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildReadOnlyField('Student', widget.student.name)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildReadOnlyField('ID', widget.student.studentId)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildReadOnlyField('Hostel', widget.student.hostel)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildReadOnlyField('Room', widget.student.roomNumber)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    CustomButton(
                      text: isMulti ? 'Submit Leave Request' : 'Submit Outing Request',
                      onPressed: _handleSubmit,
                      isLoading: _isSubmitting,
                      type: ButtonType.primary,
                      height: 48,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.textMuted,
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

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
