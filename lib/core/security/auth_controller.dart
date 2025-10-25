import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bio_auth_service.dart';
import 'pin_repository.dart';

enum AuthStatus { loading, needsSetup, locked, authenticated }

@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.awaitingConfirmation = false,
    this.biometricsAvailable = false,
    this.biometricsEnabled = false,
    this.processing = false,
    this.error,
    this.errorVersion = 0,
  });

  final AuthStatus status;
  final bool awaitingConfirmation;
  final bool biometricsAvailable;
  final bool biometricsEnabled;
  final bool processing;
  final String? error;
  final int errorVersion;

  bool get canUseBiometric => biometricsAvailable && biometricsEnabled;

  AuthState copyWith({
    AuthStatus? status,
    bool? awaitingConfirmation,
    bool? biometricsAvailable,
    bool? biometricsEnabled,
    bool? processing,
    String? error,
    int? errorVersion,
  }) {
    return AuthState(
      status: status ?? this.status,
      awaitingConfirmation: awaitingConfirmation ?? this.awaitingConfirmation,
      biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      processing: processing ?? this.processing,
      error: error,
      errorVersion: errorVersion ?? this.errorVersion,
    );
  }
}

final authStateProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  late final PinRepository _pins;
  late final BioAuthService _bio;
  String? _pendingPin;
  bool _bioAttempted = false;

  @override
  AuthState build() {
    _pins = ref.read(pinRepositoryProvider);
    _bio = ref.read(bioAuthServiceProvider);
    final hasPin = _pins.hasPin;
    final initialStatus = hasPin ? AuthStatus.locked : AuthStatus.needsSetup;
    final initialState = AuthState(
      status: initialStatus,
      biometricsEnabled: _pins.isBiometricEnabled,
    );
    Future(() => _initializeBiometrics(initialStatus));
    return initialState;
  }

  Future<void> _initializeBiometrics(AuthStatus initial) async {
    final available = await _bio.isBiometricAvailable();
    state = state.copyWith(biometricsAvailable: available);
    if (initial == AuthStatus.locked && state.canUseBiometric) {
      await tryBiometricUnlock();
    }
  }

  Future<void> submitSetupPin(String pin) async {
    if (pin.length != 4) {
      state = state.copyWith(
        error: 'Enter a 4-digit PIN',
        errorVersion: state.errorVersion + 1,
      );
      return;
    }
    if (_pendingPin == null) {
      _pendingPin = pin;
      state = state.copyWith(
        awaitingConfirmation: true,
        error: null,
      );
      return;
    }
    if (_pendingPin != pin) {
      _pendingPin = null;
      state = state.copyWith(
        awaitingConfirmation: false,
        error: 'PINs do not match. Try again.',
        errorVersion: state.errorVersion + 1,
      );
      return;
    }
    state = state.copyWith(processing: true, error: null);
    await _pins.savePin(pin);
    _pendingPin = null;
    if (!state.biometricsAvailable) {
      await _pins.setBiometricEnabled(false);
    }
    state = state.copyWith(
      status: AuthStatus.authenticated,
      processing: false,
      awaitingConfirmation: false,
      error: null,
    );
  }

  Future<void> setBiometricPreference(bool enabled) async {
    await _pins.setBiometricEnabled(enabled);
    state = state.copyWith(biometricsEnabled: enabled);
  }

  Future<void> unlockWithPin(String pin) async {
    if (pin.length != 4) {
      state = state.copyWith(
        error: 'Enter a 4-digit PIN',
        errorVersion: state.errorVersion + 1,
      );
      return;
    }
    state = state.copyWith(processing: true, error: null);
    final isValid = _pins.verifyPin(pin);
    if (isValid) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        processing: false,
      );
      _bioAttempted = false;
    } else {
      state = state.copyWith(
        processing: false,
        error: 'Incorrect PIN. Try again.',
        errorVersion: state.errorVersion + 1,
      );
    }
  }

  Future<void> tryBiometricUnlock({bool force = false}) async {
    if (!state.canUseBiometric) return;
    if (_bioAttempted && !force) return;
    _bioAttempted = true;
    state = state.copyWith(processing: true, error: null);
    final success = await _bio.authenticate();
    if (success) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        processing: false,
      );
    } else {
      state = state.copyWith(processing: false);
    }
  }

  Future<void> lock() async {
    _bioAttempted = false;
    state = state.copyWith(status: AuthStatus.locked, error: null);
  }
}
