class UserSettings {
  final String age;
  final String personality;
  final String? considerations;
  final String? aboutMe;

  UserSettings({
    this.age = "kids",
    this.personality = "default",
    this.considerations,
    this.aboutMe,
  });

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'personality': personality,
      'considerations': considerations,
      'about_me': aboutMe,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      age: json['age'] ?? "kids",
      personality: json['personality'] ?? "default",
      considerations: json['considerations'],
      aboutMe: json['about_me'],
    );
  }
}

class UpdateSettingsRequest {
  final String user;
  final UserSettings settings;

  UpdateSettingsRequest({required this.user, required this.settings});

  Map<String, dynamic> toJson() {
    return {'user': user, 'settings': settings.toJson()};
  }
}
