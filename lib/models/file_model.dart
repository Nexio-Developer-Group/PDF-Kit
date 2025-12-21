import 'dart:convert';

/// 🧾 A model representing metadata of a file.
class FileInfo {
  final String name;
  final String path;
  final String extension;
  final int size;
  final DateTime? lastModified;
  final String? mimeType;
  final String? parentDirectory;
  final Map<String, dynamic>? exifData; // optional, not used by default
  final Map<String, dynamic>? mediaInfo; // not used for videos here
  final bool isDirectory;
  final int? childrenCount;
  final bool isExpanded; // for tree view UI
  final String? contentHash; // for diffing/versioning
  final List<FileInfo>? children; // cached children for tree structures

  const FileInfo({
    required this.name,
    required this.path,
    required this.extension,
    required this.size,
    this.lastModified,
    this.mimeType,
    this.parentDirectory,
    this.exifData,
    this.mediaInfo,
    this.isDirectory = false,
    this.childrenCount,
    this.isExpanded = false,
    this.contentHash,
    this.children,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) => FileInfo(
    name: json['name'] ?? '',
    path: json['path'] ?? '',
    extension: json['extension'] ?? '',
    size: json['size'] ?? 0,
    lastModified: json['lastModified'] != null
        ? DateTime.tryParse(json['lastModified'])
        : null,
    mimeType: json['mimeType'],
    parentDirectory: json['parentDirectory'],
    exifData: json['exifData'] != null
        ? Map<String, dynamic>.from(json['exifData'])
        : null,
    mediaInfo: json['mediaInfo'] != null
        ? Map<String, dynamic>.from(json['mediaInfo'])
        : null,
    isDirectory: json['isDirectory'] ?? false,
    childrenCount: json['childrenCount'],
    isExpanded: json['isExpanded'] ?? false,
    contentHash: json['contentHash'],
    children: json['children'] != null
        ? (json['children'] as List).map((e) => FileInfo.fromJson(e)).toList()
        : null,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'path': path,
    'extension': extension,
    'size': size,
    'lastModified': lastModified?.toIso8601String(),
    'mimeType': mimeType,
    'parentDirectory': parentDirectory,
    'exifData': exifData,
    'mediaInfo': mediaInfo,
    'isDirectory': isDirectory,
    'childrenCount': childrenCount,
    'isExpanded': isExpanded,
    'contentHash': contentHash,
    'children': children?.map((e) => e.toJson()).toList(),
  };

  /// 🧩 Create a modified copy.
  FileInfo copyWith({
    String? name,
    String? path,
    String? extension,
    int? size,
    DateTime? lastModified,
    String? mimeType,
    String? parentDirectory,
    Map<String, dynamic>? exifData,
    Map<String, dynamic>? mediaInfo,
    bool? isExpanded,
    String? contentHash,
    List<FileInfo>? children,
  }) {
    return FileInfo(
      name: name ?? this.name,
      path: path ?? this.path,
      extension: extension ?? this.extension,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      mimeType: mimeType ?? this.mimeType,
      parentDirectory: parentDirectory ?? this.parentDirectory,
      exifData: exifData ?? this.exifData,
      mediaInfo: mediaInfo ?? this.mediaInfo,
      isDirectory: isDirectory,
      childrenCount: childrenCount,
      isExpanded: isExpanded ?? this.isExpanded,
      contentHash: contentHash ?? this.contentHash,
      children: children ?? this.children,
    );
  }

  /// 🧾 Get file size in readable format (e.g., "2.5 MB")
  String get readableSize {
    if (size < 1024) return "$size B";
    if (size < 1024 * 1024) return "${(size / 1024).toStringAsFixed(2)} KB";
    if (size < 1024 * 1024 * 1024) {
      return "${(size / (1024 * 1024)).toStringAsFixed(2)} MB";
    }
    return "${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }

  /// 🧠 Helpful stringify for debugging or printing.
  @override
  String toString() {
    return '''
📄 FileInfo(
  name: $name,
  path: $path,
  extension: $extension,
  size: ${readableSize},
  lastModified: $lastModified,
  mimeType: $mimeType,
  parentDirectory: $parentDirectory,
  exifData: ${exifData != null ? jsonEncode(exifData) : 'null'},
  mediaInfo: ${mediaInfo != null ? jsonEncode(mediaInfo) : 'null'},
  isExpanded: $isExpanded,
  children: ${children?.length ?? 0}
)''';
  }

  /// 🟰 Equality check.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          path == other.path &&
          extension == other.extension &&
          size == other.size &&
          mimeType == other.mimeType &&
          isExpanded == other.isExpanded &&
          contentHash == other.contentHash;

  /// 🔢 Hash code.
  @override
  int get hashCode =>
      name.hashCode ^
      path.hashCode ^
      extension.hashCode ^
      size.hashCode ^
      mimeType.hashCode ^
      isExpanded.hashCode ^
      contentHash.hashCode;
}
