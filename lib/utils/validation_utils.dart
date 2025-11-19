class ValidationUtils {
  /// Validates email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email);
  }

  /// Validates password strength
  static bool isValidPassword(String password) {
    if (password.isEmpty) return false;

    // Minimum 8 characters, at least one letter and one number
    final passwordRegex = RegExp(r'^(?=.*[a-zA-Z])(?=.*\d).{8,}$');

    return passwordRegex.hasMatch(password);
  }

  /// Validates nickname
  static bool isValidNickname(String nickname) {
    if (nickname.isEmpty) return false;

    // Only letters, numbers, spaces, and some special characters
    // Minimum 2 characters, maximum 20
    final nicknameRegex = RegExp(r'^[a-zA-Z0-9À-ÿ\s._-]{2,20}$');

    return nicknameRegex.hasMatch(nickname);
  }

  /// Get email validation error message
  static String? getEmailError(String email) {
    if (email.isEmpty) {
      return 'El email es requerido';
    }
    if (!isValidEmail(email)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  /// Get password validation error message
  static String? getPasswordError(String password) {
    if (password.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'La contraseña debe contener al menos una letra';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'La contraseña debe contener al menos un número';
    }
    return null;
  }

  /// Get nickname validation error message
  static String? getNicknameError(String nickname) {
    if (nickname.isEmpty) {
      return 'El nickname es requerido';
    }
    if (nickname.length < 2) {
      return 'El nickname debe tener al menos 2 caracteres';
    }
    if (nickname.length > 20) {
      return 'El nickname no puede tener más de 20 caracteres';
    }
    if (!isValidNickname(nickname)) {
      return 'El nickname contiene caracteres no válidos';
    }
    return null;
  }

  /// Validate password confirmation
  static String? getPasswordConfirmationError(
    String password,
    String confirmation,
  ) {
    if (confirmation.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (password != confirmation) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
}
