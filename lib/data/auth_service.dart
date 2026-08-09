import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  SupabaseAuthService(this.client);

  final SupabaseClient client;

  User? get currentUser => client.auth.currentUser;

  Future<void> sendEmailOtp(String email) async {
    await client.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
    );
  }

  Future<User?> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final AuthResponse response = await client.auth.verifyOTP(
      type: OtpType.email,
      email: email.trim(),
      token: token.trim(),
    );
    return response.user;
  }

  Future<void> signOut() => client.auth.signOut();
}
