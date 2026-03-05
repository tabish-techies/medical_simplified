import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for Status Bar styling
import '../../data/auth_repository.dart';
import '../home/home_screen.dart';
import '../home/main_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.authRepository});
  final AuthRepository authRepository;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Logic / State (Unchanged) ---
  final Map<String, dynamic> _formData = {
    'firstName': '',
    'lastName': '',
    'gender': '',
    'email': '',
    'address1': '',
    'address2': '',
    'city': '',
    'state': '',
    'pincode': '',
    'dob': '',
  };

  bool _isSubmitting = false;
  late final TextEditingController _dobController;

  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan',
    'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh',
    'Uttarakhand', 'West Bengal', 'Delhi', 'Jammu and Kashmir', 'Ladakh'
  ];

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _dobController = TextEditingController();
  }

  @override
  void dispose() {
    _dobController.dispose();
    super.dispose();
  }

  // --- UI Helpers ---

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      floatingLabelStyle: const TextStyle(
          color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16),
      prefixIcon: Icon(icon, color: Colors.grey[500], size: 22),
      filled: true,
      fillColor: const Color(0xFFF8F9FA), // Very subtle grey fill
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      
      // Default Border (Grey)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      
      // Focused Border (CHANGED: Black instead of Blue)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black87, width: 1.5),
      ),
      
      // Error Border
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 0, 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String key,
    IconData icon, {
    TextInputType? type,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    TextEditingController? controller,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: type,
      cursorColor: Colors.black87, // CHANGED: Cursor color to black
      decoration: _inputDecoration(label, icon),
      validator: validator,
      onSaved: (value) => _formData[key] = value?.trim(),
      onTap: onTap,
    );
  }

  Widget _buildDobField() {
    return _buildTextField(
      'Date of Birth',
      'dob',
      Icons.calendar_month_outlined, // Updated Icon
      readOnly: true,
      controller: _dobController,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Select Date of Birth';
        final dob = DateTime.parse(value);
        final age = DateTime.now().year - dob.year;
        if (age < 18) return 'Must be at least 18 years old';
        return null;
      },
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.black87, // Calendar header color
                  onPrimary: Colors.white,
                  onSurface: Colors.black87,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(foregroundColor: Colors.black87),
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          final formatted =
              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
          setState(() {
            _dobController.text = formatted;
            _formData['dob'] = formatted;
          });
        }
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    try {
      _formData['isRegCompleted'] = 1;
      await widget.authRepository.registerUser(_formData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87, // Dark snackbar
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // ✅ Navigate to MainScreen to show BottomNavBar
          builder: (_) => MainScreen(authRepository: widget.authRepository),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Defines the consistent background color
    const Color scaffoldBgColor = Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        // Seamless AppBar styling
        backgroundColor: scaffoldBgColor,
        elevation: 0,
        scrolledUnderElevation: 0, // Prevents color change on scroll (Material 3)
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Dark icons for status bar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Let's start",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Complete your details to finish signing up.",
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),

                _buildSectionHeader("Personal Information"),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'First Name',
                        'firstName',
                        Icons.person_outline_rounded,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        'Last Name',
                        'lastName',
                        Icons.person_outline_rounded,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54), // Custom Arrow
                        decoration: _inputDecoration('Gender', Icons.wc_rounded),
                        dropdownColor: Colors.white, // Clean white menu
                        items: _genders
                            .map((g) =>
                                DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) => _formData['gender'] = val,
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _buildDobField(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  'Email Address',
                  'email',
                  Icons.alternate_email_rounded,
                  type: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter Email';
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$')
                        .hasMatch(v)) {
                      return 'Invalid Email';
                    }
                    return null;
                  },
                ),

                _buildSectionHeader("Location Details"),

                _buildTextField(
                  'Address Line 1',
                  'address1',
                  Icons.home_outlined,
                  validator: (v) =>
                      v != null && v.length >= 5 ? null : 'Enter valid address',
                ),
                const SizedBox(height: 16),

                _buildTextField(
                    'College Name', 'address2', Icons.apartment_rounded),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
                  dropdownColor: Colors.white,
                  decoration: _inputDecoration('State', Icons.map_outlined),
                  items: _indianStates
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => _formData['state'] = val,
                  validator: (v) => v == null ? 'Select State' : null,
                  menuMaxHeight: 300,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildTextField('City', 'city', Icons.location_city_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: _buildTextField(
                        'Pincode',
                        'pincode',
                        Icons.pin_drop_outlined,
                        type: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!RegExp(r'^\d{6}$').hasMatch(v)) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // --- Submit Button ---
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // CHANGED: Black button
                      foregroundColor: Colors.white,
                      elevation: 0, // Flat design
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Complete Registration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}