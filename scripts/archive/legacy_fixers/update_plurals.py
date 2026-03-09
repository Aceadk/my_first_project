import json

arb_path = "lib/l10n/app_en.arb"
with open(arb_path, "r") as f:
    data = json.load(f)

data["photosRejected"] = "{count, plural, =1{1 photo rejected: {reason}} other{{count} photos rejected: {reason}}}"
data["@photosRejected"] = {"placeholders": {"count": {"type": "int"}, "reason": {"type": "String"}}}

data["photoSlotsAvailable"] = "{count, plural, =1{Only 1 more photo slot available.} other{Only {count} more photo slots available.}}"
data["@photoSlotsAvailable"] = {"placeholders": {"count": {"type": "int"}}}

data["photoCount"] = "{count, plural, =1{1 photo} other{{count} photos}}"
data["@photoCount"] = {"placeholders": {"count": {"type": "int"}}}

data["storyCountStr"] = "{count, plural, =1{Story} other{{count}}}"
data["@storyCountStr"] = {"placeholders": {"count": {"type": "int"}}}

data["personLikesYou"] = "{count, plural, =1{1 person likes you} other{{count} people like you}}"
data["@personLikesYou"] = {"placeholders": {"count": {"type": "int"}}}

data["blockedUserCount"] = "{count, plural, =1{1 blocked user} other{{count} blocked users}}"
data["@blockedUserCount"] = {"placeholders": {"count": {"type": "int"}}}

with open(arb_path, "w") as f:
    json.dump(data, f, indent=2)

