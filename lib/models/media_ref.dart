class MediaRef {
  final String id;
  final String memberId;
  final String localPath;
  final String mimeType;
  const MediaRef({required this.id, required this.memberId, required this.localPath, required this.mimeType});
  factory MediaRef.fromJson(Map<String, dynamic> json) => MediaRef(id: json['id'], memberId: json['memberId'], localPath: json['localPath'], mimeType: json['mimeType']);
  Map<String, dynamic> toJson() => {'id': id, 'memberId': memberId, 'localPath': localPath, 'mimeType': mimeType};
}
