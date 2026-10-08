import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _submitPhone() {
    if (_phoneController.text.trim().length >= 10) {
      HapticFeedback.lightImpact();
      context.read<AuthBloc>().add(AuthSignInRequested(_phoneController.text.trim()));
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرجاء إدخال رقم هاتف صحيح').tr(),
          backgroundColor: AppTheme.expense,
        ),
      );
    }
  }

  void _submitOtp(String phone) {
    if (_otpController.text.trim().length == 6) {
      HapticFeedback.mediumImpact();
      context.read<AuthBloc>().add(
            AuthVerifyOTPRequested(phone, _otpController.text.trim()),
          );
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('رمز التحقق يتكون من 6 أرقام').tr(),
          backgroundColor: AppTheme.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              HapticFeedback.heavyImpact();
              context.go('/onboarding');
            } else if (state is AuthError) {
              HapticFeedback.vibrate();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.expense,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final isOtp = state is AuthOTPVerificationPending;
            final phone = isOtp ? state.phone : _phoneController.text;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Icon & Badge
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          size: 38,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Header Text
                    Text(
                      isOtp ? 'auth.otp_title'.tr() : 'auth.login_title'.tr(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.text,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOtp
                          ? '${'auth.otp_subtitle'.tr()} $phone'
                          : 'auth.login_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                    ),
                    const SizedBox(height: 36),

                    // Input Form
                    if (!isOtp) ...[
                      // Phone Number Input Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _phoneController,
                              autofocus: true,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(
                                fontSize: 18,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                              autofillHints: const [AutofillHints.telephoneNumber],
                              decoration: InputDecoration(
                                labelText: 'auth.phone_label'.tr(),
                                hintText: 'auth.phone_hint'.tr(),
                                prefixIcon: const Icon(
                                  Icons.phone_iphone_rounded,
                                  color: AppTheme.primary,
                                ),
                              ),
                              onFieldSubmitted: (_) => _submitPhone(),
                            ),
                            const SizedBox(height: 20),

                            // Submit Button
                            ElevatedButton(
                              onPressed: isLoading ? null : _submitPhone,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.background,
                                      ),
                                    )
                                  : Text('auth.send_code'.tr()),
                            ),
                            const SizedBox(height: 28),

                            // Trust Note Microcopy
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 16,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'auth.trust_note'.tr(),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textMuted,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // OTP Verification Input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _otpController,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            style: const TextStyle(
                              fontSize: 28,
                              letterSpacing: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            autofillHints: const [AutofillHints.oneTimeCode],
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '● ● ● ● ● ●',
                              labelText: 'auth.otp_hint'.tr(),
                            ),
                            onFieldSubmitted: (_) => _submitOtp(phone),
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: isLoading ? null : () => _submitOtp(phone),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.background,
                                    ),
                                  )
                                : Text('auth.verify'.tr()),
                          ),
                          const SizedBox(height: 16),

                          // Isolated Cooldown Timer Widget
                          _OtpCooldownTimer(
                            onResend: () {
                              HapticFeedback.selectionClick();
                              context.read<AuthBloc>().add(AuthSignInRequested(phone));
                            },
                          ),

                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _otpController.clear();
                              context.read<AuthBloc>().add(AuthSignOutRequested());
                            },
                            child: Text(
                              'auth.change_phone'.tr(),
                              style: const TextStyle(color: AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Isolated timer component so ticking doesn't trigger widget-tree rebuilds
class _OtpCooldownTimer extends StatefulWidget {
  final VoidCallback onResend;

  const _OtpCooldownTimer({required this.onResend});

  @override
  State<_OtpCooldownTimer> createState() => _OtpCooldownTimerState();
}

class _OtpCooldownTimerState extends State<_OtpCooldownTimer> {
  int _secondsRemaining = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() => _secondsRemaining = 45);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_secondsRemaining > 0) {
      return Text(
        'auth.resend_in'.tr(args: [_secondsRemaining.toString()]),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 14,
        ),
      );
    }

    return TextButton(
      onPressed: () {
        widget.onResend();
        _startTimer();
      },
      child: Text(
        'auth.resend_code'.tr(),
        style: const TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
