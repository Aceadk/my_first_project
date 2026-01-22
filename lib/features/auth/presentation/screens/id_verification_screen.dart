import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_event.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_state.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';

class IdVerificationScreen extends StatefulWidget {
  const IdVerificationScreen({super.key, this.fromSettings = false});

  /// Whether this screen is being shown from settings (not onboarding)
  final bool fromSettings;

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _frontIdImage;
  File? _backIdImage;
  bool _isUploading = false;
  bool _hasSubmitted = false;

  Future<void> _pickImage(bool isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          if (isFront) {
            _frontIdImage = File(image.path);
          } else {
            _backIdImage = File(image.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to pick image. Please try again.');
      }
    }
  }

  Future<void> _takePhoto(bool isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          if (isFront) {
            _frontIdImage = File(image.path);
          } else {
            _backIdImage = File(image.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to take photo. Please try again.');
      }
    }
  }

  void _showImageSourceDialog(bool isFront) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? DsColors.surfaceDark : DsColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? DsColors.borderDark : DsColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  isFront ? 'Upload Front of ID' : 'Upload Back of ID',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DsColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: DsColors.primary),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to capture ID'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto(isFront);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DsColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: DsColors.secondary),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(isFront);
                },
              ),
              DsGap.xl,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitVerification() async {
    if (_frontIdImage == null || _backIdImage == null) {
      showErrorSnackBar(context, 'Please upload both front and back of your ID');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // In a real app, this would upload the images to a server
      // For now, we'll simulate the upload and mark as pending
      context.read<ProfileBloc>().add(ProfileIdDocumentUploaded());

      setState(() {
        _hasSubmitted = true;
        _isUploading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        showErrorSnackBar(context, 'Failed to submit. Please try again.');
      }
    }
  }

  void _skipVerification() {
    if (widget.fromSettings) {
      Navigator.of(context).pop();
    } else {
      // Refresh auth state so router has updated user data
      context.read<AuthBloc>().add(AuthUserRefreshRequested());
      context.go(CrushRoutes.profileSetup);
    }
  }

  void _continueAfterSubmit() {
    if (widget.fromSettings) {
      Navigator.of(context).pop();
    } else {
      // Refresh auth state so router has updated user data
      context.read<AuthBloc>().add(AuthUserRefreshRequested());
      context.go(CrushRoutes.profileSetup);
    }
  }

  void _goBack() {
    if (widget.fromSettings) {
      Navigator.of(context).pop();
    } else {
      context.go(CrushRoutes.basicInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    DsColors.backgroundDark,
                    const Color(0xFF1A1A2E),
                    DsColors.backgroundDark,
                  ]
                : [
                    DsColors.backgroundLight,
                    const Color(0xFFF8F0FF),
                    DsColors.backgroundLight,
                  ],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<ProfileBloc, ProfileState>(
            listenWhen: (previous, current) =>
                previous.errorMessage != current.errorMessage,
            listener: (context, state) {
              final error = state.errorMessage;
              if (error != null && error.isNotEmpty) {
                showErrorSnackBar(context, error);
              }
            },
            builder: (context, state) {
              if (_hasSubmitted) {
                return _buildSubmittedView(context, isDark);
              }
              return _buildMainView(context, isDark, state);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainView(BuildContext context, bool isDark, ProfileState state) {
    return Column(
      children: [
        // Custom App Bar
        Padding(
          padding: DsEdgeInsets.horizontalXxl.copyWith(top: DsSpacing.md),
          child: Row(
            children: [
              GlassIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: _goBack,
                size: 40,
              ),
              const Spacer(),
              Text(
                'Verify Your ID',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 40),
            ],
          ),
        ),
        DsGap.lg,
        // Progress Indicator (only show in onboarding)
        if (!widget.fromSettings)
          Padding(
            padding: DsEdgeInsets.horizontalXxl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step 4 of 5',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DsColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Optional',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DsColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                DsGap.sm,
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.8,
                    minHeight: 6,
                    backgroundColor: isDark ? DsColors.surfaceDark : DsColors.skeletonLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(DsColors.primary),
                  ),
                ),
              ],
            ),
          ),
        if (!widget.fromSettings) DsGap.lg,
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: DsEdgeInsets.horizontalXxl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Benefits Section
                _buildBenefitsCard(context, isDark),
                DsGap.xl,
                // Upload Section
                Text(
                  'Upload Your Government ID',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
                  ),
                ),
                DsGap.sm,
                Text(
                  'We accept national ID cards, passports, or driver\'s licenses. Your information is encrypted and kept secure.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                  ),
                ),
                DsGap.lg,
                // Front ID Upload
                _buildIdUploadCard(
                  context,
                  isDark,
                  title: 'Front of ID',
                  subtitle: 'Photo side with your picture',
                  image: _frontIdImage,
                  onTap: () => _showImageSourceDialog(true),
                  onRemove: () => setState(() => _frontIdImage = null),
                ),
                DsGap.md,
                // Back ID Upload
                _buildIdUploadCard(
                  context,
                  isDark,
                  title: 'Back of ID',
                  subtitle: 'Back side of your document',
                  image: _backIdImage,
                  onTap: () => _showImageSourceDialog(false),
                  onRemove: () => setState(() => _backIdImage = null),
                ),
                DsGap.lg,
                // Info Note
                Container(
                  padding: DsEdgeInsets.allMd,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Colors.amber,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verification takes 24-48 hours',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Our team will review your documents and verify your identity. You\'ll receive a notification once verified.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                DsGap.xxl,
              ],
            ),
          ),
        ),
        // Bottom Buttons
        Container(
          padding: DsEdgeInsets.allXxl.copyWith(bottom: DsSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (isDark ? DsColors.backgroundDark : DsColors.backgroundLight)
                    .withValues(alpha: 0),
                isDark ? DsColors.backgroundDark : DsColors.backgroundLight,
              ],
            ),
          ),
          child: Column(
            children: [
              // Upload Button
              SizedBox(
                width: double.infinity,
                child: GlassPrimaryButton(
                  onPressed: (_frontIdImage != null && _backIdImage != null && !_isUploading)
                      ? _submitVerification
                      : null,
                  child: _isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_user_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _frontIdImage != null && _backIdImage != null
                                  ? 'Submit for Verification'
                                  : 'Upload ID to Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              DsGap.md,
              // Skip Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isUploading ? null : _skipVerification,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.fromSettings
                        ? 'Cancel'
                        : 'Skip for now, I\'ll verify later',
                    style: TextStyle(
                      color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmittedView(BuildContext context, bool isDark) {
    return Padding(
      padding: DsEdgeInsets.allXxl,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DsColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 80,
              color: DsColors.success,
            ),
          ),
          DsGap.xl,
          Text(
            'Documents Submitted!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
            ),
          ),
          DsGap.md,
          Text(
            'Your ID documents have been submitted for verification. Our team will review them within 24-48 hours.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
          DsGap.lg,
          Container(
            padding: DsEdgeInsets.allMd,
            decoration: BoxDecoration(
              color: isDark
                  ? DsColors.surfaceDark.withValues(alpha: 0.5)
                  : DsColors.inputFillLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildStatusRow(
                  context,
                  isDark,
                  icon: Icons.upload_file_rounded,
                  label: 'Documents uploaded',
                  status: 'Complete',
                  isComplete: true,
                ),
                const Divider(height: 24),
                _buildStatusRow(
                  context,
                  isDark,
                  icon: Icons.pending_rounded,
                  label: 'Under review',
                  status: 'In progress',
                  isComplete: false,
                ),
                const Divider(height: 24),
                _buildStatusRow(
                  context,
                  isDark,
                  icon: Icons.verified_rounded,
                  label: 'Verification badge',
                  status: 'Pending',
                  isComplete: false,
                ),
              ],
            ),
          ),
          DsGap.lg,
          Text(
            'You\'ll receive a notification once your ID is verified.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: GlassPrimaryButton(
              onPressed: _continueAfterSubmit,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.fromSettings
                        ? 'Done'
                        : 'Continue Setting Up Profile',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!widget.fromSettings) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ],
              ),
            ),
          ),
          DsGap.xl,
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required String status,
    required bool isComplete,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isComplete
                ? DsColors.success.withValues(alpha: 0.1)
                : DsColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isComplete ? DsColors.success : DsColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isComplete
                ? DsColors.success.withValues(alpha: 0.1)
                : Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isComplete ? DsColors.success : Colors.amber.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsCard(BuildContext context, bool isDark) {
    return Container(
      padding: DsEdgeInsets.allLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DsColors.primary.withValues(alpha: 0.1),
            DsColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DsColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DsColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: DsColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why Verify?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Unlock exclusive benefits',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          DsGap.lg,
          _buildBenefitRow(
            context,
            isDark,
            icon: Icons.favorite_rounded,
            title: '50% More Free Swipes',
            subtitle: 'Get extra daily swipes to find more matches',
          ),
          DsGap.md,
          _buildBenefitRow(
            context,
            isDark,
            icon: Icons.visibility_rounded,
            title: 'Higher Visibility',
            subtitle: 'Your profile is shown to more people',
          ),
          DsGap.md,
          _buildBenefitRow(
            context,
            isDark,
            icon: Icons.verified_user_rounded,
            title: 'Verification Badge',
            subtitle: 'Stand out with a trusted profile badge',
          ),
          DsGap.md,
          _buildBenefitRow(
            context,
            isDark,
            icon: Icons.new_releases_rounded,
            title: 'Early Access to Features',
            subtitle: 'Be first to try new app features',
          ),
          DsGap.md,
          _buildBenefitRow(
            context,
            isDark,
            icon: Icons.security_rounded,
            title: 'Secure Your Account',
            subtitle: 'Extra protection against impersonation',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: DsColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: DsColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdUploadCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required String subtitle,
    required File? image,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: image == null ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: DsEdgeInsets.allMd,
        decoration: BoxDecoration(
          color: image != null
              ? DsColors.success.withValues(alpha: 0.1)
              : (isDark
                  ? DsColors.surfaceDark.withValues(alpha: 0.5)
                  : DsColors.inputFillLight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: image != null
                ? DsColors.success
                : (isDark ? DsColors.borderDark : DsColors.borderLight),
            width: image != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (image != null)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      image,
                      width: 60,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: DsColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? DsColors.borderDark.withValues(alpha: 0.5)
                      : DsColors.borderLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? DsColors.borderDark : DsColors.borderLight,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                  size: 24,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? DsColors.textPrimaryDark
                              : DsColors.textPrimaryLight,
                        ),
                      ),
                      if (image != null) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: DsColors.success,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    image != null ? 'Tap to change' : subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            if (image == null)
              const Icon(
                Icons.upload_rounded,
                color: DsColors.primary,
              )
            else
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DsColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: DsColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
