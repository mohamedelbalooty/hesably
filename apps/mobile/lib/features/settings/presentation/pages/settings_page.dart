import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../businesses/domain/entities/business_entity.dart';
import '../bloc/settings_bloc.dart';

class SettingsPage extends StatelessWidget {
  final String businessId;
  const SettingsPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsError) {
          HapticFeedback.vibrate();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppTheme.expense),
          );
        } else if (state is LoggedOut || state is AccountDeleted) {
          HapticFeedback.mediumImpact();
          context.go('/auth');
        } else if (state is WebAccessLinkSent) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إرسال رابط التحقق إلى ${state.email}'),
              backgroundColor: AppTheme.income,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is SettingsLoading || state is SettingsInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }

        if (state is SettingsLoaded) {
          final business = state.business;
          final isArabic = context.locale.languageCode == 'ar';

          return Scaffold(
            appBar: AppBar(
              title: Text('settings.title'.tr()),
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Business Profile Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront_rounded, color: AppTheme.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              business.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              business.type,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.textMuted),
                        onPressed: () => _showEditProfileDialog(context, business),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Web Access Promo Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.cta.withValues(alpha: 0.15),
                        AppTheme.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cta.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.cta.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.laptop_mac_rounded, color: AppTheme.cta, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'settings.web_access'.tr(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppTheme.text,
                                  ),
                                ),
                                Text(
                                  state.emailLinked != null
                                      ? 'مرتبط بـ: ${state.emailLinked}'
                                      : 'settings.web_access_desc'.tr(),
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (state.emailLinked == null)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cta,
                            foregroundColor: AppTheme.text,
                            minimumSize: const Size.fromHeight(40),
                          ),
                          onPressed: () => _showWebAccessDialog(context),
                          child: const Text('تفعيل الدخول عبر الويب'),
                        )
                      else
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.expense,
                            side: const BorderSide(color: AppTheme.expense),
                            minimumSize: const Size.fromHeight(40),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            context.read<SettingsBloc>().add(UnlinkEmail());
                          },
                          child: const Text('إلغاء ربط البريد'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Settings Section: Preferences
                _buildSectionHeader('تفضيلات التطبيق'),
                const SizedBox(height: 8),
                _buildSettingTile(
                  icon: Icons.category_outlined,
                  title: 'settings.manage_categories'.tr(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push('/categories', extra: {'businessId': business.id});
                  },
                ),
                const SizedBox(height: 8),
                _buildSettingTile(
                  icon: Icons.language_rounded,
                  title: 'settings.language'.tr(),
                  trailing: Text(
                    isArabic ? 'العربية' : 'English',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (isArabic) {
                      context.setLocale(const Locale('en', 'US'));
                    } else {
                      context.setLocale(const Locale('ar', 'EG'));
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Settings Section: Account
                _buildSectionHeader('الحساب والأمان'),
                const SizedBox(height: 8),
                _buildSettingTile(
                  icon: Icons.logout_rounded,
                  title: 'settings.logout'.tr(),
                  iconColor: AppTheme.textMuted,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<SettingsBloc>().add(LogoutRequested());
                  },
                ),
                const SizedBox(height: 8),
                _buildSettingTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'settings.delete_account'.tr(),
                  titleColor: AppTheme.expense,
                  iconColor: AppTheme.expense,
                  onTap: () => _showDeleteConfirmation(context),
                ),
              ],
            ),
          );
        }
        return const Scaffold(body: Center(child: Text('Error loading settings')));
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? titleColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppTheme.primary, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? AppTheme.text,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, BusinessEntity business) {
    final nameController = TextEditingController(text: business.name);
    final typeController = TextEditingController(text: business.type);

    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('onboarding.business_name'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'onboarding.business_name'.tr()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: typeController,
              decoration: InputDecoration(labelText: 'onboarding.business_type'.tr()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && typeController.text.isNotEmpty) {
                HapticFeedback.lightImpact();
                context.read<SettingsBloc>().add(UpdateBusinessProfile(
                      name: nameController.text.trim(),
                      type: typeController.text.trim(),
                    ));
                Navigator.of(dContext).pop();
              }
            },
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }

  void _showWebAccessDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('settings.web_access'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.web_access_desc'.tr(),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.trim().isNotEmpty) {
                HapticFeedback.lightImpact();
                context.read<SettingsBloc>().add(EnableWebAccess(emailController.text.trim()));
                Navigator.of(dContext).pop();
              }
            },
            child: const Text('إرسال الرابط'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('settings.delete_account'.tr(), style: const TextStyle(color: AppTheme.expense)),
        content: Text(
          'settings.delete_confirm'.tr(),
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expense),
            onPressed: () {
              HapticFeedback.heavyImpact();
              context.read<SettingsBloc>().add(DeleteAccountRequested());
              Navigator.of(dContext).pop();
            },
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }
}
