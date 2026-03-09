import os

filepath = "lib/features/chat/presentation/screens/message_requests_screen.dart"
if os.path.exists(filepath):
    with open(filepath, "r") as f:
        text = f.read()
    
    idx = text.find("/// Match celebration dialog.")
    if idx != -1:
        text = text[:idx]
        with open(filepath, "w") as f:
            f.write(text)

