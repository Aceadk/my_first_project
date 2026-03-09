import os
import glob
import re

auth_files = glob.glob('lib/features/auth/**/*.dart', recursive=True) + glob.glob('lib/core/**/*.dart', recursive=True)

findings = {
    "token_storage": [],
    "oauth_providers": [],
    "biometric": [],
    "account_deletion": [],
    "rate_limiting": [],
    "error_handling": [],
    "sign_in_with_apple": False,
    "ipad_responsiveness": []
}

for fpath in auth_files:
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()

        # Token Storage
        if 'SharedPreferences' in content and ('token' in content.lower() or 'auth' in content.lower()):
            findings["token_storage"].append(f"Possible insecure token storage in SharedPreferences: {fpath}")
        if 'FlutterSecureStorage' in content:
            findings["token_storage"].append(f"Secure storage used in: {fpath}")

        # OAuth
        if 'GoogleAuthProvider' in content or 'google_sign_in' in content:
            findings["oauth_providers"].append("Google")
        if 'AppleAuthProvider' in content or 'sign_in_with_apple' in content:
            findings["oauth_providers"].append("Apple")
            findings["sign_in_with_apple"] = True

        # Biometric
        if 'local_auth' in content or 'biometric' in content.lower():
            findings["biometric"].append(f"Biometric logic found in: {fpath}")

        # Account deletion
        if 'deleteAccount' in content or 'deleteUser' in content:
            findings["account_deletion"].append(f"Deletion logic in: {fpath}")
        
        # iPad Responsiveness (LayoutBuilder/MediaQuery used?)
        if 'presentation/screens' in fpath:
            if 'LayoutBuilder' not in content and 'MediaQuery' not in content:
                findings["ipad_responsiveness"].append(f"No responsive builders in: {fpath}")

print("=== AUTH AUDIT SUMMARY ===")
for k, v in findings.items():
    if isinstance(v, list):
        print(f"[{k}]: {len(v)} findings -> {list(set(v))[:5]}")
    else:
        print(f"[{k}]: {v}")

