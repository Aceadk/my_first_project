import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/preferences.dart';

/// Service for exporting user data in compliance with GDPR/CCPA.
///
/// Allows users to download their personal data in a portable JSON format.
class DataExportService {
  DataExportService({
    required this.currentUserId,
    required this.getUserData,
    required this.getProfileData,
    required this.getMatchesData,
    required this.getMessagesData,
    required this.getPreferencesData,
  });

  final String currentUserId;
  final Future<CrushUser?> Function() getUserData;
  final Future<Profile?> Function() getProfileData;
  final Future<List<CrushMatch>> Function() getMatchesData;
  final Future<List<Message>> Function() getMessagesData;
  final Future<DiscoveryPreferences?> Function() getPreferencesData;

  /// Exports all user data to a JSON file and returns the file path.
  Future<DataExportResult> exportData({
    void Function(String status, double progress)? onProgress,
  }) async {
    try {
      onProgress?.call('Gathering account data...', 0.1);

      final exportData = <String, dynamic>{
        'exportDate': DateTime.now().toIso8601String(),
        'exportVersion': '1.0',
        'dataCategories': [],
      };

      // Gather user data
      onProgress?.call('Exporting account information...', 0.2);
      final user = await getUserData();
      if (user != null) {
        exportData['account'] = _sanitizeUserData(user);
        (exportData['dataCategories'] as List).add('account');
      }

      // Gather profile data
      onProgress?.call('Exporting profile data...', 0.3);
      final profile = await getProfileData();
      if (profile != null) {
        exportData['profile'] = _sanitizeProfileData(profile);
        (exportData['dataCategories'] as List).add('profile');
      }

      // Gather preferences
      onProgress?.call('Exporting preferences...', 0.4);
      final preferences = await getPreferencesData();
      if (preferences != null) {
        exportData['preferences'] = _sanitizePreferencesData(preferences);
        (exportData['dataCategories'] as List).add('preferences');
      }

      // Gather matches
      onProgress?.call('Exporting matches...', 0.6);
      final matches = await getMatchesData();
      exportData['matches'] = matches.map((m) => _sanitizeMatchData(m)).toList();
      exportData['matchCount'] = matches.length;
      if (matches.isNotEmpty) {
        (exportData['dataCategories'] as List).add('matches');
      }

      // Gather messages
      onProgress?.call('Exporting messages...', 0.8);
      final messages = await getMessagesData();
      exportData['messages'] = messages.map((m) => _sanitizeMessageData(m)).toList();
      exportData['messageCount'] = messages.length;
      if (messages.isNotEmpty) {
        (exportData['dataCategories'] as List).add('messages');
      }

      // Write to file
      onProgress?.call('Creating export file...', 0.9);
      final filePath = await _writeExportFile(exportData);

      onProgress?.call('Export complete!', 1.0);

      return DataExportResult.success(
        filePath: filePath,
        exportDate: DateTime.now(),
        dataCategories: List<String>.from(exportData['dataCategories']),
        matchCount: matches.length,
        messageCount: messages.length,
      );
    } catch (e, stackTrace) {
      debugPrint('DataExportService: Export failed - $e\n$stackTrace');
      return DataExportResult.failure(error: e.toString());
    }
  }

  /// Shares the exported data file using the system share sheet.
  Future<void> shareExport(String filePath) async {
    final file = XFile(filePath);
    await Share.shareXFiles(
      [file],
      subject: 'CrushHour Data Export',
      text: 'Your personal data export from CrushHour',
    );
  }

  Map<String, dynamic> _sanitizeUserData(CrushUser user) {
    return {
      'id': user.id,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'username': user.username,
      'isEmailVerified': user.isEmailVerified,
      'isPhoneVerified': user.isPhoneVerified,
      'isIdVerified': user.isIdVerified,
      'subscriptionPlan': user.plan.name,
    };
  }

  Map<String, dynamic> _sanitizeProfileData(Profile profile) {
    return {
      'name': profile.name,
      'age': profile.age,
      'gender': profile.gender,
      'sexualOrientation': profile.sexualOrientation,
      'dateOfBirth': profile.dateOfBirth?.toIso8601String(),
      'bio': profile.bio,
      'photoUrls': profile.photoUrls,
      'videoUrls': profile.videoUrls,
      'interests': profile.interests,
      'profilePrompts': profile.profilePrompts.map((p) => {
        'question': p.question,
        'answer': p.answer,
      }).toList(),
      'heightCm': profile.heightCm,
      'relationshipGoals': profile.relationshipGoals,
      'languages': profile.languages,
      'zodiacSign': profile.zodiacSign,
      'educationLevel': profile.educationLevel,
      'familyPlans': profile.familyPlans,
      'personalityType': profile.personalityType,
      'religion': profile.religion,
      'lifestyle': {
        'workout': profile.workout,
        'smoking': profile.smoking,
        'drinking': profile.drinking,
        'diet': profile.diet,
        'pets': profile.pets,
        'sleepingHabits': profile.sleepingHabits,
      },
      'work': {
        'jobTitle': profile.jobTitle,
        'company': profile.company,
        'school': profile.school,
      },
      'location': {
        'city': profile.city,
        'country': profile.country,
        'livingIn': profile.livingIn,
      },
      'music': {
        'favoriteSongs': profile.favoriteSongs,
        'favoriteSinger': profile.favoriteSinger,
      },
      'isVerified': profile.isVerified,
      'verificationBadge': profile.verificationBadge,
    };
  }

  Map<String, dynamic> _sanitizePreferencesData(DiscoveryPreferences preferences) {
    return {
      'minAge': preferences.minAge,
      'maxAge': preferences.maxAge,
      'maxDistanceKm': preferences.maxDistanceKm,
      'showMeGenders': preferences.showMeGenders,
      'showMyDistance': preferences.showMyDistance,
      'showMyAge': preferences.showMyAge,
      'hideFromDiscovery': preferences.hideFromDiscovery,
      'incognitoMode': preferences.incognitoMode,
      'passportModeEnabled': preferences.passportModeEnabled,
      'passportLocation': preferences.passportLocation,
    };
  }

  Map<String, dynamic> _sanitizeMatchData(CrushMatch match) {
    return {
      'matchId': match.id,
      'otherUserId': match.otherUserId,
      'otherUserName': match.otherUserName,
      'status': match.status.name,
      'isMutual': match.isMutual,
    };
  }

  Map<String, dynamic> _sanitizeMessageData(Message message) {
    return {
      'messageId': message.id,
      'matchId': message.matchId,
      'content': message.content,
      'type': message.type.name,
      'sentAt': message.sentAt.toIso8601String(),
      'isFromMe': message.fromUserId == currentUserId,
      'isRead': message.isRead,
    };
  }

  Future<String> _writeExportFile(Map<String, dynamic> data) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'crushhour_export_$timestamp.json';
    final file = File('${directory.path}/$fileName');

    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(data);
    await file.writeAsString(jsonString);

    return file.path;
  }
}

/// Result of a data export operation.
class DataExportResult {
  const DataExportResult._({
    required this.isSuccess,
    this.filePath,
    this.exportDate,
    this.dataCategories,
    this.matchCount,
    this.messageCount,
    this.error,
  });

  final bool isSuccess;
  final String? filePath;
  final DateTime? exportDate;
  final List<String>? dataCategories;
  final int? matchCount;
  final int? messageCount;
  final String? error;

  factory DataExportResult.success({
    required String filePath,
    required DateTime exportDate,
    required List<String> dataCategories,
    required int matchCount,
    required int messageCount,
  }) {
    return DataExportResult._(
      isSuccess: true,
      filePath: filePath,
      exportDate: exportDate,
      dataCategories: dataCategories,
      matchCount: matchCount,
      messageCount: messageCount,
    );
  }

  factory DataExportResult.failure({required String error}) {
    return DataExportResult._(
      isSuccess: false,
      error: error,
    );
  }
}
