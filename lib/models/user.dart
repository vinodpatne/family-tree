class AppUser {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  const AppUser({required this.id, required this.email, required this.name, this.avatarUrl});
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(id: json['id'], email: json['email'], name: json['name'], avatarUrl: json['avatarUrl']);
  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name, 'avatarUrl': avatarUrl};
}
