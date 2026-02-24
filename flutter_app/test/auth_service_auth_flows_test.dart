import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nebula/services/auth_service.dart';
import 'package:nebula/services/local_store.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class _MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class _TestFirebaseAuth extends MockFirebaseAuth {
  _TestFirebaseAuth({
    super.mockUser,
    super.verifyEmailAutomatically = true,
  }) : super(
        );

  @override
  Future<void> setLanguageCode(String? languageCode) async {}
}

UserInfo _providerInfo({
  required String providerId,
  required String uid,
  required String email,
}) {
  return UserInfo.fromPigeon(
    PigeonUserInfo(
      providerId: providerId,
      uid: uid,
      email: email,
      isAnonymous: false,
      isEmailVerified: true,
    ),
  );
}

void _configureGoogleMocks({
  required _MockGoogleSignIn googleSignIn,
  required _MockGoogleSignInAccount account,
  required _MockGoogleSignInAuthentication auth,
  required String email,
  required String displayName,
}) {
  when(() => googleSignIn.signOut()).thenAnswer((_) async => null);
  when(() => googleSignIn.disconnect()).thenAnswer((_) async {
    return null;
  });
  when(() => googleSignIn.signIn()).thenAnswer((_) async => account);
  when(() => account.email).thenReturn(email);
  when(() => account.displayName).thenReturn(displayName);
  when(() => account.authentication).thenAnswer((_) async => auth);
  when(() => auth.accessToken).thenReturn('fake_access_token');
  when(() => auth.idToken).thenReturn('fake_id_token');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'Registro y login corriente funcionan con Firebase',
    () async {
      final store = await LocalStore.create();
      final firestore = FakeFirebaseFirestore();
      final firebaseAuth = _TestFirebaseAuth(
        verifyEmailAutomatically: true,
      );
      final service = AuthService(
        store,
        firebaseAuth: firebaseAuth,
        firestore: firestore,
      );

      const email = 'corriente@test.com';
      const password = '123456';
      final register = await service.register(
        name: 'Corriente',
        username: 'corriente_user',
        email: email,
        password: password,
      );

      expect(register.ok, isTrue);
      expect(register.message, contains('correo de verificacion'));

      final cloudQuery = await firestore
          .collection('users')
          .where('emailLower', isEqualTo: email)
          .limit(1)
          .get();
      expect(cloudQuery.docs.length, 1);
      final cloudData = cloudQuery.docs.first.data();
      expect(cloudData['emailLower'], email);
      expect(cloudData['hasLocalPassword'], isTrue);

      final login = await service.login(identifier: email, password: password);
      expect(login.ok, isTrue);
      expect(login.data, isNotNull);
      expect(login.data!.email, email);

      final usersAfterLogin = await store.readUsers();
      expect(usersAfterLogin.length, 1);
    },
  );

  test(
    'Google primera vez exige username+password y luego permite login sin dialogo',
    () async {
      final store = await LocalStore.create();
      final firestore = FakeFirebaseFirestore();
      const email = 'googleuser@test.com';
      const uid = 'google_uid_1';

      final mockUser = MockUser(
        uid: uid,
        email: email,
        displayName: 'Google User',
        isEmailVerified: true,
        providerData: [
          _providerInfo(
            providerId: GoogleAuthProvider.PROVIDER_ID,
            uid: uid,
            email: email,
          ),
        ],
      );
      final firebaseAuth = _TestFirebaseAuth(mockUser: mockUser);

      final googleSignIn = _MockGoogleSignIn();
      final account = _MockGoogleSignInAccount();
      final auth = _MockGoogleSignInAuthentication();
      _configureGoogleMocks(
        googleSignIn: googleSignIn,
        account: account,
        auth: auth,
        email: email,
        displayName: 'Google User',
      );

      final service = AuthService(
        store,
        firebaseAuth: firebaseAuth,
        firestore: firestore,
        googleSignIn: googleSignIn,
      );

      final firstGoogleStart = await service.loginWithGoogle();
      expect(firstGoogleStart.ok, isFalse);
      expect(
        firstGoogleStart.message.startsWith(
          'GOOGLE_CONFIRM_REQUIRED_WITH_USERNAME:',
        ),
        isTrue,
      );

      final firstGoogleConfirm = await service.confirmPendingGoogleLogin(
        preferredUsernameForNewAccount: 'google_new_user',
        preferredPasswordForNewAccount: '123456',
      );
      expect(firstGoogleConfirm.ok, isTrue);
      expect(firstGoogleConfirm.data, isNotNull);
      expect(firstGoogleConfirm.data!.username, isNotEmpty);
      expect(firstGoogleConfirm.data!.password, isNotEmpty);

      final cloudDoc = await firestore.collection('users').doc(uid).get();
      final cloudData = cloudDoc.data();
      expect(cloudData, isNotNull);
      expect(cloudData!['hasLocalPassword'], isTrue);

      // Simula estado real despues de link provider password en Firebase.
      mockUser.providerData.add(
        _providerInfo(
          providerId: EmailAuthProvider.PROVIDER_ID,
          uid: uid,
          email: email,
        ),
      );

      await service.logout();
      final secondGoogleStart = await service.loginWithGoogle();
      expect(secondGoogleStart.ok, isFalse);
      expect(
        secondGoogleStart.message.startsWith('GOOGLE_CONFIRM_REQUIRED:'),
        isTrue,
      );
      expect(
        secondGoogleStart.message.startsWith(
          'GOOGLE_CONFIRM_REQUIRED_WITH_USERNAME:',
        ),
        isFalse,
      );

      final secondGoogleConfirm = await service.confirmPendingGoogleLogin();
      expect(secondGoogleConfirm.ok, isTrue);
      expect(secondGoogleConfirm.data, isNotNull);
      expect(secondGoogleConfirm.data!.email, email);
    },
  );
}
