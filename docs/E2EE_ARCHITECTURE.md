# End-to-End Encryption (E2EE) Architecture

## Overview

This document outlines the high-level architecture for implementing End-to-End Encryption (E2EE) within the Crush app's messaging ecosystem. E2EE ensures that only the communicating users can read the messages, preventing eavesdropping by the server, ISPs, or unauthorized third parties.

Firebase Firestore provides encryption at rest, and HTTPS/WSS provide encryption in transit. However, true E2EE requires message payloads to be encrypted on the sender's device and only decrypted on the recipient's device.

## Proposed Protocol: The Signal Protocol Base

For modern messaging applications, the Signal Protocol is the industry standard. It relies on two core algorithms:

1. **X3DH (Extended Triple Diffie-Hellman)**: Used for asynchronous key agreement. It allows two users to establish a shared secret key even if one of them is offline.
2. **Double Ratchet Algorithm**: Used for exchanging encrypted messages. It ensures forward secrecy (past messages remain secure if the current key is compromised) and future secrecy (future messages remain secure if the current key is compromised).

### Key Management Infrastructure (KMI)

To support X3DH, the Crush backend must act as a Key Distribution Center.

- **Identity Keys**: Long-term Ed25519 key pairs. Public keys are registered with the server upon account creation.
- **Signed Pre-Keys**: Medium-term key pairs, signed by the Identity Key, rotated periodically (e.g., weekly).
- **One-Time Pre-Keys**: A batch of one-time use keys uploaded by each user. Useful for initial message handshakes when the recipient is offline.

The backend does **NOT** hold private keys. It only serves public keys to clients requesting to initiate a session.

## The Moderation Conflict

There is an inherent paradox between true E2EE and server-side content moderation. If the server cannot read the message payload, it cannot scan it for toxic content (e.g., via the `onMessageCreated` Firebase Function).

### Resolution Strategies

#### 1. Client-Side Moderation (On-Device ML)

- Provide a lightweight TensorFlow Lite (or Apple CoreML) model to the client application.
- Before encrypting the message, the sender's device scans the text. If flagged, the UI can warn the sender or block transmission.
- **Pros**: Maintains strict E2EE.
- **Cons**: Increases app size; models can be reverse-engineered or bypassed by modified clients.

#### 2. Recipient-Initiated Reporting (Zero-Knowledge Moderation)

- Messages remain fully completely E2EE.
- If a recipient finds a message abusive, they can explicitly "Report" it.
- **Reporting Mechanism**: The reporting client decrypts the offending message, attaches cryptographic proof (the sender's signature of that message), and sends it to the moderation backend.
- **Cloud Function Adaptation**: The backend moderation pipeline is moved from `onMessageCreated` to entirely sit behind a `/v1/safety/report` endpoint.
- **Pros**: The only scalable way to manage abuse while preserving absolute privacy for benign conversations.

## Conclusion and Recommendations

For a dating application where privacy and trust are paramount, **Recipient-Initiated Reporting** is the recommended pattern. We have implemented a lightweight server-side NLP scanner for immediate use, but as the app matures, transitioning to E2EE will require decoupling ambient server moderation in favor of explicit user reporting flows.
