import 'package:flutter/material.dart';

import '../enums/sex.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/primary_button.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';
import '../services/counter_service.dart';

import 'patient_lookup_screen.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState
    extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final residenceController = TextEditingController();
  final idNumberController = TextEditingController();
  final phoneController = TextEditingController();

  final PatientService _patientService = PatientService();
  final CounterService _counterService = CounterService();

  Sex selectedSex = Sex.male;

  bool isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    residenceController.dispose();
    idNumberController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // Generate clinic number
      final clinicNumber =
          await _counterService.generateClinicNumber();

      // Create patient
      final patient = Patient(
        id: '',
        clinicNumber: clinicNumber,
        name: nameController.text.trim(),
        ageInYears: int.parse(ageController.text.trim()),
        sex: selectedSex,
        residence: residenceController.text.trim(),
        idNumber: idNumberController.text.trim().isEmpty
            ? null
            : idNumberController.text.trim(),
        phoneNumber: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        createdAt: DateTime.now(),
      );

      // Save patient to Firestore
      await _patientService.savePatient(patient);

      if (!mounted) return;

      // Show success message briefly
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Patient Registered: $clinicNumber",
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Give the SnackBar a moment to appear,
      // then take the doctor back to Patient Lookup.
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PatientLookupScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error registering patient:\n$e",
          ),
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
      appBar: AppBar(
        title: const Text("Register Patient"),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Register New Patient",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // Patient Name
                AppTextField(
                  controller: nameController,
                  label: "Patient Name",
                  icon: Icons.person,
                ),

                const SizedBox(height: 20),

                // Age
                AppTextField(
                  controller: ageController,
                  label: "Age",
                  icon: Icons.cake,
                  keyboardType:
                      TextInputType.number,
                ),

                const SizedBox(height: 20),

                // Sex
                AppDropdown<Sex>(
                  value: selectedSex,
                  label: "Sex",
                  icon: Icons.people,
                  items: const [
                    DropdownMenuItem(
                      value: Sex.male,
                      child: Text("Male"),
                    ),
                    DropdownMenuItem(
                      value: Sex.female,
                      child: Text("Female"),
                    ),
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
                  keyboardType:
                      TextInputType.number,
                ),

                const SizedBox(height: 20),

                // Phone Number
                AppTextField(
                  controller: phoneController,
                  label: "Phone Number (Optional)",
                  icon: Icons.phone,
                  keyboardType:
                      TextInputType.phone,
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