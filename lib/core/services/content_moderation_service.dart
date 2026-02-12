import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Content moderation service for ensuring user safety.
/// Provides text and image content analysis, profanity filtering,
/// and report management.
class ContentModerationService {
  ContentModerationService._();

  static final ContentModerationService _instance =
      ContentModerationService._();
  static ContentModerationService get instance => _instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @visibleForTesting
  void setDependencies({
    required FirebaseFunctions functions,
    required FirebaseStorage storage,
  }) {
    // Note: This is not the right way to inject dependencies.
    // This is a workaround for the existing singleton pattern.
    // A proper dependency injection solution should be used in a real app.
  }

  // ==========================================================================
  // PROFANITY FILTER
  // ==========================================================================

  /// Common profanity patterns (basic list - expand as needed)
  /// In production, use a more comprehensive database or API
  static const Set<String> _profanityPatterns = {
    // Placeholder patterns - actual implementation should use
    // a comprehensive profanity database or external API
    'badword1',
    'badword2',
    // Add more patterns...
  };

  /// Leetspeak character substitutions for bypass detection
  static const Map<String, String> _leetSpeakMap = {
    '0': 'o',
    '1': 'i',
    '3': 'e',
    '4': 'a',
    '5': 's',
    '7': 't',
    '8': 'b',
    '@': 'a',
    '\$': 's',
  };

  /// Pre-normalized profanity patterns (leetspeak chars resolved to their
  /// letter equivalents). Fixes R-125: patterns like 'badword1' are normalized
  /// to 'badwordi' so they match against normalized input text.
  static final Set<String> _normalizedProfanityPatterns = {
    for (final p in _profanityPatterns) _normalizePattern(p),
  };

  /// Normalize a pattern string using the leetspeak map.
  static String _normalizePattern(String pattern) {
    var normalized = pattern.toLowerCase();
    for (final entry in _leetSpeakMap.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized;
  }

  /// Check if text contains profanity.
  bool containsProfanity(String text) {
    final normalizedText = _normalizeText(text);

    for (final pattern in _normalizedProfanityPatterns) {
      if (normalizedText.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  /// Filter profanity from text by replacing with asterisks.
  String filterProfanity(String text) {
    var result = text;
    final normalizedText = _normalizeText(text);

    for (final pattern in _normalizedProfanityPatterns) {
      if (normalizedText.contains(pattern)) {
        // Build a regex that matches the pattern including leetspeak variants
        // e.g., 'bad' → '[b8][a4@][d]' to match 'b4d', 'b@d', etc.
        final regex = RegExp(
          _buildLeetAwarePattern(pattern),
          caseSensitive: false,
        );
        result = result.replaceAll(regex, '*' * pattern.length);
      }
    }

    return result;
  }

  /// Build a regex that matches a normalized pattern with any leetspeak variant.
  /// For each character that has leetspeak equivalents, creates a character class.
  /// E.g., 'bad' → '[b8][a4@][d]' matches 'bad', 'b4d', 'b@d', '84d', etc.
  String _buildLeetAwarePattern(String normalizedPattern) {
    final buffer = StringBuffer();
    for (final char in normalizedPattern.split('')) {
      final variants = <String>[char];
      for (final entry in _leetSpeakMap.entries) {
        if (entry.value == char) {
          variants.add(_escapeRegex(entry.key));
        }
      }
      if (variants.length > 1) {
        buffer.write('[${variants.join()}]');
      } else {
        buffer.write(_escapeRegex(char));
      }
    }
    return buffer.toString();
  }

  /// Normalize text for comparison (lowercase, remove leetspeak).
  String _normalizeText(String text) {
    var normalized = text.toLowerCase();

    // Replace leetspeak characters
    for (final entry in _leetSpeakMap.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }

    // Remove spaces between characters (common bypass technique)
    normalized = normalized.replaceAll(RegExp(r'\s+'), '');

    // Remove common special character bypasses
    normalized = normalized.replaceAll(RegExp(r'[._\-*]'), '');

    return normalized;
  }

  String _escapeRegex(String text) {
    return text.replaceAllMapped(
      RegExp(r'[.*+?^${}()|[\]\\]'),
      (match) => '\\${match.group(0)}',
    );
  }

  // ==========================================================================
  // CONTENT ANALYSIS
  // ==========================================================================

  /// Analyze text content for various safety issues.
  Future<ContentAnalysisResult> analyzeText(String text) async {
    try {
      final callable = _functions.httpsCallable('moderateTextContent');
      final result = await callable.call<Map<String, dynamic>>({'content': text});
      final data = result.data;

      final isApproved = data['action'] == 'allow';
      final issues = <ContentIssue>[];
      if (!isApproved) {
        issues.add(ContentIssue(
          type: _mapIssueType(data['reason']),
          severity: _mapSeverity(data['severity']),
          description: data['reason'] ?? 'Content flagged for review',
        ));
      }

      return ContentAnalysisResult(
        isApproved: isApproved,
        issues: issues,
        filteredText: isApproved ? text : filterProfanity(text),
      );
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        print('Error calling moderateTextContent: ${e.message}');
      }
      // Fallback to local analysis in case of error
      return _localAnalyzeText(text);
    } catch (e) {
      if (kDebugMode) {
        print('Error analyzing text: $e');
      }
      return _localAnalyzeText(text);
    }
  }

  ContentAnalysisResult _localAnalyzeText(String text) {
    final issues = <ContentIssue>[];

    // Check for profanity
    if (containsProfanity(text)) {
      issues.add(const ContentIssue(
        type: ContentIssueType.profanity,
        severity: ContentSeverity.medium,
        description: 'Text contains potentially offensive language',
      ));
    }

    // Check for personal information sharing
    if (_containsPersonalInfo(text)) {
      issues.add(const ContentIssue(
        type: ContentIssueType.personalInfo,
        severity: ContentSeverity.high,
        description: 'Text may contain personal contact information',
      ));
    }

    // Check for spam patterns
    if (_containsSpamPatterns(text)) {
      issues.add(const ContentIssue(
        type: ContentIssueType.spam,
        severity: ContentSeverity.low,
        description: 'Text shows spam-like patterns',
      ));
    }

    // Check for harassment indicators
    if (_containsHarassment(text)) {
      issues.add(const ContentIssue(
        type: ContentIssueType.harassment,
        severity: ContentSeverity.high,
        description: 'Text may contain harassment or threats',
      ));
    }

    return ContentAnalysisResult(
      isApproved: issues.isEmpty ||
          issues.every((i) => i.severity == ContentSeverity.low),
      issues: issues,
      filteredText: filterProfanity(text),
    );
  }

  ContentIssueType _mapIssueType(String? reason) {
    if (reason == null) return ContentIssueType.other;
    if (reason.contains('profanity')) return ContentIssueType.profanity;
    if (reason.contains('personal info')) return ContentIssueType.personalInfo;
    if (reason.contains('spam')) return ContentIssueType.spam;
    if (reason.contains('harassment')) return ContentIssueType.harassment;
    return ContentIssueType.other;
  }

  ContentSeverity _mapSeverity(String? severity) {
    switch (severity) {
      case 'low':
        return ContentSeverity.low;
      case 'medium':
        return ContentSeverity.medium;
      case 'high':
        return ContentSeverity.high;
      case 'critical':
        return ContentSeverity.critical;
      default:
        return ContentSeverity.medium;
    }
  }

  /// Check if text contains personal contact information.
  bool _containsPersonalInfo(String text) {
    // Phone number patterns
    final phonePattern = RegExp(
      r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}',
    );

    // Email pattern
    final emailPattern = RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    );

    // Social media handles pattern
    final socialPattern = RegExp(
      r'(@[a-zA-Z0-9_]{3,}|instagram\.com|snapchat|whatsapp|telegram)',
      caseSensitive: false,
    );

    return phonePattern.hasMatch(text) ||
        emailPattern.hasMatch(text) ||
        socialPattern.hasMatch(text);
  }

  /// Check for spam patterns.
  bool _containsSpamPatterns(String text) {
    // Excessive caps
    final capsRatio = text
            .split('')
            .where((c) => c == c.toUpperCase() && c != c.toLowerCase())
            .length /
        text.length;

    if (text.length > 10 && capsRatio > 0.7) {
      return true;
    }

    // Repeated characters (e.g., "hellooooo")
    final repeatedChars = RegExp(r'(.)\1{4,}');
    if (repeatedChars.hasMatch(text)) {
      return true;
    }

    // URLs (potential external link spam)
    final urlPattern = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );
    if (urlPattern.hasMatch(text)) {
      return true;
    }

    return false;
  }

  /// Check for harassment indicators.
  bool _containsHarassment(String text) {
    final normalizedText = text.toLowerCase();

    // Threat indicators
    final threatPatterns = [
      'kill you',
      'hurt you',
      'find you',
      'come for you',
      'watch out',
      'you\'ll regret',
      'you will regret',
    ];

    for (final pattern in threatPatterns) {
      if (normalizedText.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  // ==========================================================================
  // IMAGE MODERATION
  // ==========================================================================

  /// Analyze image for safety issues.
  /// In production, this should call an external moderation API
  /// (e.g., Google Cloud Vision, AWS Rekognition, Microsoft Azure Content Moderator)
  Future<ImageModerationResult> analyzeImage(List<int> imageBytes) async {
    try {
      final storageRef = _storage.ref().child('moderation_images/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = storageRef.putData(Uint8List.fromList(imageBytes));
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();

      final callable = _functions.httpsCallable('moderateImageContent');
      final result = await callable.call<Map<String, dynamic>>({'imageUrl': imageUrl});
      final data = result.data;

      final isApproved = data['action'] == 'allow';
      return ImageModerationResult(
        isApproved: isApproved,
        adultScore: data['adultScore'] ?? 0.0,
        violenceScore: data['violenceScore'] ?? 0.0,
        racyScore: data['racyScore'] ?? 0.0,
        rejectionReason: data['reason'],
      );
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        print('Error calling moderateImageContent: ${e.message}');
      }
      return const ImageModerationResult(isApproved: true, adultScore: 0, violenceScore: 0, racyScore: 0);
    } catch (e) {
      if (kDebugMode) {
        print('Error analyzing image: $e');
      }
      return const ImageModerationResult(isApproved: true, adultScore: 0, violenceScore: 0, racyScore: 0);
    }
  }

  // ==========================================================================
  // REPORT MANAGEMENT
  // ==========================================================================

  /// Validate report reason and description.
  ReportValidation validateReport({
    required ReportCategory category,
    required String description,
  }) {
    final issues = <String>[];

    // Check description length
    if (description.trim().length < 10) {
      issues.add('Please provide more detail about the issue');
    }

    if (description.length > 1000) {
      issues.add('Description is too long (max 1000 characters)');
    }

    // Check for required details based on category
    if (category == ReportCategory.impersonation &&
        !description.toLowerCase().contains('who')) {
      issues.add('For impersonation reports, please specify who is being impersonated');
    }

    if (issues.isEmpty) {
      return const ReportValidation(isValid: true, issues: []);
    }
    return ReportValidation(
      isValid: false,
      issues: issues,
    );
  }
}

// =============================================================================
// DATA MODELS
// =============================================================================

/// Result of content text analysis.
class ContentAnalysisResult {
  final bool isApproved;
  final List<ContentIssue> issues;
  final String filteredText;

  const ContentAnalysisResult({
    required this.isApproved,
    required this.issues,
    required this.filteredText,
  });

  Map<String, dynamic> toJson() => {
        'isApproved': isApproved,
        'issues': issues.map((i) => i.toJson()).toList(),
        'filteredText': filteredText,
      };
}

/// A specific content issue found during analysis.
class ContentIssue {
  final ContentIssueType type;
  final ContentSeverity severity;
  final String description;

  const ContentIssue({
    required this.type,
    required this.severity,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'severity': severity.name,
        'description': description,
      };
}

/// Types of content issues.
enum ContentIssueType {
  profanity,
  personalInfo,
  spam,
  harassment,
  nsfw,
  violence,
  hate,
  scam,
  other,
}

/// Severity levels for content issues.
enum ContentSeverity {
  low,
  medium,
  high,
  critical,
}

/// Result of image moderation.
class ImageModerationResult {
  final bool isApproved;
  final double adultScore;
  final double violenceScore;
  final double racyScore;
  final String? rejectionReason;

  const ImageModerationResult({
    required this.isApproved,
    required this.adultScore,
    required this.violenceScore,
    required this.racyScore,
    this.rejectionReason,
  });

  factory ImageModerationResult.fromApiResponse(Map<String, dynamic> json) {
    final adult = (json['adult'] as num?)?.toDouble() ?? 0.0;
    final violence = (json['violence'] as num?)?.toDouble() ?? 0.0;
    final racy = (json['racy'] as num?)?.toDouble() ?? 0.0;

    // Thresholds for approval
    const adultThreshold = 0.7;
    const violenceThreshold = 0.8;
    const racyThreshold = 0.9;

    final isApproved = adult < adultThreshold &&
        violence < violenceThreshold &&
        racy < racyThreshold;

    String? reason;
    if (!isApproved) {
      if (adult >= adultThreshold) {
        reason = 'Image contains adult content';
      } else if (violence >= violenceThreshold) {
        reason = 'Image contains violent content';
      } else if (racy >= racyThreshold) {
        reason = 'Image is too explicit';
      }
    }

    return ImageModerationResult(
      isApproved: isApproved,
      adultScore: adult,
      violenceScore: violence,
      racyScore: racy,
      rejectionReason: reason,
    );
  }
}

/// Categories for user reports.
enum ReportCategory {
  harassment('Harassment or bullying'),
  inappropriateContent('Inappropriate content'),
  spam('Spam or scam'),
  impersonation('Impersonation'),
  underage('Underage user'),
  violence('Threats or violence'),
  hateSpeech('Hate speech'),
  other('Other');

  final String displayName;
  const ReportCategory(this.displayName);
}

/// Validation result for a report.
class ReportValidation {
  final bool isValid;
  final List<String> issues;

  const ReportValidation({
    required this.isValid,
    required this.issues,
  });
}

/// Extension for easy JSON encoding.
extension ContentModerationJson on ContentAnalysisResult {
  String toJsonString() => jsonEncode(toJson());
}
