import 'package:flutter/material.dart';

import '../enums/sex.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/primary_button.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';
import '../services/counter_service.dart';
import '../utils/age_formatter.dart';

import 'consultation_screen.dart';

typedef DateOfBirthPicker =
    Future<DateTime?> Function(BuildContext context, DateTime initialDate);
typedef PatientDetailsBuilder =
    Widget Function(BuildContext context, Patient patient);

class PatientRegistrationScreen extends StatefulWidget {
  final DateTime Function()? now;
  final DateOfBirthPicker? pickDateOfBirth;
  final Future<String> Function()? generateClinicNumber;
  final Future<Patient> Function(Patient patient)? savePatient;
  final PatientDetailsBuilder? patientDetailsBuilder;

  const PatientRegistrationScreen({
    super.key,
    this.now,
    this.pickDateOfBirth,
    this.generateClinicNumber,
    this.savePatient,
    this.patientDetailsBuilder,
  });

  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final residenceController = TextEditingController();
  final idNumberController = TextEditingController();
  final phoneController = TextEditingController();

  final PatientService _patientService = PatientService();
  final CounterService _counterService = CounterService();

  Sex selectedSex = Sex.male;
  DateTime? selectedDateOfBirth;

  bool isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    dateOfBirthController.dispose();
    residenceController.dispose();
    idNumberController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  DateTime get _currentDate => widget.now?.call() ?? DateTime.now();

  Future<void> _pickDateOfBirth() async {
    final now = _currentDate;
    final initialDate = selectedDateOfBirth ?? now;
    final picker = widget.pickDateOfBirth;
    final pickedDate = picker == null
        ? await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(1900),
            lastDate: now,
          )
        : await picker(context, initialDate);

    if (pickedDate == null || pickedDate.isAfter(now) || !mounted) return;

    final formattedDate = MaterialLocalizations.of(
      context,
    ).formatCompactDate(pickedDate);
    setState(() {
      selectedDateOfBirth = pickedDate;
      dateOfBirthController.text = formattedDate;
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    nameController.clear();
    dateOfBirthController.clear();
    residenceController.clear();
    idNumberController.clear();
    phoneController.clear();
    selectedDateOfBirth = null;
    selectedSex = Sex.male;
  }

  Future<void> _savePatient() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dateOfBirth = selectedDateOfBirth;
    if (dateOfBirth == null) {
      return;
    }

    final submittedAt = _currentDate;
    final name = nameController.text.trim();
    final sex = selectedSex;
    final residence = residenceController.text.trim();
    final idNumber = idNumberController.text.trim();
    final phoneNumber = phoneController.text.trim();

    setState(() {
      isSaving = true;
    });

    try {
      // Generate clinic number
      final clinicNumber =
          await (widget.generateClinicNumber?.call() ??
              _counterService.generateClinicNumber());

      // Create patient
      final patient = Patient(
        id: '',
        clinicNumber: clinicNumber,
        name: name,
        ageInYears: calculateAgeInYears(dateOfBirth, asOf: submittedAt),
        dateOfBirth: dateOfBirth,
        sex: sex,
        residence: residence,
        idNumber: idNumber.isEmpty ? null : idNumber,
        phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
        createdAt: submittedAt,
      );

      // Save patient to Firestore and keep the generated document ID.
      final persistedPatient =
          await (widget.savePatient?.call(patient) ??
              _patientService.savePatient(patient));

      if (!mounted) return;

      setState(_resetForm);

      // Show success message briefly
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Patient Registered: $clinicNumber"),
          duration: const Duration(seconds: 2),
        ),
      );

      // Give the SnackBar a moment to appear before opening patient details.
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      final detailsBuilder = widget.patientDetailsBuilder;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => detailsBuilder == null
              ? ConsultationScreen(patient: persistedPatient)
              : detailsBuilder(context, persistedPatient),
        ),
      );
    } catch (error) {
      debugPrint('Patient registration failed: ${error.runtimeType}');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to register patient. Please try again."),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Patient")),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Register New Patient",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 30),

                // Patient Name
                AppTextField(
                  controller: nameController,
                  label: "Patient Name",
                  icon: Icons.person,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? "Enter patient name"
                      : null,
                ),

                const SizedBox(height: 20),

                // Date of birth
                AppTextField(
                  controller: dateOfBirthController,
                  label: "Date of Birth",
                  icon: Icons.cake,
                  readOnly: true,
                  onTap: _pickDateOfBirth,
                  suffixIcon: Icons.calendar_month,
                  validator: (_) => selectedDateOfBirth == null
                      ? "Select the patient's date of birth"
                      : null,
                ),

                if (selectedDateOfBirth != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Age: ${formatPatientAge(selectedDateOfBirth!, asOf: _currentDate)}",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Sex
                AppDropdown<Sex>(
                  value: selectedSex,
                  label: "Sex",
                  icon: Icons.people,
                  items: const [
                    DropdownMenuItem(value: Sex.male, child: Text("Male")),
                    DropdownMenuItem(value: Sex.female, child: Text("Female")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedSex = value!;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // Residence
                AppTextField(
                  controller: residenceController,
                  label: "Residence",
                  icon: Icons.home,
                ),

                const SizedBox(height: 20),

                // National ID
                AppTextField(
                  controller: idNumberController,
                  label: "National ID (Optional)",
                  icon: Icons.badge,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 20),

                // Phone Number
                AppTextField(
                  controller: phoneController,
                  label: "Phone Number (Optional)",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 40),

                // Save
                PrimaryButton(
                  text: "SAVE PATIENT",
                  loading: isSaving,
                  onPressed: _savePatient,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
