import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/profile/profile_bloc.dart';
import '../../logic/profile/profile_event.dart';
import '../../logic/profile/profile_state.dart';
import '../../data/models/profile.dart';
import '../../data/models/preferences.dart';
import '../../core/ui/snackbar_utils.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _lastProfileId;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(ProfileLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (prev, curr) => prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null && error.isNotEmpty) {
          showErrorSnackBar(context, error);
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = state.profile;
        if (profile != null && profile.id != _lastProfileId) {
          _lastProfileId = profile.id;
          _nameController.text = profile.name;
          _bioController.text = profile.bio;
        }

        final saving = state.isSaving;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your profile'),
          ),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Display name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'About you'),
                      maxLines: 3,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: saving
                            ? null
                            : () {
                                final base = profile ??
                                    Profile(
                                      id: state.user?.id ?? 'TEMP',
                                      name: '',
                                      age: state.user?.profile?.age ?? 18,
                                      gender: state.user?.profile?.gender ?? '',
                                      sexualOrientation: state
                                          .user?.profile?.sexualOrientation,
                                      bio: '',
                                      photoUrls:
                                          state.user?.profile?.photoUrls ??
                                              const [],
                                      jobTitle: state.user?.profile?.jobTitle,
                                      company: state.user?.profile?.company,
                                      school: state.user?.profile?.school,
                                      interests:
                                          state.user?.profile?.interests ??
                                              const [],
                                      country: state.user?.profile?.country ??
                                          'Unknown',
                                      city: state.user?.profile?.city ??
                                          'Unknown',
                                      latitude: state.user?.profile?.latitude,
                                      longitude: state.user?.profile?.longitude,
                                      preferences:
                                          state.user?.profile?.preferences ??
                                              const DiscoveryPreferences(
                                                minAge: 18,
                                                maxAge: 45,
                                                maxDistanceKm: 50,
                                                showMeGenders: ['women', 'men'],
                                                showMyDistance: true,
                                                showMyAge: true,
                                                hideFromDiscovery: false,
                                                incognitoMode: false,
                                                country: 'Unknown',
                                                city: 'Unknown',
                                              ),
                                    );

                                final updated = base.copyWith(
                                  name: _nameController.text.trim(),
                                  bio: _bioController.text.trim(),
                                );

                                context.read<ProfileBloc>().add(
                                    ProfileSaveRequested(profile: updated));
                              },
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
              if (saving)
                Container(
                  color: const Color.fromARGB(31, 26, 1, 1),
                ),
            ],
          ),
        );
      },
    );
  }
}
