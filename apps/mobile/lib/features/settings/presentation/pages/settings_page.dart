import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is LoggedOut || state is AccountDeleted) {
          context.go('/auth');
        } else if (state is WebAccessLinkSent) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification link sent to ${state.email}')));
        }
      },
      builder: (context, state) {
        if (state is SettingsLoading || state is SettingsInitial) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (state is SettingsLoaded) {
          final business = state.business;
          return Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: ListView(
              children: [
                ListTile(
                  title: const Text('Business Profile'),
                  subtitle: Text('${business.name} - ${business.type}'),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    _showEditProfileDialog(context, business);
                  },
                ),
                ListTile(
                  title: const Text('Manage Categories'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/categories', extra: {'businessId': business.id});
                  },
                ),
                ListTile(
                  title: const Text('Web Access'),
                  subtitle: Text(state.emailLinked != null ? 'Linked to ${state.emailLinked}' : 'Not enabled'),
                  trailing: state.emailLinked == null 
                      ? const Icon(Icons.chevron_right)
                      : TextButton(
                          onPressed: () {
                            context.read<SettingsBloc>().add(UnlinkEmail());
                          },
                          child: const Text('Unlink', style: TextStyle(color: Colors.red)),
                        ),
                  onTap: () {
                    if (state.emailLinked == null) {
                      _showWebAccessDialog(context);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Logout'),
                  leading: const Icon(Icons.logout),
                  onTap: () {
                    context.read<SettingsBloc>().add(LogoutRequested());
                  },
                ),
                ListTile(
                  title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                  leading: const Icon(Icons.delete, color: Colors.red),
                  onTap: () {
                    _showDeleteConfirmation(context);
                  },
                ),
              ],
            ),
          );
        }
        return const Scaffold(body: Center(child: Text('Error loading settings')));
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, BusinessEntity business) {
    final nameController = TextEditingController(text: business.name);
    final typeController = TextEditingController(text: business.type);
    
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text('Edit Business Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Business Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: typeController,
              decoration: const InputDecoration(labelText: 'Business Type'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && typeController.text.isNotEmpty) {
                context.read<SettingsBloc>().add(UpdateBusinessProfile(
                  name: nameController.text,
                  type: typeController.text,
                ));
                Navigator.of(dContext).pop();
              }
            },
            child: const Text('Save'),
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
        title: const Text('Enable Web Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter an email address to link to your account. You will receive a verification link.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email Address'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                context.read<SettingsBloc>().add(EnableWebAccess(emailController.text));
                Navigator.of(dContext).pop();
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone and will delete all your transactions and receipts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<SettingsBloc>().add(DeleteAccountRequested());
              Navigator.of(dContext).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
