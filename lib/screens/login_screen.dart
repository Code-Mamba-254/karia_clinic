import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../services/auth_service.dart';
import '../services/doctor_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService();
  final DoctorService doctorService = DoctorService();

  final TextEditingController passwordController =
      TextEditingController();

  Doctor? selectedDoctor;

  List<Doctor> doctors = [];

  bool loadingDoctors = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    try {
      final loadedDoctors = await doctorService.getDoctors();

      if (!mounted) return;

      setState(() {
        doctors = loadedDoctors;
        loadingDoctors = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingDoctors = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to load doctors.\n$e",
          ),
        ),
      );
    }
  }

  Future<void> login() async {
    if (selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a doctor."),
        ),
      );
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your password."),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await authService.login(
        email: selectedDoctor!.email,
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Invalid password.",
          ),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KARIA MEDICAL CENTRE"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 380,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.local_hospital,
                    size: 90,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Doctor Login",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  if (loadingDoctors)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else
                    DropdownButtonFormField<Doctor>(
                      value: selectedDoctor,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Select Doctor",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: doctors
                          .map(
                            (doctor) => DropdownMenuItem<Doctor>(
                              value: doctor,
                              child: Text(
                                doctor.fullName,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (doctor) {
                        setState(() {
                          selectedDoctor = doctor;
                        });
                      },
                    ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}