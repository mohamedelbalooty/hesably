import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hesably_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:hesably_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:hesably_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'auth_bloc_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    final tUser = UserEntity(id: '123', phone: '+201000000000');
    final tPhone = '+201000000000';
    final tOtp = '123456';

    test('initial state should be AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthAuthenticated] when AuthCheckRequested is added and user is logged in',
      build: () {
        when(mockAuthRepository.getCurrentUser()).thenAnswer((_) async => tUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when AuthCheckRequested is added and user is not logged in',
      build: () {
        when(mockAuthRepository.getCurrentUser()).thenAnswer((_) async => null);
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        isA<AuthUnauthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthOTPVerificationPending] when AuthSignInRequested is added',
      build: () {
        when(mockAuthRepository.signInWithPhone(any)).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthSignInRequested(tPhone)),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthOTPVerificationPending>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when AuthVerifyOTPRequested is added and successful',
      build: () {
        when(mockAuthRepository.verifyOTP(any, any)).thenAnswer((_) async => tUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthVerifyOTPRequested(tPhone, tOtp)),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
    );
  });
}
