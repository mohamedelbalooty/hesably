import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<void> signInWithPhone(String phone);
  Future<UserEntity?> verifyOTP(String phone, String otp);
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
}
