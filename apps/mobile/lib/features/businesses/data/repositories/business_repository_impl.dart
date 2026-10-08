import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/repositories/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final SupabaseClient _supabase;

  BusinessRepositoryImpl(this._supabase);

  @override
  Future<BusinessEntity?> getBusinessForUser(String userId) async {
    final response = await _supabase.from('businesses').select().eq('owner_id', userId).maybeSingle();
    
    if (response != null) {
      return BusinessEntity(
        id: response['id'] as String,
        ownerId: response['owner_id'] as String,
        name: response['name'] as String,
        type: response['type'] as String,
      );
    }
    return null;
  }

  @override
  Future<BusinessEntity> createBusiness(String userId, String name, String type) async {
    final response = await _supabase.from('businesses').insert({
      'owner_id': userId,
      'name': name,
      'type': type,
    }).select().single();

    return BusinessEntity(
      id: response['id'] as String,
      ownerId: response['owner_id'] as String,
      name: response['name'] as String,
      type: response['type'] as String,
    );
  }

  @override
  Future<BusinessEntity> updateBusiness(String businessId, String name, String type) async {
    final response = await _supabase.from('businesses').update({
      'name': name,
      'type': type,
    }).eq('id', businessId).select().single();

    return BusinessEntity(
      id: response['id'] as String,
      ownerId: response['owner_id'] as String,
      name: response['name'] as String,
      type: response['type'] as String,
    );
  }

  @override
  Future<void> deleteAccount() async {
    await _supabase.rpc('delete_user_account');
  }
}
