import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}
class AuthSignInRequested extends AuthEvent {
  final String phone;
  AuthSignInRequested(this.phone);
}
class AuthVerifyOTPRequested extends AuthEvent {
  final String phone;
  final String otp;
  AuthVerifyOTPRequested(this.phone, this.otp);
}
class AuthSignOutRequested extends AuthEvent {}

abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserEntity user;
  AuthAuthenticated(this.user);
}
class AuthUnauthenticated extends AuthState {}
class AuthOTPVerificationPending extends AuthState {
  final String phone;
  AuthOTPVerificationPending(this.phone);
}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc(this.authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>((event, emit) async {
      try {
        final user = await authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<AuthSignInRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.signInWithPhone(event.phone);
        emit(AuthOTPVerificationPending(event.phone));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<AuthVerifyOTPRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authRepository.verifyOTP(event.phone, event.otp);
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthError('Invalid OTP'));
        }
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<AuthSignOutRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.signOut();
        emit(AuthUnauthenticated());
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}
