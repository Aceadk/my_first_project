import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/presentation/widgets/onboarding_progress.dart';
import 'package:crushhour/presentation/widgets/onboarding_nav_buttons.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _dialCodeController = TextEditingController();
  bool _phoneTouched = false;
  bool _dialTouched = false;
  bool _submitted = false;
  _CountryCode _selectedCountry = _countries.firstWhere(
    (c) => c.name == 'United States',
    orElse: () => _countries.first,
  );

  @override
  void initState() {
    super.initState();
    _dialCodeController.text = _selectedCountry.dialCode;
    _phoneController.addListener(_onPhoneChanged);
    _dialCodeController.addListener(_onDialCodeChanged);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _dialCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up with phone')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BlocConsumer<AuthBloc, AuthState>(
                listenWhen: (previous, current) =>
                    previous.status != current.status ||
                    previous.errorMessage != current.errorMessage,
                listener: (context, state) {
                  if (state.status == AuthStatus.otpSent &&
                      state.phoneInProgress != null) {
                    showSuccessSnackBar(
                      context,
                      'Code sent. Check your messages.',
                    );
                    final phone = Uri.encodeComponent(state.phoneInProgress!);
                    context.push('${CrushRoutes.otp}?phone=$phone');
                  }
                  final error = state.errorMessage;
                  if (error != null && error.isNotEmpty) {
                    showErrorSnackBar(context, error);
                  }
                },
                builder: (context, state) {
                  final isLoading = state.isLoading;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      AbsorbPointer(
                        absorbing: isLoading,
                        child: Column(
                          children: [
                            const OnboardingProgress(
                              currentStep: 1,
                              caption: 'We’ll text you a code next',
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Your country',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<_CountryCode>(
                              initialValue: _selectedCountry,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.flag_outlined),
                              ),
                              items: _countries
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        '${c.flag} ${c.name} (${c.dialCode})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              selectedItemBuilder: (context) => _countries
                                  .map(
                                    (c) => Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${c.flag} ${c.name} (${c.dialCode})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCountry = value;
                                    _dialCodeController.text = value.dialCode;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _dialCodeController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.phone_iphone_outlined,
                                ),
                                labelText: 'Dial code',
                                helperText:
                                    'You can edit this if your country code differs.',
                                errorText: _dialErrorText(),
                              ),
                              onTap: () => _markDialTouched(),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                prefixText: _dialCodeController.text.isEmpty
                                    ? null
                                    : '${_dialCodeController.text} ',
                                labelText: 'Phone number',
                                helperText:
                                    'SMS rates may apply. We only use this to secure your account.',
                                errorText: _phoneErrorText(),
                              ),
                              onTap: () => _markPhoneTouched(),
                              onChanged: (_) => _markPhoneTouched(),
                            ),
                            const SizedBox(height: 24),
                            OnboardingNavButtons(
                              onBack: isLoading
                                  ? null
                                  : () {
                                      if (Navigator.canPop(context)) {
                                        Navigator.pop(context);
                                      } else {
                                        context.go(CrushRoutes.authGateway);
                                      }
                                    },
                              onNext: isLoading || !_canSubmitPhone()
                                  ? null
                                  : () {
                                      setState(() {
                                        _submitted = true;
                                        _phoneTouched = true;
                                        _dialTouched = true;
                                      });
                                      final dialError = _dialErrorText();
                                      final phoneError = _phoneErrorText();
                                      if (dialError != null ||
                                          phoneError != null) {
                                        showErrorSnackBar(
                                          context,
                                          dialError ?? phoneError!,
                                        );
                                        return;
                                      }
                                      final normalized =
                                          '${_normalizedDialCode()}${_digitsOnly(_phoneController.text)}';
                                      context.read<AuthBloc>().add(
                                        AuthPhoneSubmitted(normalized),
                                      );
                                    },
                              nextLoading: isLoading,
                            ),
                            Semantics(
                              button: true,
                              label: 'Use email instead',
                              child: GlassSmallButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context.go(CrushRoutes.emailAuth),
                                child: const Text('Use email instead'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLoading)
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: DsColors.overlayLight,
                            ),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPhoneChanged() => setState(() {});

  void _onDialCodeChanged() => setState(() {
    _dialTouched = true;
  });

  void _markPhoneTouched() {
    if (!_phoneTouched) {
      setState(() {
        _phoneTouched = true;
      });
    }
  }

  void _markDialTouched() {
    if (!_dialTouched) {
      setState(() {
        _dialTouched = true;
      });
    }
  }

  String? _dialErrorText() {
    if (!_dialTouched && !_submitted) return null;
    final raw = _dialCodeController.text.trim();
    if (raw.isEmpty) {
      return 'Enter your country code';
    }
    if (!_looksLikeDialCode(raw)) {
      return 'Include + and numbers only';
    }
    return null;
  }

  String? _phoneErrorText() {
    if (!_phoneTouched && !_submitted) return null;
    final digits = _digitsOnly(_phoneController.text);
    if (digits.isEmpty) {
      return 'Enter your phone number';
    }
    if (digits.length < 6) {
      return 'Add at least 6 digits';
    }
    return null;
  }

  String? _normalizedDialCode() {
    final raw = _dialCodeController.text.trim();
    if (raw.isEmpty) return null;
    final digits = _digitsOnly(raw);
    if (digits.isEmpty) return null;
    return '+$digits';
  }

  bool _canSubmitPhone() {
    final normalizedDial = _normalizedDialCode();
    final phoneDigits = _digitsOnly(_phoneController.text);
    return normalizedDial != null &&
        _looksLikeDialCode(_dialCodeController.text) &&
        phoneDigits.length >= 6;
  }

  bool _looksLikeDialCode(String input) {
    final trimmed = input.trim();
    return trimmed.startsWith('+') && _digitsOnly(trimmed).isNotEmpty;
  }
}

String _digitsOnly(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');

class _CountryCode {
  const _CountryCode({
    required this.name,
    required this.dialCode,
    required this.flag,
  });

  final String name;
  final String dialCode;
  final String flag;
}

// Full country list sorted alphabetically
const _countries = <_CountryCode>[
  _CountryCode(name: 'Afghanistan', dialCode: '+93', flag: '🇦🇫'),
  _CountryCode(name: 'Albania', dialCode: '+355', flag: '🇦🇱'),
  _CountryCode(name: 'Algeria', dialCode: '+213', flag: '🇩🇿'),
  _CountryCode(name: 'American Samoa', dialCode: '+1684', flag: '🇦🇸'),
  _CountryCode(name: 'Andorra', dialCode: '+376', flag: '🇦🇩'),
  _CountryCode(name: 'Angola', dialCode: '+244', flag: '🇦🇴'),
  _CountryCode(name: 'Anguilla', dialCode: '+1264', flag: '🇦🇮'),
  _CountryCode(name: 'Antarctica', dialCode: '+672', flag: '🇦🇶'),
  _CountryCode(name: 'Antigua and Barbuda', dialCode: '+1268', flag: '🇦🇬'),
  _CountryCode(name: 'Argentina', dialCode: '+54', flag: '🇦🇷'),
  _CountryCode(name: 'Armenia', dialCode: '+374', flag: '🇦🇲'),
  _CountryCode(name: 'Aruba', dialCode: '+297', flag: '🇦🇼'),
  _CountryCode(name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
  _CountryCode(name: 'Austria', dialCode: '+43', flag: '🇦🇹'),
  _CountryCode(name: 'Azerbaijan', dialCode: '+994', flag: '🇦🇿'),
  _CountryCode(name: 'Bahamas', dialCode: '+1242', flag: '🇧🇸'),
  _CountryCode(name: 'Bahrain', dialCode: '+973', flag: '🇧🇭'),
  _CountryCode(name: 'Bangladesh', dialCode: '+880', flag: '🇧🇩'),
  _CountryCode(name: 'Barbados', dialCode: '+1246', flag: '🇧🇧'),
  _CountryCode(name: 'Belarus', dialCode: '+375', flag: '🇧🇾'),
  _CountryCode(name: 'Belgium', dialCode: '+32', flag: '🇧🇪'),
  _CountryCode(name: 'Belize', dialCode: '+501', flag: '🇧🇿'),
  _CountryCode(name: 'Benin', dialCode: '+229', flag: '🇧🇯'),
  _CountryCode(name: 'Bermuda', dialCode: '+1441', flag: '🇧🇲'),
  _CountryCode(name: 'Bhutan', dialCode: '+975', flag: '🇧🇹'),
  _CountryCode(name: 'Bolivia', dialCode: '+591', flag: '🇧🇴'),
  _CountryCode(name: 'Bosnia and Herzegovina', dialCode: '+387', flag: '🇧🇦'),
  _CountryCode(name: 'Botswana', dialCode: '+267', flag: '🇧🇼'),
  _CountryCode(name: 'Brazil', dialCode: '+55', flag: '🇧🇷'),
  _CountryCode(
    name: 'British Indian Ocean Territory',
    dialCode: '+246',
    flag: '🇮🇴',
  ),
  _CountryCode(name: 'British Virgin Islands', dialCode: '+1284', flag: '🇻🇬'),
  _CountryCode(name: 'Brunei', dialCode: '+673', flag: '🇧🇳'),
  _CountryCode(name: 'Bulgaria', dialCode: '+359', flag: '🇧🇬'),
  _CountryCode(name: 'Burkina Faso', dialCode: '+226', flag: '🇧🇫'),
  _CountryCode(name: 'Burundi', dialCode: '+257', flag: '🇧🇮'),
  _CountryCode(name: 'Cambodia', dialCode: '+855', flag: '🇰🇭'),
  _CountryCode(name: 'Cameroon', dialCode: '+237', flag: '🇨🇲'),
  _CountryCode(name: 'Canada', dialCode: '+1', flag: '🇨🇦'),
  _CountryCode(name: 'Cape Verde', dialCode: '+238', flag: '🇨🇻'),
  _CountryCode(name: 'Cayman Islands', dialCode: '+1345', flag: '🇰🇾'),
  _CountryCode(
    name: 'Central African Republic',
    dialCode: '+236',
    flag: '🇨🇫',
  ),
  _CountryCode(name: 'Chad', dialCode: '+235', flag: '🇹🇩'),
  _CountryCode(name: 'Chile', dialCode: '+56', flag: '🇨🇱'),
  _CountryCode(name: 'China', dialCode: '+86', flag: '🇨🇳'),
  _CountryCode(name: 'Christmas Island', dialCode: '+61', flag: '🇨🇽'),
  _CountryCode(name: 'Cocos (Keeling) Islands', dialCode: '+61', flag: '🇨🇨'),
  _CountryCode(name: 'Colombia', dialCode: '+57', flag: '🇨🇴'),
  _CountryCode(name: 'Comoros', dialCode: '+269', flag: '🇰🇲'),
  _CountryCode(name: 'Cook Islands', dialCode: '+682', flag: '🇨🇰'),
  _CountryCode(name: 'Costa Rica', dialCode: '+506', flag: '🇨🇷'),
  _CountryCode(name: "Cote d'Ivoire", dialCode: '+225', flag: '🇨🇮'),
  _CountryCode(name: 'Croatia', dialCode: '+385', flag: '🇭🇷'),
  _CountryCode(name: 'Cuba', dialCode: '+53', flag: '🇨🇺'),
  _CountryCode(name: 'Curacao', dialCode: '+599', flag: '🇨🇼'),
  _CountryCode(name: 'Cyprus', dialCode: '+357', flag: '🇨🇾'),
  _CountryCode(name: 'Czech Republic', dialCode: '+420', flag: '🇨🇿'),
  _CountryCode(
    name: 'Democratic Republic of the Congo',
    dialCode: '+243',
    flag: '🇨🇩',
  ),
  _CountryCode(name: 'Denmark', dialCode: '+45', flag: '🇩🇰'),
  _CountryCode(name: 'Djibouti', dialCode: '+253', flag: '🇩🇯'),
  _CountryCode(name: 'Dominica', dialCode: '+1767', flag: '🇩🇲'),
  _CountryCode(name: 'Dominican Republic', dialCode: '+1809', flag: '🇩🇴'),
  _CountryCode(name: 'Ecuador', dialCode: '+593', flag: '🇪🇨'),
  _CountryCode(name: 'Egypt', dialCode: '+20', flag: '🇪🇬'),
  _CountryCode(name: 'El Salvador', dialCode: '+503', flag: '🇸🇻'),
  _CountryCode(name: 'Equatorial Guinea', dialCode: '+240', flag: '🇬🇶'),
  _CountryCode(name: 'Eritrea', dialCode: '+291', flag: '🇪🇷'),
  _CountryCode(name: 'Estonia', dialCode: '+372', flag: '🇪🇪'),
  _CountryCode(name: 'Ethiopia', dialCode: '+251', flag: '🇪🇹'),
  _CountryCode(name: 'Falkland Islands', dialCode: '+500', flag: '🇫🇰'),
  _CountryCode(name: 'Faroe Islands', dialCode: '+298', flag: '🇫🇴'),
  _CountryCode(name: 'Fiji', dialCode: '+679', flag: '🇫🇯'),
  _CountryCode(name: 'Finland', dialCode: '+358', flag: '🇫🇮'),
  _CountryCode(name: 'France', dialCode: '+33', flag: '🇫🇷'),
  _CountryCode(name: 'French Guiana', dialCode: '+594', flag: '🇬🇫'),
  _CountryCode(name: 'French Polynesia', dialCode: '+689', flag: '🇵🇫'),
  _CountryCode(name: 'Gabon', dialCode: '+241', flag: '🇬🇦'),
  _CountryCode(name: 'Gambia', dialCode: '+220', flag: '🇬🇲'),
  _CountryCode(name: 'Georgia', dialCode: '+995', flag: '🇬🇪'),
  _CountryCode(name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
  _CountryCode(name: 'Ghana', dialCode: '+233', flag: '🇬🇭'),
  _CountryCode(name: 'Gibraltar', dialCode: '+350', flag: '🇬🇮'),
  _CountryCode(name: 'Greece', dialCode: '+30', flag: '🇬🇷'),
  _CountryCode(name: 'Greenland', dialCode: '+299', flag: '🇬🇱'),
  _CountryCode(name: 'Grenada', dialCode: '+1473', flag: '🇬🇩'),
  _CountryCode(name: 'Guadeloupe', dialCode: '+590', flag: '🇬🇵'),
  _CountryCode(name: 'Guam', dialCode: '+1671', flag: '🇬🇺'),
  _CountryCode(name: 'Guatemala', dialCode: '+502', flag: '🇬🇹'),
  _CountryCode(name: 'Guernsey', dialCode: '+44', flag: '🇬🇬'),
  _CountryCode(name: 'Guinea', dialCode: '+224', flag: '🇬🇳'),
  _CountryCode(name: 'Guinea-Bissau', dialCode: '+245', flag: '🇬🇼'),
  _CountryCode(name: 'Guyana', dialCode: '+592', flag: '🇬🇾'),
  _CountryCode(name: 'Haiti', dialCode: '+509', flag: '🇭🇹'),
  _CountryCode(name: 'Honduras', dialCode: '+504', flag: '🇭🇳'),
  _CountryCode(name: 'Hong Kong', dialCode: '+852', flag: '🇭🇰'),
  _CountryCode(name: 'Hungary', dialCode: '+36', flag: '🇭🇺'),
  _CountryCode(name: 'Iceland', dialCode: '+354', flag: '🇮🇸'),
  _CountryCode(name: 'India', dialCode: '+91', flag: '🇮🇳'),
  _CountryCode(name: 'Indonesia', dialCode: '+62', flag: '🇮🇩'),
  _CountryCode(name: 'Iran', dialCode: '+98', flag: '🇮🇷'),
  _CountryCode(name: 'Iraq', dialCode: '+964', flag: '🇮🇶'),
  _CountryCode(name: 'Ireland', dialCode: '+353', flag: '🇮🇪'),
  _CountryCode(name: 'Isle of Man', dialCode: '+44', flag: '🇮🇲'),
  _CountryCode(name: 'Israel', dialCode: '+972', flag: '🇮🇱'),
  _CountryCode(name: 'Italy', dialCode: '+39', flag: '🇮🇹'),
  _CountryCode(name: 'Jamaica', dialCode: '+1876', flag: '🇯🇲'),
  _CountryCode(name: 'Japan', dialCode: '+81', flag: '🇯🇵'),
  _CountryCode(name: 'Jersey', dialCode: '+44', flag: '🇯🇪'),
  _CountryCode(name: 'Jordan', dialCode: '+962', flag: '🇯🇴'),
  _CountryCode(name: 'Kazakhstan', dialCode: '+7', flag: '🇰🇿'),
  _CountryCode(name: 'Kenya', dialCode: '+254', flag: '🇰🇪'),
  _CountryCode(name: 'Kiribati', dialCode: '+686', flag: '🇰🇮'),
  _CountryCode(name: 'Kuwait', dialCode: '+965', flag: '🇰🇼'),
  _CountryCode(name: 'Kyrgyzstan', dialCode: '+996', flag: '🇰🇬'),
  _CountryCode(name: 'Laos', dialCode: '+856', flag: '🇱🇦'),
  _CountryCode(name: 'Latvia', dialCode: '+371', flag: '🇱🇻'),
  _CountryCode(name: 'Lebanon', dialCode: '+961', flag: '🇱🇧'),
  _CountryCode(name: 'Lesotho', dialCode: '+266', flag: '🇱🇸'),
  _CountryCode(name: 'Liberia', dialCode: '+231', flag: '🇱🇷'),
  _CountryCode(name: 'Libya', dialCode: '+218', flag: '🇱🇾'),
  _CountryCode(name: 'Liechtenstein', dialCode: '+423', flag: '🇱🇮'),
  _CountryCode(name: 'Lithuania', dialCode: '+370', flag: '🇱🇹'),
  _CountryCode(name: 'Luxembourg', dialCode: '+352', flag: '🇱🇺'),
  _CountryCode(name: 'Macao', dialCode: '+853', flag: '🇲🇴'),
  _CountryCode(name: 'Madagascar', dialCode: '+261', flag: '🇲🇬'),
  _CountryCode(name: 'Malawi', dialCode: '+265', flag: '🇲🇼'),
  _CountryCode(name: 'Malaysia', dialCode: '+60', flag: '🇲🇾'),
  _CountryCode(name: 'Maldives', dialCode: '+960', flag: '🇲🇻'),
  _CountryCode(name: 'Mali', dialCode: '+223', flag: '🇲🇱'),
  _CountryCode(name: 'Malta', dialCode: '+356', flag: '🇲🇹'),
  _CountryCode(name: 'Marshall Islands', dialCode: '+692', flag: '🇲🇭'),
  _CountryCode(name: 'Martinique', dialCode: '+596', flag: '🇲🇶'),
  _CountryCode(name: 'Mauritania', dialCode: '+222', flag: '🇲🇷'),
  _CountryCode(name: 'Mauritius', dialCode: '+230', flag: '🇲🇺'),
  _CountryCode(name: 'Mayotte', dialCode: '+262', flag: '🇾🇹'),
  _CountryCode(name: 'Mexico', dialCode: '+52', flag: '🇲🇽'),
  _CountryCode(name: 'Micronesia', dialCode: '+691', flag: '🇫🇲'),
  _CountryCode(name: 'Moldova', dialCode: '+373', flag: '🇲🇩'),
  _CountryCode(name: 'Monaco', dialCode: '+377', flag: '🇲🇨'),
  _CountryCode(name: 'Mongolia', dialCode: '+976', flag: '🇲🇳'),
  _CountryCode(name: 'Montenegro', dialCode: '+382', flag: '🇲🇪'),
  _CountryCode(name: 'Montserrat', dialCode: '+1664', flag: '🇲🇸'),
  _CountryCode(name: 'Morocco', dialCode: '+212', flag: '🇲🇦'),
  _CountryCode(name: 'Mozambique', dialCode: '+258', flag: '🇲🇿'),
  _CountryCode(name: 'Myanmar', dialCode: '+95', flag: '🇲🇲'),
  _CountryCode(name: 'Namibia', dialCode: '+264', flag: '🇳🇦'),
  _CountryCode(name: 'Nauru', dialCode: '+674', flag: '🇳🇷'),
  _CountryCode(name: 'Nepal', dialCode: '+977', flag: '🇳🇵'),
  _CountryCode(name: 'Netherlands', dialCode: '+31', flag: '🇳🇱'),
  _CountryCode(name: 'New Caledonia', dialCode: '+687', flag: '🇳🇨'),
  _CountryCode(name: 'New Zealand', dialCode: '+64', flag: '🇳🇿'),
  _CountryCode(name: 'Nicaragua', dialCode: '+505', flag: '🇳🇮'),
  _CountryCode(name: 'Niger', dialCode: '+227', flag: '🇳🇪'),
  _CountryCode(name: 'Nigeria', dialCode: '+234', flag: '🇳🇬'),
  _CountryCode(name: 'Niue', dialCode: '+683', flag: '🇳🇺'),
  _CountryCode(name: 'Norfolk Island', dialCode: '+672', flag: '🇳🇫'),
  _CountryCode(name: 'North Korea', dialCode: '+850', flag: '🇰🇵'),
  _CountryCode(name: 'North Macedonia', dialCode: '+389', flag: '🇲🇰'),
  _CountryCode(
    name: 'Northern Mariana Islands',
    dialCode: '+1670',
    flag: '🇲🇵',
  ),
  _CountryCode(name: 'Norway', dialCode: '+47', flag: '🇳🇴'),
  _CountryCode(name: 'Oman', dialCode: '+968', flag: '🇴🇲'),
  _CountryCode(name: 'Pakistan', dialCode: '+92', flag: '🇵🇰'),
  _CountryCode(name: 'Palau', dialCode: '+680', flag: '🇵🇼'),
  _CountryCode(name: 'Palestine', dialCode: '+970', flag: '🇵🇸'),
  _CountryCode(name: 'Panama', dialCode: '+507', flag: '🇵🇦'),
  _CountryCode(name: 'Papua New Guinea', dialCode: '+675', flag: '🇵🇬'),
  _CountryCode(name: 'Paraguay', dialCode: '+595', flag: '🇵🇾'),
  _CountryCode(name: 'Peru', dialCode: '+51', flag: '🇵🇪'),
  _CountryCode(name: 'Philippines', dialCode: '+63', flag: '🇵🇭'),
  _CountryCode(name: 'Poland', dialCode: '+48', flag: '🇵🇱'),
  _CountryCode(name: 'Portugal', dialCode: '+351', flag: '🇵🇹'),
  _CountryCode(name: 'Puerto Rico', dialCode: '+1787', flag: '🇵🇷'),
  _CountryCode(name: 'Qatar', dialCode: '+974', flag: '🇶🇦'),
  _CountryCode(name: 'Republic of the Congo', dialCode: '+242', flag: '🇨🇬'),
  _CountryCode(name: 'Reunion', dialCode: '+262', flag: '🇷🇪'),
  _CountryCode(name: 'Romania', dialCode: '+40', flag: '🇷🇴'),
  _CountryCode(name: 'Russia', dialCode: '+7', flag: '🇷🇺'),
  _CountryCode(name: 'Rwanda', dialCode: '+250', flag: '🇷🇼'),
  _CountryCode(name: 'Saint Barthelemy', dialCode: '+590', flag: '🇧🇱'),
  _CountryCode(name: 'Saint Helena', dialCode: '+290', flag: '🇸🇭'),
  _CountryCode(name: 'Saint Kitts and Nevis', dialCode: '+1869', flag: '🇰🇳'),
  _CountryCode(name: 'Saint Lucia', dialCode: '+1758', flag: '🇱🇨'),
  _CountryCode(name: 'Saint Martin', dialCode: '+590', flag: '🇲🇫'),
  _CountryCode(
    name: 'Saint Pierre and Miquelon',
    dialCode: '+508',
    flag: '🇵🇲',
  ),
  _CountryCode(
    name: 'Saint Vincent and the Grenadines',
    dialCode: '+1784',
    flag: '🇻🇨',
  ),
  _CountryCode(name: 'Samoa', dialCode: '+685', flag: '🇼🇸'),
  _CountryCode(name: 'San Marino', dialCode: '+378', flag: '🇸🇲'),
  _CountryCode(name: 'Sao Tome and Principe', dialCode: '+239', flag: '🇸🇹'),
  _CountryCode(name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦'),
  _CountryCode(name: 'Senegal', dialCode: '+221', flag: '🇸🇳'),
  _CountryCode(name: 'Serbia', dialCode: '+381', flag: '🇷🇸'),
  _CountryCode(name: 'Seychelles', dialCode: '+248', flag: '🇸🇨'),
  _CountryCode(name: 'Sierra Leone', dialCode: '+232', flag: '🇸🇱'),
  _CountryCode(name: 'Singapore', dialCode: '+65', flag: '🇸🇬'),
  _CountryCode(name: 'Sint Maarten', dialCode: '+1721', flag: '🇸🇽'),
  _CountryCode(name: 'Slovakia', dialCode: '+421', flag: '🇸🇰'),
  _CountryCode(name: 'Slovenia', dialCode: '+386', flag: '🇸🇮'),
  _CountryCode(name: 'Solomon Islands', dialCode: '+677', flag: '🇸🇧'),
  _CountryCode(name: 'Somalia', dialCode: '+252', flag: '🇸🇴'),
  _CountryCode(name: 'South Africa', dialCode: '+27', flag: '🇿🇦'),
  _CountryCode(name: 'South Korea', dialCode: '+82', flag: '🇰🇷'),
  _CountryCode(name: 'South Sudan', dialCode: '+211', flag: '🇸🇸'),
  _CountryCode(name: 'Spain', dialCode: '+34', flag: '🇪🇸'),
  _CountryCode(name: 'Sri Lanka', dialCode: '+94', flag: '🇱🇰'),
  _CountryCode(name: 'Sudan', dialCode: '+249', flag: '🇸🇩'),
  _CountryCode(name: 'Suriname', dialCode: '+597', flag: '🇸🇷'),
  _CountryCode(name: 'Sweden', dialCode: '+46', flag: '🇸🇪'),
  _CountryCode(name: 'Switzerland', dialCode: '+41', flag: '🇨🇭'),
  _CountryCode(name: 'Syria', dialCode: '+963', flag: '🇸🇾'),
  _CountryCode(name: 'Taiwan', dialCode: '+886', flag: '🇹🇼'),
  _CountryCode(name: 'Tajikistan', dialCode: '+992', flag: '🇹🇯'),
  _CountryCode(name: 'Tanzania', dialCode: '+255', flag: '🇹🇿'),
  _CountryCode(name: 'Thailand', dialCode: '+66', flag: '🇹🇭'),
  _CountryCode(name: 'Timor-Leste', dialCode: '+670', flag: '🇹🇱'),
  _CountryCode(name: 'Togo', dialCode: '+228', flag: '🇹🇬'),
  _CountryCode(name: 'Tokelau', dialCode: '+690', flag: '🇹🇰'),
  _CountryCode(name: 'Tonga', dialCode: '+676', flag: '🇹🇴'),
  _CountryCode(name: 'Trinidad and Tobago', dialCode: '+1868', flag: '🇹🇹'),
  _CountryCode(name: 'Tunisia', dialCode: '+216', flag: '🇹🇳'),
  _CountryCode(name: 'Turkey', dialCode: '+90', flag: '🇹🇷'),
  _CountryCode(name: 'Turkmenistan', dialCode: '+993', flag: '🇹🇲'),
  _CountryCode(
    name: 'Turks and Caicos Islands',
    dialCode: '+1649',
    flag: '🇹🇨',
  ),
  _CountryCode(name: 'Tuvalu', dialCode: '+688', flag: '🇹🇻'),
  _CountryCode(name: 'Uganda', dialCode: '+256', flag: '🇺🇬'),
  _CountryCode(name: 'Ukraine', dialCode: '+380', flag: '🇺🇦'),
  _CountryCode(name: 'United Arab Emirates', dialCode: '+971', flag: '🇦🇪'),
  _CountryCode(name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
  _CountryCode(name: 'United States', dialCode: '+1', flag: '🇺🇸'),
  _CountryCode(name: 'Uruguay', dialCode: '+598', flag: '🇺🇾'),
  _CountryCode(name: 'Uzbekistan', dialCode: '+998', flag: '🇺🇿'),
  _CountryCode(name: 'Vanuatu', dialCode: '+678', flag: '🇻🇺'),
  _CountryCode(name: 'Vatican City', dialCode: '+379', flag: '🇻🇦'),
  _CountryCode(name: 'Venezuela', dialCode: '+58', flag: '🇻🇪'),
  _CountryCode(name: 'Vietnam', dialCode: '+84', flag: '🇻🇳'),
  _CountryCode(name: 'Wallis and Futuna', dialCode: '+681', flag: '🇼🇫'),
  _CountryCode(name: 'Yemen', dialCode: '+967', flag: '🇾🇪'),
  _CountryCode(name: 'Zambia', dialCode: '+260', flag: '🇿🇲'),
  _CountryCode(name: 'Zimbabwe', dialCode: '+263', flag: '🇿🇼'),
];
