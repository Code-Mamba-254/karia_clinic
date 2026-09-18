import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/patient.dart';
import '../models/consultation.dart';

import '../services/consultation_service.dart';
import '../services/doctor_service.dart';

import '../widgets/patient_summary_card.dart';
import '../widgets/consultation_form_card.dart';
import '../widgets/consultation_card.dart';

import 'edit_patient_screen.dart';

typedef PatientEditor =
    Future<Patient?> Function(BuildContext context, Patient patient);

class ConsultationScreen extends StatefulWidget {
  final Patient patient;
  final PatientEditor? editPatient;
  final Stream<List<Consultation>> Function(String patientId)?
  consultationStream;

  const ConsultationScreen({
    super.key,
    required this.patient,
    this.editPatient,
    this.consultationStream,
  });

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final chiefComplaintController = TextEditingController();

  final temperatureController = TextEditingController();
  final pulseController = TextEditingController();
  final respiratoryController = TextEditingController();
  final bpController = TextEditingController();
  final oxygenController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  final investigationsController = TextEditingController();
  final diagnosisController = TextEditingController();
  final treatmentController = TextEditingController();
  final labController = TextEditingController();
  final remarksController = TextEditingController();

  final ConsultationService _consultationService = ConsultationService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DoctorService _doctorService = DoctorService();

  late Patient _patient;
  late Stream<List<Consultation>> _consultations;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _consultations =
        widget.consultationStream?.call(_patient.id) ??
        _consultationService.getPatientConsultations(_patient.id);
  }

  @override
  void dispose() {
    chiefComplaintController.dispose();

    temperatureController.dispose();
    pulseController.dispose();
    respiratoryController.dispose();
    bpController.dispose();
    oxygenController.dispose();
    weightController.dispose();
    heightController.dispose();

    investigationsController.dispose();
    diagnosisController.dispose();
    treatmentController.dispose();
    labController.dispose();
    remarksController.dispose();

    super.dispose();
  }

  Future<void> saveConsultation() async {
    if (_isSaving) return;

    final doctor = _auth.currentUser;
    if (doctor == null) return;

    final patientId = _patient.id;
    final createdAt = DateTime.now();
    final chiefComplaint = chiefComplaintController.text.trim();
    final temperature = temperatureController.text.trim();
    final pulseRate = pulseController.text.trim();
    final respiratoryRate = respiratoryController.text.trim();
    final bloodPressure = bpController.text.trim();
    final oxygenSaturation = oxygenController.text.trim();
    final weight = weightController.text.trim();
    final height = heightController.text.trim();
    final investigations = investigationsController.text.trim();
    final diagnosis = diagnosisController.text.trim();
    final treatment = treatmentController.text.trim();
    final labFeedback = labController.text.trim();
    final remarks = remarksController.text.trim();

    setState(() => _isSaving = true);
    try {
      var doctorName = doctor.displayName ?? '';
      var doctorEmail = doctor.email ?? '';
      try {
        final doctorProfile = await _doctorService.findDoctorForAuthUser(
          uid: doctor.uid,
          email: doctor.email,
        );
        doctorName = doctorProfile?.fullName ?? doctorName;
        doctorEmail = doctorProfile?.email ?? doctorEmail;
      } catch (error) {
        debugPrint('Doctor profile lookup failed: ${error.runtimeType}');
      }

      final consultation = Consultation(
        id: '',
        patientId: patientId,
        doctorId: doctor.uid,
        doctorEmail: doctorEmail,
        doctorName: doctorName,
        chiefComplaint: chiefComplaint,
        temperature: temperature,
        pulseRate: pulseRate,
        respiratoryRate: respiratoryRate,
        bloodPressure: bloodPressure,
        oxygenSaturation: oxygenSaturation,
        weight: weight,
        height: height,
        bmi: 0,
        investigations: investigations,
        diagnosis: diagnosis,
        treatment: treatment,
        labFeedback: labFeedback,
        remarks: remarks,
        createdAt: createdAt,
      );

      await _consultationService.saveConsultation(consultation);
      if (!mounted) return;

      _clearConsultationForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consultation Saved Successfully')),
      );
    } catch (error) {
      debugPrint('Consultation save failed: ${error.runtimeType}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save consultation. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearConsultationForm() {
    chiefComplaintController.clear();
    temperatureController.clear();
    pulseController.clear();
    respiratoryController.clear();
    bpController.clear();
    oxygenController.clear();
    weightController.clear();
    heightController.clear();
    investigationsController.clear();
    diagnosisController.clear();
    treatmentController.clear();
    labController.clear();
    remarksController.clear();
  }

  Future<void> _editPatient() async {
    final editor = widget.editPatient;
    final updatedPatient = editor == null
        ? await Navigator.push<Patient>(
            context,
            MaterialPageRoute(
              builder: (_) => EditPatientScreen(patient: _patient),
            ),
          )
        : await editor(context, _patient);

    if (!mounted || updatedPatient == null) return;
    setState(() => _patient = updatedPatient);
  }

  @override
  Widget build(BuildContext context) {
    final patient = _patient;

    return Scaffold(
      appBar: AppBar(title: const Text("Consultation")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            PatientSummaryCard(patient: patient, onEdit: _editPatient),

            const SizedBox(height: 24),

            const Text(
              "New Consultation",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),

            const SizedBox(height: 12),

            ConsultationFormCard(
              chiefComplaintController: chiefComplaintController,

              temperatureController: temperatureController,

              pulseController: pulseController,

              respiratoryController: respiratoryController,

              bpController: bpController,

              oxygenController: oxygenController,

              weightController: weightController,

              heightController: heightController,

              investigationsController: investigationsController,

              diagnosisController: diagnosisController,

              treatmentController: treatmentController,

              labController: labController,

              remarksController: remarksController,

              onSave: saveConsultation,
              isSaving: _isSaving,
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 20),

            const Text(
              "Consultation History",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),

            const SizedBox(height: 10),

            StreamBuilder<List<Consultation>>(
              stream: _consultations,

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final consultations = snapshot.data!;

                if (consultations.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text("No consultations yet."),
                    ),
                  );
                }

                return Column(
                  children: consultations
                      .map((c) => ConsultationCard(consultation: c))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
