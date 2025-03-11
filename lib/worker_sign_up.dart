import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'terms_and_conditions.dart';
import 'dart:io';
import 'phone_ver.dart';
import 'package:flutter/gestures.dart';
import 'l10n/app_localizations.dart';

class WorkerSignUpScreen extends StatefulWidget {
  const WorkerSignUpScreen({Key? key}) : super(key: key);

  @override
  State<WorkerSignUpScreen> createState() => _WorkerSignUpScreenState();
}

class _WorkerSignUpScreenState extends State<WorkerSignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();

  String? selectedService;
  String? selectedEducationLevel;
  String? selectedSubject;
  String? selectedGender;
  String? selectedSubscription;
  File? profileImage;
  File? idCard;
  File? policeRecord;
  bool isLoading = false;
  bool acceptedTerms = false;
  bool _submitted = false; // Tracks whether the user attempted to sign up

  @override
  void initState() {
    super.initState();
    // Prefill phone field with +213
    phoneController.text = '+213 ';
  }

  // Getters to retrieve raw keys from the JSON maps.
  List<String> get genders {
    final dynamic value = AppLocalizations.of(context).localizedStrings['genders'];
    if (value is Map) {
      return value.keys.map((e) => e.toString()).toList();
    }
    return [];
  }

  List<String> get services {
    final dynamic value = AppLocalizations.of(context).localizedStrings['services'];
    if (value is Map) {
      return value.keys.map((e) => e.toString()).toList();
    }
    return [];
  }

  List<String> get availableSubscriptions {
    final dynamic value = AppLocalizations.of(context).localizedStrings['subscriptions'];
    if (value is Map) {
      return value.keys.map((e) => e.toString()).toList();
    }
    return [];
  }

  Map<String, List<String>> get educationLevels {
    final dynamic rawMap = AppLocalizations.of(context).localizedStrings['education_levels'];
    if (rawMap is Map) {
      return rawMap.map((key, value) {
        if (value is List) {
          return MapEntry(key.toString(), value.map((e) => e.toString()).toList());
        }
        return MapEntry(key.toString(), <String>[]);
      });
    }
    return {};
  }

  List<String> get educationLevelKeys {
    return educationLevels.keys.toList();
  }

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
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadURL = await taskSnapshot.ref.getDownloadURL();
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
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('image_selected_success')),
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).translate('image_selection_error')}: $e'),
        ),
      );
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    // Mark that the user has attempted to submit
    setState(() {
      _submitted = true;
    });

    if (!formKey.currentState!.validate()) return;
    if (selectedSubscription == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('select_subscription'))),
      );
      return;
    }
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('accept_terms'))),
      );
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('password_mismatch'))),
      );
      return;
    }
    // Check if all images are uploaded
    if (profileImage == null || idCard == null || policeRecord == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('upload_all_images'))),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email, password: password);
      final String userId = userCredential.user!.uid;

      final String? profileImageUrl = await uploadImageToFirebase(profileImage, 'profile_images', userId);
      final String? idCardUrl = await uploadImageToFirebase(idCard, 'id_cards', userId);
      final String? policeRecordUrl = await uploadImageToFirebase(policeRecord, 'police_records', userId);

      // Store the education level and subject keys
      final String? educationLevelKey = selectedEducationLevel;
      final String? subjectKey = selectedSubject;

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'role': 'worker',
        'email': email,
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'birthday': birthdayController.text.trim(),
        'gender': selectedGender,
        'service': selectedService,
        'educationLevel': educationLevelKey,
        'subject': subjectKey,
        'profileImageUrl': profileImageUrl ?? '',
        'idCardUrl': idCardUrl ?? '',
        'policeRecordUrl': policeRecordUrl ?? '',
        'subscription': selectedSubscription,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('signup_success'))),
      );

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
      String errorMessage = AppLocalizations.of(context).translate('generic_error');
      if (e.code == 'weak-password') {
        errorMessage = AppLocalizations.of(context).translate('weak_password_error');
      } else if (e.code == 'email-already-in-use') {
        errorMessage = AppLocalizations.of(context).translate('email_in_use_error');
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).translate('error')}: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime lastAllowedDate = DateTime(today.year - 20, today.month, today.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: lastAllowedDate,
      firstDate: DateTime(1900),
      lastDate: lastAllowedDate,
    );

    if (picked != null) {
      setState(() {
        birthdayController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.red[800]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('full_name')),
                  prefixIcon: const Icon(Icons.person, color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('email')),
                  prefixIcon: const Icon(Icons.email, color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('phone_number')),
                  prefixIcon: const Icon(Icons.phone, color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: birthdayController,
                readOnly: true,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('birthday')),
                  prefixIcon: const Icon(Icons.cake, color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('gender')),
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                ),
                items: genders.map((genderKey) {
                  return DropdownMenuItem(
                    value: genderKey,
                    child: Text(AppLocalizations.of(context).translate('genders.$genderKey')),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedGender = value),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedService,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('service')),
                  prefixIcon: const Icon(Icons.work, color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                ),
                items: services.map((serviceKey) {
                  return DropdownMenuItem(
                    value: serviceKey,
                    child: Text(AppLocalizations.of(context).translate('services.$serviceKey')),
                  );
                }).toList(),
                onChanged: (value) => setState(() {
                  selectedService = value;
                  selectedEducationLevel = null;
                  selectedSubject = null;
                }),
              ),
              const SizedBox(height: 20),
              if (selectedService == 'tutoring') ...[
                DropdownButtonFormField<String>(
                  value: selectedEducationLevel,
                  decoration: InputDecoration(
                    label: Text(AppLocalizations.of(context).translate('education_level')),
                    prefixIcon: const Icon(Icons.school, color: Colors.red),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: "Primary",
                      child: Text(AppLocalizations.of(context).translate('primaire')),
                    ),
                    DropdownMenuItem<String>(
                      value: "Middle School",
                      child: Text(AppLocalizations.of(context).translate('cem')),
                    ),
                    DropdownMenuItem<String>(
                      value: "High School",
                      child: Text(AppLocalizations.of(context).translate('lycee')),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedEducationLevel = newValue;
                      selectedSubject = null; // Reset subjects when level changes
                    });
                  },
                ),
                const SizedBox(height: 20),
                if (selectedEducationLevel != null && educationLevels.containsKey(selectedEducationLevel)) ...[
                  DropdownButtonFormField<String>(
                    value: selectedSubject,
                    decoration: InputDecoration(
                      label: Text(AppLocalizations.of(context).translate('subject')),
                      prefixIcon: const Icon(Icons.book, color: Colors.red),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red.shade800),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red.shade800),
                      ),
                    ),
                    items: educationLevels[selectedEducationLevel]!
                        .map((subjectKey) => DropdownMenuItem(
                      value: subjectKey,
                      child: Text(AppLocalizations.of(context).translate('subjectss.$subjectKey')),
                    ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedSubject = value),
                  ),
                ],
              ],
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedSubscription,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('subscription')),
                  prefixIcon: const Icon(Icons.subscriptions, color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                ),
                items: availableSubscriptions.map((subKey) {
                  return DropdownMenuItem(
                    value: subKey,
                    child: Text(AppLocalizations.of(context).translate('subscriptions.$subKey')),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedSubscription = value),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('password')),
                  prefixIcon: const Icon(Icons.lock, color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('confirm_password')),
                  prefixIcon: const Icon(Icons.lock, color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                ),
              ),
              const SizedBox(height: 20),
              // Profile image upload
              ElevatedButton(
                onPressed: () => pickImage(ImageSource.gallery, (file) {
                  profileImage = file;
                }),
                child: Text(AppLocalizations.of(context).translate('upload_profile_image')),
              ),
              if (profileImage != null)
                Text(AppLocalizations.of(context).translate('profile_image_selected'),
                    style: const TextStyle(color: Colors.green))
              else if (_submitted)
                const Text("Profile image is required.", style: TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              // ID card upload
              ElevatedButton(
                onPressed: () => pickImage(ImageSource.gallery, (file) {
                  idCard = file;
                }),
                child: Text(AppLocalizations.of(context).translate('upload_id_card')),
              ),
              if (idCard != null)
                Text(AppLocalizations.of(context).translate('id_card_selected'),
                    style: const TextStyle(color: Colors.green))
              else if (_submitted)
                const Text("ID card is required.", style: TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              // Police record upload
              ElevatedButton(
                onPressed: () => pickImage(ImageSource.gallery, (file) {
                  policeRecord = file;
                }),
                child: Text(AppLocalizations.of(context).translate('upload_police_record')),
              ),
              if (policeRecord != null)
                Text(AppLocalizations.of(context).translate('police_record_selected'),
                    style: const TextStyle(color: Colors.green))
              else if (_submitted)
                const Text("Police record is required.", style: TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: acceptedTerms,
                    activeColor: Colors.red.shade800,
                    onChanged: (value) => setState(() => acceptedTerms = value ?? false),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: AppLocalizations.of(context).translate('accept_terms'),
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: AppLocalizations.of(context).translate('terms_conditions'),
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsAndConditionsScreen(),
                                ),
                              ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: size.width,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading
                      ? null
                      : () => signUp(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  ),
                  child: Text(
                    AppLocalizations.of(context).translate('signup'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
