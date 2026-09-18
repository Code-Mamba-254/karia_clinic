import 'package:flutter/material.dart';

import '../enums/sex.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';
import '../utils/age_formatter.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

typedef EditPatientDatePicker =
    Future<DateTime?> Function(BuildContext context, DateTime initialDate);

class EditPatientScreen extends StatefulWidget {
  final Patient patient;
  final DateTime Function()? now;
  final EditPatientDatePicker? pickDateOfBirth;
  final Future<void> Function(Patient patient)? updatePatient;

  const EditPatientScreen({
    super.key,
    required this.patient,
    this.now,
    this.pickDateOfBirth,
    this.updatePatient,
  });

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientService = PatientService();

  late final TextEditingController nameController;
  late final TextEditingController dateOfBirthController;
  late final TextEditingController residenceController;
  late final TextEditingController idNumberController;
  late final TextEditingController phoneController;

  late Sex selectedSex;
  DateTime? selectedDateOfBirth;
  bool isSaving = false;
  bool _formattedInitialDate = false;

  DateTime get _currentDate => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    final patient = widget.patient;
    nameController = TextEditingController(text: patient.name);
    dateOfBirthController = TextEditingController();
    residenceController = TextEditingController(text: patient.residence);
    idNumberController = TextEditingController(text: patient.idNumber ?? '');
    phoneController = TextEditingController(text: patient.phoneNumber ?? '');
    selectedSex = patient.sex;
    selectedDateOfBirth = patient.dateOfBirth;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_formattedInitialDate || selectedDateOfBirth == null) return;
    dateOfBirthController.text = MaterialLocalizations.of(
      context,
    ).formatCompactDate(selectedDateOfBirth!);
    _formattedInitialDate = true;
  }

  @override
  void dispose() {
    nameController.dispose();
    dateOfBirthController.dispose();
    residenceController.dispose();
    idNumberController.dispose();
    phoneController.dispose();
    super.dispose();
  }

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

  Future<void> _savePatient() async {
    if (isSaving || !_formKey.currentState!.validate()) return;

    final dateOfBirth = selectedDateOfBirth;
    final asOf = _currentDate;
    final idNumber = idNumberController.text.trim();
    final phoneNumber = phoneController.text.trim();
    final updatedPatient = widget.patient.copyWith(
      name: nameController.text.trim(),
      ageInYears: dateOfBirth == null
          ? widget.patient.ageInYears
          : calculateAgeInYears(dateOfBirth, asOf: asOf),
      dateOfBirth: dateOfBirth,
      sex: selectedSex,
      residence: residenceController.text.trim(),
      idNumber: idNumber.isEmpty ? null : idNumber,
      phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
    );

    setState(() => isSaving = true);
    try {
      await (widget.updatePatient?.call(updatedPatient) ??
          _patientService.updatePatient(updatedPatient));
      if (!mounted) return;
      Navigator.pop(context, updatedPatient);
    } catch (error) {
      debugPrint('Patient update failed: ${error.runtimeType}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update patient. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Patient Biodata')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: nameController,
                  label: 'Patient Name',
                  icon: Icons.person,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter patient name'
                      : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: dateOfBirthController,
                  label: 'Date of Birth',
                  icon: Icons.cake,
                  readOnly: true,
                  onTap: _pickDateOfBirth,
                  suffixIcon: Icons.calendar_month,
                ),
                if (selectedDateOfBirth != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Age: ${formatPatientAge(selectedDateOfBirth!, asOf: _currentDate)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                AppDropdown<Sex>(
                  value: selectedSex,
                  label: 'Sex',
                  icon: Icons.people,
                  items: const [
                    DropdownMenuItem(value: Sex.male, child: Text('Male')),
                    DropdownMenuItem(value: Sex.female, child: Text('Female')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedSex = value);
                  },
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: residenceController,
                  label: 'Residence',
                  icon: Icons.home,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: idNumberController,
                  label: 'National ID (Optional)',
                  icon: Icons.badge,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: phoneController,
                  label: 'Phone Number (Optional)',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 40),
                PrimaryButton(
                  text: 'UPDATE PATIENT',
                  loading: isSaving,
                  onPressed: _savePatient,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
