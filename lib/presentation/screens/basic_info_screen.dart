import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/profile/profile_bloc.dart';
import '../../logic/profile/profile_event.dart';
import '../../logic/profile/profile_state.dart';
import '../../core/router.dart';
import '../widgets/primary_button.dart';
import '../../core/ui/snackbar_utils.dart';

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'woman';
  String? _orientation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic info')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state.user != null) {
              Navigator.pushReplacementNamed(
                  context, CrushRoutes.idVerification);
            }
            final error = state.errorMessage;
            if (error != null && error.isNotEmpty) {
              showErrorSnackBar(context, error);
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: _gender,
                  items: const [
                    DropdownMenuItem(value: 'woman', child: Text('Woman')),
                    DropdownMenuItem(value: 'man', child: Text('Man')),
                    DropdownMenuItem(
                        value: 'nonbinary', child: Text('Non-binary')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _gender = value ?? 'woman';
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                      labelText: 'Sexual orientation (optional)'),
                  onChanged: (value) => _orientation = value,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Continue',
                  loading: state.isSaving,
                  onPressed: () {
                    if (state.isSaving) return;
                    final age = int.tryParse(_ageController.text) ?? 0;
                    context.read<ProfileBloc>().add(ProfileBasicInfoSubmitted(
                          name: _nameController.text.trim(),
                          age: age,
                          gender: _gender,
                          sexualOrientation: _orientation,
                        ));
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
