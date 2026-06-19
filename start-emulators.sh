#!/bin/bash
export PATH="$HOME/.nvm/versions/node/v22.21.1/bin:$PATH"
# Run from this script's directory (the project root) so it works regardless of
# where it's invoked or who checks out the repo.
cd "$(dirname "$0")" || exit 1
firebase emulators:start --only auth,functions,firestore,storage
