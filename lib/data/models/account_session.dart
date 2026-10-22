class AccountSession {
  final String token, id, name, email, role;
  final DateTime expiresAt;
  AccountSession(Map<String, dynamic> data)
      : token = data['token'] as String,
        expiresAt = DateTime.parse(data['expiresAt'] as String),
        id = data['user']['id'] as String,
        name = data['user']['name'] as String,
        email = data['user']['email'] as String,
        role = data['user']['role'] as String;
}
