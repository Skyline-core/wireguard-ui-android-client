/// WireGuard UI profile / account APIs (`GetUser`, `update-user`, passkeys).
class ProfileUserVm {
  ProfileUserVm({
    required this.username,
    required this.displayName,
    required this.email,
    required this.admin,
  });

  final String username;
  final String displayName;
  final String email;
  final bool admin;

  factory ProfileUserVm.fromJson(Map<String, dynamic> j) {
    return ProfileUserVm(
      username: j['username']?.toString() ?? '',
      displayName: j['display_name']?.toString() ?? '',
      email: j['email']?.toString() ?? '',
      admin: j['admin'] == true,
    );
  }
}

/// From `GET /api/profile/passkeys` (current user + passkey list).
class ProfilePasskeysSnapshot {
  ProfilePasskeysSnapshot({
    required this.username,
    required this.passkeys,
  });

  final String username;
  final List<PasskeyItemVm> passkeys;
}

class PasskeyItemVm {
  PasskeyItemVm({
    required this.credentialId,
    required this.name,
    required this.fingerprint,
  });

  final String credentialId;
  final String name;
  final String fingerprint;

  factory PasskeyItemVm.fromJson(Map<String, dynamic> j) {
    return PasskeyItemVm(
      credentialId: j['credential_id']?.toString() ?? '',
      name: j['name']?.toString() ?? 'Passkey',
      fingerprint: j['fingerprint']?.toString() ?? '—',
    );
  }
}

class UpdateUserResult {
  UpdateUserResult({
    required this.ok,
    this.message,
    this.reauthenticate = false,
  });

  final bool ok;
  final String? message;
  final bool reauthenticate;
}

class PasskeyMutationResult {
  PasskeyMutationResult({
    required this.ok,
    this.message,
    this.reauthenticate = false,
  });

  final bool ok;
  final String? message;
  final bool reauthenticate;
}
