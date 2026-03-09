import os

patches = {
    "lib/features/profile/presentation/widgets/profile_media_picker.dart": [
        (
            "'${errors.length} photo${errors.length == 1 ? '' : 's'} rejected: ${errors.first}'",
            "AppLocalizations.of(context)!.photosRejected(errors.length, errors.first)"
        ),
        (
            "'Only $remaining more photo slot${remaining == 1 ? '' : 's'} available.'",
            "AppLocalizations.of(context)!.photoSlotsAvailable(remaining)"
        )
    ],
    "lib/features/profile/presentation/screens/profile_media_screen.dart": [
        (
            "'${photos.length} photo${photos.length == 1 ? '' : 's'}'",
            "AppLocalizations.of(context)!.photoCount(photos.length)"
        )
    ],
    "lib/features/discovery/presentation/widgets/story_ring.dart": [
        (
            "storyCount == 1 ? 'Story' : '$storyCount'",
            "AppLocalizations.of(context)!.storyCountStr(storyCount)"
        )
    ],
    "lib/features/discovery/presentation/screens/likes_you_screen.dart": [
        (
            "'$count ${count == 1 ? 'person likes' : 'people like'} you'",
            "AppLocalizations.of(context)!.personLikesYou(count)"
        )
    ],
    "lib/features/settings/presentation/screens/settings_screen.dart": [
        (
            "'$blockedCount blocked user${blockedCount == 1 ? '' : 's'}'",
            "AppLocalizations.of(context)!.blockedUserCount(blockedCount)"
        )
    ]
}

for file_path, replacements in patches.items():
    if os.path.exists(file_path):
        with open(file_path, "r") as f:
            content = f.read()
            
        for old, new in replacements:
            content = content.replace(old, new)
            
        with open(file_path, "w") as f:
            f.write(content)
