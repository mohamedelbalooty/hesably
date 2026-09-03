import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  @override
  Future<void> signInWithPhone(String phone) async {
    await _supabase.auth.signInWithOtp(phone: phone);
  }

  @override
  Future<UserEntity?> verifyOTP(String phone, String otp) async {
    final response = await _supabase.auth.verifyOTP(
      type: OtpType.sms,
      token: otp,
      phone: phone,
    );
    if (response.user != null) {
      return UserEntity(id: response.user!.id, phone: response.user!.phone ?? phone);
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      return UserEntity(id: user.id, phone: user.phone ?? '');
    }
    return null;
  }
}
