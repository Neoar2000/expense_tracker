import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final bioAuthServiceProvider = Provider<BioAuthService>((_) => BioAuthService());

class BioAuthService {
  BioAuthService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isBiometricAvailable() async {
    final supported = await _auth.isDeviceSupported();
    final canCheck = await _auth.canCheckBiometrics;
    return supported && canCheck;
  }

  Future<bool> authenticate() async {
    try {
      final didAuth = await _auth.authenticate(
        localizedReason: 'Unlock Expense Tracker',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return didAuth;
    } catch (_) {
      return false;
    }
  }
}
