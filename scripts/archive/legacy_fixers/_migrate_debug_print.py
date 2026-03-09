#!/usr/bin/env python3
"""
Migrate debugPrint() calls to AppLogger.debug()/AppLogger.error() across the Flutter codebase.

Rules:
1. DO NOT modify lib/core/app_logger.dart
2. Replace debugPrint(...) with AppLogger.debug(...) for normal debug logs
3. Replace debugPrint(...) with AppLogger.error(...) for error-related logs
   (those containing "error", "Error", "failed", "Failed", "exception", "Exception")
4. Add AppLogger import where missing
"""

import os
import re
import sys

LIB_DIR = '/Users/ace/my_first_project/lib'
SKIP_FILE = os.path.join(LIB_DIR, 'core/app_logger.dart')
IMPORT_LINE = "import 'package:crushhour/core/app_logger.dart';"

# Files that have debugPrint (excluding app_logger.dart)
TARGET_FILES = [
    'lib/core/services/push_notification_service.dart',
    'lib/features/profile/data/services/profile_media_service.dart',
    'lib/core/performance/performance_monitor.dart',
    'lib/core/services/tracking_consent_service.dart',
    'lib/features/profile/presentation/screens/profile_setup_screen.dart',
    'lib/config/app_config.dart',
    'lib/features/auth/presentation/screens/basic_info_screen.dart',
    'lib/core/services/photo_verification_service.dart',
    'lib/features/auth/data/repositories/impl/http_auth_repository.dart',
    'lib/features/chat/data/repositories/impl/http_chat_repository.dart',
    'lib/features/chat/data/repositories/impl/firebase_chat_repository.dart',
    'lib/core/services/analytics_service.dart',
    'lib/core/network/api_version.dart',
    'lib/features/chat/presentation/screens/chat_screen.dart',
    'lib/features/chat/presentation/bloc/chat_bloc.dart',
    'lib/core/network/certificate_pinning.dart',
    'lib/core/services/app_check_service.dart',
    'lib/core/security/secure_logger.dart',
    'lib/features/discovery/data/repositories/impl/hybrid_discovery_repository.dart',
    'lib/features/profile/data/services/profile_validation_service.dart',
    'lib/features/discovery/data/repositories/impl/http_discovery_repository.dart',
    'lib/data/repositories/fake_repositories.dart',
    'lib/features/subscription/data/repositories/impl/http_subscription_repository.dart',
    'lib/features/settings/presentation/bloc/storage_settings_cubit.dart',
    'lib/features/settings/presentation/bloc/safety_cubit.dart',
    'lib/features/settings/presentation/bloc/privacy_settings_cubit.dart',
    'lib/features/profile/presentation/widgets/profile_media_picker.dart',
    'lib/features/profile/data/repositories/impl/http_profile_repository.dart',
    'lib/features/feature_flags/data/repositories/impl/firebase_feature_flag_repository.dart',
    'lib/features/discovery/presentation/bloc/discovery_bloc.dart',
    'lib/features/discovery/data/services/profile_reaction_service.dart',
    'lib/features/discovery/data/repositories/impl/stub_discovery_repository.dart',
    'lib/features/discovery/data/models/filter_options.dart',
    'lib/features/chat/presentation/widgets/voice_note_recorder.dart',
    'lib/features/chat/presentation/bloc/matches_bloc.dart',
    'lib/data/models/profile_prompt.dart',
    'lib/core/services/offline_cache_service.dart',
    'lib/core/services/gradual_rollout_service.dart',
    'lib/core/services/data_export_service.dart',
    'lib/core/services/crash_reporting_service.dart',
    'lib/core/services/app_update_service.dart',
    'lib/core/security/input_sanitizer.dart',
    'lib/core/network/realtime/realtime_connection.dart',
    'lib/core/network/realtime/firebase_realtime_service.dart',
    'lib/core/network/dto/base_dto.dart',
    'lib/core/network/api_client.dart',
    'lib/core/feature_flags/feature_flags.dart',
    'lib/core/deep_link_bootstrap.dart',
    'lib/core/cache/offline_queue.dart',
    'lib/core/cache/cached_repository.dart',
    'lib/features/chat/data/services/voice_recorder_service.dart',
    'lib/core/services/in_app_review_service.dart',
    'lib/features/calls/data/repositories/impl/http_call_repository.dart',
    'lib/features/feature_flags/data/repositories/impl/stub_feature_flag_repository.dart',
]

# Error-related keywords (case-insensitive check on the full debugPrint line)
ERROR_KEYWORDS = [
    'error', 'Error', 'ERROR',
    'failed', 'Failed', 'FAILED',
    'exception', 'Exception', 'EXCEPTION',
    'fail:', 'Fail:',
]

def is_error_context(line, prev_lines):
    """Check if a debugPrint line is in an error context."""
    line_lower = line.lower()

    # Check if the debugPrint message itself contains error keywords
    for kw in ERROR_KEYWORDS:
        if kw.lower() in line_lower:
            return True

    # Check if we're inside a catch block (look at previous lines)
    for prev in prev_lines:
        stripped = prev.strip()
        if stripped.startswith('} catch') or stripped.startswith('catch (') or stripped.startswith('on '):
            return True

    return False


def has_app_logger_import(content):
    """Check if file already imports AppLogger."""
    return IMPORT_LINE in content


def add_import(content):
    """Add AppLogger import near the top imports."""
    lines = content.split('\n')
    # Find the last import line
    last_import_idx = -1
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("import '") or stripped.startswith('import "'):
            last_import_idx = i

    if last_import_idx >= 0:
        lines.insert(last_import_idx + 1, IMPORT_LINE)
    else:
        # No imports found, add at top
        lines.insert(0, IMPORT_LINE)

    return '\n'.join(lines)


def process_file(filepath):
    """Process a single file, replacing debugPrint with AppLogger calls."""
    full_path = os.path.join('/Users/ace/my_first_project', filepath)

    if not os.path.exists(full_path):
        print(f'  SKIP (not found): {filepath}')
        return 0

    with open(full_path, 'r') as f:
        content = f.read()

    if 'debugPrint(' not in content:
        print(f'  SKIP (no debugPrint): {filepath}')
        return 0

    lines = content.split('\n')
    replacements = 0
    new_lines = []

    for i, line in enumerate(lines):
        if 'debugPrint(' not in line:
            new_lines.append(line)
            continue

        # Get context (previous 5 lines for catch block detection)
        prev_lines = lines[max(0, i-5):i]

        if is_error_context(line, prev_lines):
            new_line = line.replace('debugPrint(', 'AppLogger.error(')
            replacements += 1
        else:
            new_line = line.replace('debugPrint(', 'AppLogger.debug(')
            replacements += 1

        new_lines.append(new_line)

    new_content = '\n'.join(new_lines)

    # Add import if needed
    if replacements > 0 and not has_app_logger_import(new_content):
        new_content = add_import(new_content)

    with open(full_path, 'w') as f:
        f.write(new_content)

    print(f'  DONE ({replacements} replacements): {filepath}')
    return replacements


def main():
    total = 0
    file_count = 0

    print(f'Processing {len(TARGET_FILES)} files...\n')

    for filepath in TARGET_FILES:
        count = process_file(filepath)
        if count > 0:
            file_count += 1
            total += count

    print(f'\nTotal: {total} replacements across {file_count} files')


if __name__ == '__main__':
    main()
