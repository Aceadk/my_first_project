#!/bin/bash
export PATH="$HOME/.nvm/versions/node/v22.21.1/bin:$PATH"
cd /Users/ace/Desktop/my_first_project
firebase emulators:start --only auth,functions,firestore
