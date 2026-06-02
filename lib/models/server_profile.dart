class ServerProfile {
  final String id;
  String name;
  int port;
  String rootFolder;
  bool anonymousAccess;
  String username;
  String password;

  ServerProfile({
    required this.id,
    this.name = 'Default',
    this.port = 2121,
    this.rootFolder = '/storage/emulated/0',
    this.anonymousAccess = false,
    this.username = 'admin',
    this.password = 'password',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'port': port,
    'rootFolder': rootFolder,
    'anonymousAccess': anonymousAccess,
    'username': username,
    'password': password,
  };

  factory ServerProfile.fromJson(Map<String, dynamic> json) => ServerProfile(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Default',
    port: json['port'] as int? ?? 2121,
    rootFolder: json['rootFolder'] as String? ?? '/storage/emulated/0',
    anonymousAccess: json['anonymousAccess'] as bool? ?? false,
    username: json['username'] as String? ?? 'admin',
    password: json['password'] as String? ?? 'password',
  );

  ServerProfile copy() => ServerProfile.fromJson(toJson());
}