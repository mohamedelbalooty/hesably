import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/business_repository.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'retail';
  bool _isLoading = false;

  final List<({String key, String labelKey, IconData icon})> _businessTypes = [
    (key: 'retail', labelKey: 'onboarding.type_retail', icon: Icons.storefront_rounded),
    (key: 'restaurant', labelKey: 'onboarding.type_restaurant', icon: Icons.restaurant_rounded),
    (key: 'pharmacy', labelKey: 'onboarding.type_pharmacy', icon: Icons.local_pharmacy_rounded),
    (key: 'service', labelKey: 'onboarding.type_service', icon: Icons.handyman_rounded),
    (key: 'other', labelKey: 'onboarding.type_other', icon: Icons.business_center_rounded),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitBusiness() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final supabase = getIt<SupabaseClient>();
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User session not found');
      }

      final repo = getIt<BusinessRepository>();
      await repo.createBusiness(
        userId,
        _nameController.text.trim(),
        _selectedType,
      );

      HapticFeedback.heavyImpact();
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.expense,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Header
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.store_mall_directory_rounded,
                        size: 34,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Welcome Title
                  Text(
                    'onboarding.welcome_title'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.text,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'onboarding.welcome_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Business Name Field
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'onboarding.business_name'.tr(),
                      hintText: 'onboarding.business_name_hint'.tr(),
                      prefixIcon: const Icon(
                        Icons.edit_note_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال اسم النشاط التجاري'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Business Type Label
                  Text(
                    'onboarding.business_type'.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Business Type Selectable Tiles
                  ..._businessTypes.map((type) {
                    final isSelected = _selectedType == type.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedType = type.key);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.12)
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                type.icon,
                                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  type.labelKey.tr(),
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.text : AppTheme.textMuted,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitBusiness,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.background,
                            ),
                          )
                        : Text('onboarding.start_button'.tr()),
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
