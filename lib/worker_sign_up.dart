import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'phone_ver.dart';

class WorkerSignUpScreen extends StatefulWidget {
  const WorkerSignUpScreen({super.key});

  @override
  State<WorkerSignUpScreen> createState() => _WorkerSignUpScreenState();
}

class _WorkerSignUpScreenState extends State<WorkerSignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  String? selectedService;
  String? selectedEducationLevel;
  String? selectedSubject;
  String? selectedGender;
  File? profileImage;
  File? idCard;
  File? policeRecord;
  bool isLoading = false;

  final List<String> services = [
    'Jardinage',
    'Peinture',
    'Apprentissage',
    'Nettoyage',
    'Plomberie',
    'Electricite'
  ];

  final Map<String, List<String>> educationLevels = {
    'Primaire': ['Math', 'Arabe', 'Physique', 'Science', 'Francais'],
    'CEM': ['Math', 'Arabe', 'Physique', 'Science', 'Francais', 'Anglais', 'Philo'],
    'Lycee': ['Math', 'Arabe', 'Physique', 'Science', 'Francais', 'Anglais', 'Philo', 'Comptabilite']
  };

  final formKey = GlobalKey<FormState>();

  Future<String?> uploadImageToFirebase(File? imageFile, String folder, String userId) async {
    if (imageFile == null) return null;

    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child('$folder/$userId/$fileName');

      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for the upload to complete and get the URL
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadURL = await taskSnapshot.ref.getDownloadURL();
      print('Upload successful: $downloadURL');
      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> pickImage(ImageSource source, void Function(File) setImage) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          setImage(File(pickedFile.path));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image selected successfully')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    if (!formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Create user account
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final String userId = userCredential.user!.uid;

      // Upload images
      final String? profileImageUrl = await uploadImageToFirebase(
          profileImage, 'profile_images', userId);
      final String? idCardUrl = await uploadImageToFirebase(
          idCard, 'id_cards', userId);
      final String? policeRecordUrl = await uploadImageToFirebase(
          policeRecord, 'police_records', userId);

      // Save user data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'role': 'worker',
        'email': email,
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'age': ageController.text.trim(),
        'gender': selectedGender,
        'service': selectedService,
        'educationLevel': selectedEducationLevel,
        'subject': selectedSubject,
        'profileImageUrl': profileImageUrl ?? '',
        'idCardUrl': idCardUrl ?? '',
        'policeRecordUrl': policeRecordUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up successful!')),
      );

      // Navigate to phone verification
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PhoneVerificationScreen(
            phoneNumber: phoneController.text.trim(),
            userId: userId,
            isClient: false,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for this email.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up as Worker'),
        backgroundColor: Colors.orange.shade400,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter your email' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                    validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter your phone number' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: 'Age'),
                    validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter your age' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: ['Male', 'Female']
                        .map((gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedGender = value),
                    validator: (value) =>
                    value == null ? 'Please select your gender' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedService,
                    decoration: const InputDecoration(labelText: 'Service'),
                    items: services
                        .map((service) => DropdownMenuItem(
                      value: service,
                      child: Text(service),
                    ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedService = value),
                    validator: (value) =>
                    value == null ? 'Please select a service' : null,
                  ),
                  const SizedBox(height: 16),

                  if (selectedService == 'Apprentissage') ...[
                    DropdownButtonFormField<String>(
                      value: selectedEducationLevel,
                      decoration: const InputDecoration(labelText: 'Education Level'),
                      items: educationLevels.keys
                          .map((level) => DropdownMenuItem(
                        value: level,
                        child: Text(level),
                      ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedEducationLevel = value),
                      validator: (value) =>
                      value == null ? 'Please select your education level' : null,
                    ),
                    const SizedBox(height: 16),

                    if (selectedEducationLevel != null)
                      DropdownButtonFormField<String>(
                        value: selectedSubject,
                        decoration: const InputDecoration(labelText: 'Subject'),
                        items: educationLevels[selectedEducationLevel]!
                            .map((subject) => DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        ))
                            .toList(),
                        onChanged: (value) => setState(() => selectedSubject = value),
                        validator: (value) =>
                        value == null ? 'Please select a subject' : null,
                      ),
                  ],
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a password' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                    validator: (value) =>
                    value?.isEmpty ?? true ? 'Please confirm your password' : null,
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () => pickImage(
                      ImageSource.gallery,
                          (file) => profileImage = file,
                    ),
                    child: const Text('Upload Profile Picture'),
                  ),
                  if (profileImage != null)
                    const Text('Profile picture selected', style: TextStyle(color: Colors.green)),
                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: () => pickImage(
                      ImageSource.gallery,
                          (file) => idCard = file,
                    ),
                    child: const Text('Upload ID Card'),
                  ),
                  if (idCard != null)
                    const Text('ID Card selected', style: TextStyle(color: Colors.green)),
                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: () => pickImage(
                      ImageSource.gallery,
                          (file) => policeRecord = file,
                    ),
                    child: const Text('Upload Police Record'),
                  ),
                  if (policeRecord != null)
                    const Text('Police Record selected', style: TextStyle(color: Colors.green)),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => signUp(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    ),
                    child: Text(isLoading ? 'Please wait...' : 'Sign Up'),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}