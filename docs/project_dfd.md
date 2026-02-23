# Data Flow Diagram (DFD) — CrushHour Dating App

*Last updated: 2026-02-18*

---

## Table of Contents
1. [Level 0 - Context Diagram](#level-0---context-diagram)
2. [Level 1 - Main Processes](#level-1---main-processes)
3. [Level 2 - Process Decomposition](#level-2---process-decomposition)
4. [Level 3 - Detailed Flows](#level-3---detailed-flows)
5. [Level 4 - Sub-Process Details](#level-4---sub-process-details)
6. [Data Dictionary](#data-dictionary)
7. [Data Store Catalog](#data-store-catalog)

---

## Level 0 - Context Diagram

The highest-level view showing the system as a single process with all external entities.

```mermaid
flowchart TB
    subgraph External Entities
        U[("👤 Mobile User<br/>(iOS/Android)")]
        FB[("🔥 Firebase<br/>Services")]
        ST[("💳 Stripe<br/>Payments")]
        AG[("📹 Agora<br/>Video SDK")]
        RS[("📧 Resend<br/>Email Service")]
        BQ[("📊 BigQuery<br/>Analytics/ML")]
        DEV[("📱 Device<br/>Resources")]
    end

    SYS(("🎯 CrushHour<br/>Dating App<br/>System"))

    U -->|"User Actions<br/>(Login, Swipe, Chat)"| SYS
    SYS -->|"UI Updates<br/>(Profiles, Messages)"| U

    SYS <-->|"Auth, Firestore,<br/>Storage, FCM"| FB
    SYS <-->|"Payment Processing"| ST
    SYS <-->|"Video/Audio Calls"| AG
    SYS -->|"Email Notifications"| RS
    SYS <-->|"ML Recommendations"| BQ
    SYS <-->|"Camera, Photos,<br/>Location, Storage"| DEV
```

### External Entity Descriptions

| Entity | Type | Description |
|--------|------|-------------|
| Mobile User | Human | iOS/Android app user performing dating activities |
| Firebase Services | System | Authentication, Firestore DB, Cloud Storage, FCM, Cloud Functions |
| Stripe | System | Payment processing for subscriptions |
| Agora | System | Real-time video/audio calling SDK |
| Resend | System | Transactional email delivery |
| BigQuery | System | Analytics warehouse and ML-based recommendations |
| Device Resources | System | Camera, photo library, GPS location, secure storage |

---

## Level 1 - Main Processes

Decomposition of the system into major functional processes.

```mermaid
flowchart TB
    subgraph External
        U[("👤 User")]
        FB[("🔥 Firebase")]
        ST[("💳 Stripe")]
        AG[("📹 Agora")]
        RS[("📧 Resend")]
    end

    subgraph "CrushHour System"
        P1["1.0<br/>Authentication<br/>& Identity"]
        P2["2.0<br/>Profile<br/>Management"]
        P3["3.0<br/>Discovery<br/>& Matching"]
        P4["4.0<br/>Messaging<br/>& Chat"]
        P5["5.0<br/>Notifications"]
        P6["6.0<br/>Subscription<br/>& Payments"]
        P7["7.0<br/>Safety<br/>& Moderation"]
        P8["8.0<br/>Video<br/>Calling"]
    end

    subgraph "Data Stores"
        DS1[("D1: Users")]
        DS2[("D2: Matches")]
        DS3[("D3: Messages")]
        DS8[("D8: Message Requests")]
        DS4[("D4: Likes")]
        DS5[("D5: Local Cache")]
        DS6[("D6: Subscriptions")]
        DS7[("D7: Reports/Blocks")]
    end

    U -->|"Credentials"| P1
    P1 -->|"Auth Token"| U
    P1 <-->|"Auth State"| FB
    P1 <--> DS1

    U -->|"Profile Data"| P2
    P2 -->|"Profile View"| U
    P2 <--> DS1
    P2 <-->|"Media Files"| FB

    U -->|"Location, Prefs"| P3
    P3 -->|"Candidate Deck"| U
    P3 <--> DS1
    P3 <--> DS2
    P3 <--> DS4

    U -->|"Message Input"| P4
    P4 -->|"Chat History"| U
    P4 <--> DS2
    P4 <--> DS3
    P4 <--> DS8

    P1 -->|"Auth Events"| P5
    P3 -->|"Match Events"| P5
    P4 -->|"Message Events"| P5
    P5 -->|"Push/Email"| U
    P5 <-->|"FCM"| FB
    P5 -->|"Email"| RS

    U -->|"Payment Request"| P6
    P6 -->|"Plan Status"| U
    P6 <-->|"Checkout"| ST
    P6 <--> DS6

    U -->|"Report/Block"| P7
    P7 -->|"Safety Status"| U
    P7 <--> DS7
    P7 <--> DS1

    U -->|"Call Request"| P8
    P8 -->|"Video Stream"| U
    P8 <-->|"RTC Token"| AG
```

### Process Summary (Level 1)

| Process | Name | Description |
|---------|------|-------------|
| 1.0 | Authentication & Identity | User registration, login, password management, verification |
| 2.0 | Profile Management | Create, update, media upload, completeness tracking |
| 3.0 | Discovery & Matching | Deck loading, swiping, match creation, ML recommendations |
| 4.0 | Messaging & Chat | Send/receive messages, message requests, reactions, read status |
| 5.0 | Notifications | Push notifications, email alerts, event triggers |
| 6.0 | Subscription & Payments | Stripe checkout, webhook handling, plan management |
| 7.0 | Safety & Moderation | Reporting, blocking, content moderation |
| 8.0 | Video Calling | Agora token generation, call management |

---

## Level 2 - Process Decomposition

### 2.1 Process 1.0 - Authentication & Identity

```mermaid
flowchart TB
    subgraph External
        U[("👤 User")]
        FB[("🔥 Firebase Auth")]
        RS[("📧 Resend")]
    end

    subgraph "1.0 Authentication & Identity"
        P1_1["1.1<br/>Send OTP"]
        P1_2["1.2<br/>Verify OTP"]
        P1_3["1.3<br/>Password<br/>Sign Up"]
        P1_4["1.4<br/>Password<br/>Login"]
        P1_5["1.5<br/>Password<br/>Reset"]
        P1_6["1.6<br/>Change<br/>Password"]
        P1_7["1.7<br/>Accept<br/>Terms"]
        P1_8["1.8<br/>Account<br/>Lifecycle"]
    end

    subgraph "Data Stores"
        DS1[("D1: Users")]
        DS_OTP[("D1.1: OTPs")]
        DS_RATE[("D1.2: Rate Limits")]
        DS_AUDIT[("D1.3: Audit Logs")]
        DS_LOCAL[("D5: Local Cache")]
    end

    U -->|"Email/Phone"| P1_1
    P1_1 -->|"OTP Code"| RS
    P1_1 --> DS_OTP
    P1_1 --> DS_RATE

    U -->|"OTP Code"| P1_2
    P1_2 <--> DS_OTP
    P1_2 -->|"Custom Token"| FB
    P1_2 -->|"Auth Token"| U
    P1_2 --> DS_AUDIT

    U -->|"Username,<br/>Email, Password"| P1_3
    P1_3 --> DS1
    P1_3 -->|"Custom Token"| FB
    P1_3 --> DS_AUDIT

    U -->|"Identifier,<br/>Password"| P1_4
    P1_4 <--> DS1
    P1_4 <--> DS_RATE
    P1_4 -->|"Custom Token"| FB
    P1_4 --> DS_AUDIT

    U -->|"Email"| P1_5
    P1_5 -->|"Reset OTP"| RS
    P1_5 <--> DS_OTP

    U -->|"Current + New<br/>Password"| P1_6
    P1_6 <--> DS1
    P1_6 -->|"Confirmation Email"| RS
    P1_6 --> DS_AUDIT

    U -->|"Accept"| P1_7
    P1_7 --> DS1

    U -->|"Deactivate/<br/>Delete"| P1_8
    P1_8 --> DS1
    P1_8 --> DS_AUDIT
```

#### Data Flows - Authentication

| Flow | From | To | Data |
|------|------|-----|------|
| DF1.1 | User | 1.1 Send OTP | email, phone, purpose |
| DF1.2 | 1.1 | Resend | to, otp, purpose |
| DF1.3 | User | 1.2 Verify OTP | identifier, otp |
| DF1.4 | 1.2 | User | customToken, user object |
| DF1.5 | User | 1.3 Sign Up | username, email, password |
| DF1.6 | 1.3 | D1 Users | uid, email, username, passwordHash |
| DF1.7 | User | 1.4 Login | identifier, password |
| DF1.8 | 1.4 | User | customToken, user object |
| DF1.9 | User | 1.6 Change Password | currentPassword, newPassword |
| DF1.10 | 1.6 | Resend | Password changed email |

---

### 2.2 Process 2.0 - Profile Management

```mermaid
flowchart TB
    subgraph External
        U[("👤 User")]
        DEV[("📱 Device")]
        FB_ST[("🗄️ Firebase<br/>Storage")]
    end

    subgraph "2.0 Profile Management"
        P2_1["2.1<br/>Save Basic<br/>Info"]
        P2_2["2.2<br/>Save Profile<br/>Details"]
        P2_3["2.3<br/>Upload<br/>Media"]
        P2_4["2.4<br/>Upload ID<br/>Document"]
        P2_5["2.5<br/>Get Current<br/>User"]
        P2_6["2.6<br/>Check<br/>Completeness"]
        P2_7["2.7<br/>Update<br/>Location"]
    end

    subgraph "Data Stores"
        DS1[("D1: Users")]
        DS_MEDIA[("D2.1: Media<br/>Storage")]
        DS_VERIFY[("D2.2: Verification<br/>Docs")]
        DS_LOCAL[("D5: Local Cache")]
    end

    U -->|"Name, DOB,<br/>Gender"| P2_1
    P2_1 --> DS1

    U -->|"Bio, Interests,<br/>Work, School"| P2_2
    P2_2 --> DS1

    DEV -->|"Photo/Video<br/>File"| P2_3
    P2_3 -->|"Upload"| FB_ST
    P2_3 -->|"photoUrls"| DS1
    FB_ST --> DS_MEDIA

    DEV -->|"ID Front/Back"| P2_4
    P2_4 --> DS_VERIFY
    P2_4 -->|"pendingVerification"| DS1

    U -->|"Request"| P2_5
    P2_5 <--> DS1
    P2_5 -->|"CrushUser"| U
    P2_5 --> DS_LOCAL

    U -->|"Request"| P2_6
    P2_6 <--> DS1
    P2_6 -->|"% Complete,<br/>Missing Items"| U

    DEV -->|"GPS Coords"| P2_7
    P2_7 --> DS1
```

#### Data Flows - Profile Management

| Flow | From | To | Data |
|------|------|-----|------|
| DF2.1 | User | 2.1 Basic Info | name, dateOfBirth, gender, orientation |
| DF2.2 | 2.1 | D1 Users | profile.name, profile.dateOfBirth, profile.gender |
| DF2.3 | User | 2.2 Details | bio, interests[], jobTitle, company, school |
| DF2.4 | Device | 2.3 Upload | File (bytes), contentType |
| DF2.5 | 2.3 | Storage | users/{uid}/media/{fileName} |
| DF2.6 | 2.3 | D1 Users | photoUrls[] |
| DF2.7 | 2.6 | User | {percentage, missingItems[], isComplete} |

---

### 2.3 Process 3.0 - Discovery & Matching

```mermaid
flowchart TB
    subgraph External
        U[("👤 User")]
        BQ[("📊 BigQuery<br/>ML")]
    end

    subgraph "3.0 Discovery & Matching"
        P3_1["3.1<br/>Fetch<br/>Candidates"]
        P3_2["3.2<br/>Apply<br/>Filters"]
        P3_3["3.3<br/>ML<br/>Ranking"]
        P3_4["3.4<br/>Swipe<br/>Right (Like)"]
        P3_5["3.5<br/>Swipe<br/>Left (Pass)"]
        P3_6["3.6<br/>Check<br/>Mutual Match"]
        P3_7["3.7<br/>Create<br/>Match"]
        P3_8["3.8<br/>Fetch<br/>Likes You"]
        P3_9["3.9<br/>Fetch<br/>Top Picks"]
    end

    subgraph "Data Stores"
        DS1[("D1: Users")]
        DS2[("D2: Matches")]
        DS4[("D4: Likes")]
        DS_LIMIT[("D4.1: Like<br/>Limits")]
        DS_LOCAL[("D5: Local Cache")]
    end

    U -->|"Location,<br/>Preferences"| P3_1
    P3_1 <--> DS1
    P3_1 --> P3_2

    P3_2 -->|"Filtered<br/>Candidates"| P3_3
    P3_2 <--> DS4
    P3_2 <--> DS2

    P3_3 <-->|"Score Request"| BQ
    P3_3 -->|"Ranked Deck"| U
    P3_3 --> DS_LOCAL

    U -->|"targetUserId"| P3_4
    P3_4 <--> DS_LIMIT
    P3_4 --> DS4
    P3_4 --> P3_6

    U -->|"targetUserId"| P3_5
    P3_5 --> DS4

    P3_6 <--> DS4
    P3_6 -->|"If Mutual"| P3_7

    P3_7 --> DS2
    P3_7 -->|"Match Event"| U

    U -->|"Request<br/>(Premium)"| P3_8
    P3_8 <--> DS4
    P3_8 -->|"Profiles"| U

    U -->|"Request"| P3_9
    P3_9 <--> BQ
    P3_9 -->|"Top 10"| U
```

#### Data Flows - Discovery & Matching

| Flow | From | To | Data |
|------|------|-----|------|
| DF3.1 | User | 3.1 Fetch | userId, location, preferences |
| DF3.2 | 3.1 | D1 Users | Query: nearby users, age range, gender |
| DF3.3 | 3.2 | 3.3 ML | candidateIds[], userFeatures |
| DF3.4 | BigQuery | 3.3 | scores[], rankings |
| DF3.5 | User | 3.4 Like | targetUserId |
| DF3.6 | 3.4 | D4 Likes | {likerId, likedId, timestamp, type} |
| DF3.7 | 3.6 | 3.7 | isMutual: true |
| DF3.8 | 3.7 | D2 Matches | {user1Id, user2Id, status, createdAt} |
| DF3.9 | 3.7 | Notifications | Match event trigger |
| DF3.10 | User | 3.8 Fetch Likes You | userId |
| DF3.11 | 3.8 | User | liked profiles (blurred for free users) |

---

### 2.4 Process 4.0 - Messaging & Chat

```mermaid
flowchart TB
    subgraph External
        U[("👤 User")]
        FB_ST[("🗄️ Storage")]
    end

    subgraph "4.0 Messaging & Chat"
        P4_1["4.1<br/>Send<br/>Message"]
        P4_2["4.2<br/>Fetch<br/>Messages"]
        P4_3["4.3<br/>Watch<br/>Real-time"]
        P4_4["4.4<br/>Mark<br/>Read"]
        P4_5["4.5<br/>Upload<br/>Media"]
        P4_6["4.6<br/>Unsend<br/>Message"]
        P4_7["4.7<br/>Add<br/>Reaction"]
        P4_8["4.8<br/>Content<br/>Moderation"]
        P4_9["4.9<br/>Typing<br/>Indicator"]
        P4_10["4.10<br/>Send<br/>Message Request"]
        P4_11["4.11<br/>Fetch<br/>Message Requests"]
    end

    subgraph "Data Stores"
        DS2[("D2: Matches")]
        DS3[("D3: Messages")]
        DS8[("D8: Message Requests")]
        DS_MEDIA[("D3.1: Chat<br/>Media")]
        DS_FLAGS[("D7.1: Moderation<br/>Flags")]
    end

    U -->|"matchId, text"| P4_1
    P4_1 --> P4_8
    P4_8 -->|"Clean"| DS3
    P4_8 -->|"Flagged"| DS_FLAGS
    P4_1 -->|"Message Event"| U

    U -->|"matchId, cursor"| P4_2
    P4_2 <--> DS3
    P4_2 -->|"Message[]"| U

    U -->|"matchId"| P4_3
    P4_3 <-.->|"Stream"| DS3
    P4_3 -.->|"New Messages"| U

    U -->|"messageIds[]"| P4_4
    P4_4 --> DS3

    U -->|"File"| P4_5
    P4_5 --> FB_ST
    FB_ST --> DS_MEDIA
    P4_5 -->|"mediaUrl"| P4_1

    U -->|"messageId<br/>(15 min)"| P4_6
    P4_6 --> DS3

    U -->|"messageId,<br/>emoji"| P4_7
    P4_7 --> DS3

    U -->|"matchId,<br/>isTyping"| P4_9
    P4_9 --> DS2

    U -->|"toUserId,<br/>content"| P4_10
    P4_10 --> DS8

    U -->|"userId"| P4_11
    P4_11 <--> DS8
    P4_11 -->|"Request[]"| U
```

#### Data Flows - Messaging

| Flow | From | To | Data |
|------|------|-----|------|
| DF4.1 | User | 4.1 Send | matchId, text, mediaUrl?, replyTo? |
| DF4.2 | 4.1 | D3 Messages | {id, senderId, text, timestamp, sendStatus} |
| DF4.3 | 4.8 | D3 | moderationStatus, flags[] |
| DF4.4 | User | 4.2 Fetch | matchId, limit, cursor |
| DF4.5 | D3 | 4.2 | Message[] with pagination |
| DF4.6 | 4.3 | User | Real-time message stream |
| DF4.7 | User | 4.7 React | messageId, emoji (❤️ 😂 😮 😢 😡 👍) |
| DF4.8 | User | 4.10 Send Request | toUserId, content |
| DF4.9 | 4.10 | D8 Message Requests | {id, fromUserId, toUserId, content, expiresAt} |
| DF4.10 | User | 4.11 Fetch Requests | userId |
| DF4.11 | D8 | 4.11 | MessageRequest[] |
| DF4.12 | 4.11 | User | MessageRequest list |

---

### 2.5 Process 5.0 - Notifications

```mermaid
flowchart TB
    subgraph External
        U[("👤 User")]
        FCM[("📱 FCM")]
        RS[("📧 Resend")]
    end

    subgraph "5.0 Notifications"
        P5_1["5.1<br/>Message<br/>Trigger"]
        P5_2["5.2<br/>Match<br/>Trigger"]
        P5_3["5.3<br/>Auth<br/>Trigger"]
        P5_4["5.4<br/>Send<br/>Push"]
        P5_5["5.5<br/>Send<br/>Email"]
        P5_6["5.6<br/>Check<br/>Preferences"]
    end

    subgraph "Data Stores"
        DS1[("D1: Users")]
        DS_FCM[("D5.1: FCM<br/>Tokens")]
        DS_PREFS[("D5.2: Notification<br/>Prefs")]
    end

    P5_1 -->|"New Message"| P5_6
    P5_2 -->|"New Match"| P5_6
    P5_3 -->|"Password<br/>Changed"| P5_6

    P5_6 <--> DS_PREFS
    P5_6 -->|"Push Enabled"| P5_4
    P5_6 -->|"Email Enabled"| P5_5

    P5_4 <--> DS_FCM
    P5_4 -->|"FCM Message"| FCM
    FCM -->|"Push"| U

    P5_5 -->|"Email"| RS
    RS -->|"Delivery"| U
```

---

### 2.6 Process 6.0 - Subscription & Payments

```mermaid
flowchart TB
    subgraph External
        U[("👤 User")]
        ST[("💳 Stripe")]
    end

    subgraph "6.0 Subscription & Payments"
        P6_1["6.1<br/>Create<br/>Checkout"]
        P6_2["6.2<br/>Handle<br/>Webhook"]
        P6_3["6.3<br/>Sync<br/>Status"]
        P6_4["6.4<br/>Update<br/>Plan"]
    end

    subgraph "Data Stores"
        DS1[("D1: Users")]
        DS6[("D6: Subscriptions")]
        DS_CHECKOUT[("D6.1: Checkout<br/>Sessions")]
    end

    U -->|"Plan Request"| P6_1
    P6_1 <-->|"Create Session"| ST
    P6_1 --> DS_CHECKOUT
    P6_1 -->|"Checkout URL"| U

    ST -->|"Webhook Event"| P6_2
    P6_2 --> DS6
    P6_2 --> P6_4

    U -->|"Refresh"| P6_3
    P6_3 <-->|"Get Subscription"| ST
    P6_3 --> P6_4

    P6_4 --> DS1
    P6_4 --> DS6
```

#### Data Flows - Payments

| Flow | From | To | Data |
|------|------|-----|------|
| DF6.1 | User | 6.1 Checkout | userId, planId |
| DF6.2 | 6.1 | Stripe | customerId, priceId, successUrl, cancelUrl |
| DF6.3 | Stripe | 6.1 | checkoutSessionId, url |
| DF6.4 | Stripe | 6.2 Webhook | event (checkout.session.completed, etc.) |
| DF6.5 | 6.4 | D1 Users | plan: "plus" or "free" |
| DF6.6 | 6.4 | D6 | stripeCustomerId, subscriptionId, status |

---

### 2.7 Process 7.0 - Safety & Moderation

```mermaid
flowchart TB
    subgraph External
        U[("👤 User")]
        RS[("📧 Resend")]
    end

    subgraph "7.0 Safety & Moderation"
        P7_1["7.1<br/>Report<br/>User"]
        P7_2["7.2<br/>Block<br/>User"]
        P7_3["7.3<br/>Unblock<br/>User"]
        P7_4["7.4<br/>Appeal<br/>Action"]
        P7_5["7.5<br/>Auto<br/>Moderation"]
        P7_6["7.6<br/>Flag for<br/>Review"]
        P7_7["7.7<br/>Create<br/>Date Plan"]
    end

    subgraph "Data Stores"
        DS1[("D1: Users")]
        DS_REPORTS[("D7: Reports")]
        DS_BLOCKS[("D7.1: Blocks")]
        DS_FLAGS[("D7.2: Auto<br/>Flags")]
        DS_APPEALS[("D7.3: Appeals")]
    end

    U -->|"targetId,<br/>reason"| P7_1
    P7_1 --> DS_REPORTS
    P7_1 --> P7_5

    U -->|"targetId"| P7_2
    P7_2 --> DS_BLOCKS
    P7_2 --> DS1

    U -->|"targetId"| P7_3
    P7_3 --> DS_BLOCKS

    U -->|"actionId,<br/>reason"| P7_4
    P7_4 --> DS_APPEALS

    P7_5 -->|"Score > Threshold"| P7_6
    P7_6 --> DS_FLAGS

    U -->|"date details,<br/>contact email"| P7_7
    P7_7 -->|"date plan email"| RS
```

---

#### Data Flows - Safety

| Flow | From | To | Data |
|------|------|-----|------|
| DF7.1 | User | 7.1 Report | targetId, reason |
| DF7.2 | 7.2 Report | D7 Reports | report data |
| DF7.3 | User | 7.2 Block | targetId |
| DF7.4 | User | 7.3 Unblock | targetId |
| DF7.5 | User | 7.4 Appeal | actionId, reason |
| DF7.6 | 7.6 Flag | D7.2 Auto Flags | flag record |
| DF7.7 | User | 7.7 Create Date Plan | matchName, dateTime, location, contact |
| DF7.8 | 7.7 Create Date Plan | Resend | email notification |

### 2.8 Process 8.0 - Video Calling

```mermaid
flowchart TB
    subgraph External
        U[("👤 User")]
        AG[("📹 Agora")]
    end

    subgraph "8.0 Video Calling"
        P8_1["8.1<br/>Generate<br/>Token"]
        P8_2["8.2<br/>Start<br/>Call"]
        P8_3["8.3<br/>End<br/>Call"]
    end

    subgraph "Data Stores"
        DS2[("D2: Matches")]
    end

    U -->|"matchId"| P8_1
    P8_1 -->|"Token Request"| AG
    AG -->|"RTC Token"| P8_1
    P8_1 -->|"Token"| U

    U -->|"Join Channel"| P8_2
    P8_2 --> DS2
    P8_2 <-->|"RTC Stream"| AG

    U -->|"Leave"| P8_3
    P8_3 --> DS2
```

---

## Level 3 - Detailed Flows

### 3.1 Authentication - OTP Flow (Process 1.1 + 1.2)

```mermaid
flowchart TB
    subgraph "1.1 Send OTP - Detailed"
        P1_1_1["1.1.1<br/>Validate<br/>Input"]
        P1_1_2["1.1.2<br/>Check Rate<br/>Limit"]
        P1_1_3["1.1.3<br/>Generate<br/>OTP"]
        P1_1_4["1.1.4<br/>Hash &<br/>Store OTP"]
        P1_1_5["1.1.5<br/>Send via<br/>Resend"]
        P1_1_6["1.1.6<br/>Log Audit"]
    end

    subgraph "Data Stores"
        DS_OTP[("OTPs")]
        DS_RATE[("Rate Limits")]
        DS_AUDIT[("Audit Logs")]
    end

    INPUT[/"Email/Phone"/] --> P1_1_1
    P1_1_1 -->|"Valid"| P1_1_2
    P1_1_1 -->|"Invalid"| ERROR1[/"Error"/]

    P1_1_2 <--> DS_RATE
    P1_1_2 -->|"Allowed"| P1_1_3
    P1_1_2 -->|"Blocked"| ERROR2[/"Rate Limit Error"/]

    P1_1_3 -->|"6-digit OTP"| P1_1_4
    P1_1_4 --> DS_OTP

    P1_1_4 --> P1_1_5
    P1_1_5 --> RESEND[/"Resend API"/]

    P1_1_5 --> P1_1_6
    P1_1_6 --> DS_AUDIT

    P1_1_6 --> SUCCESS[/"Success Response"/]
```

### 3.2 Discovery - Candidate Fetching (Process 3.1 + 3.2 + 3.3)

```mermaid
flowchart TB
    subgraph "3.1-3.3 Fetch Candidates - Detailed"
        P3_1_1["3.1.1<br/>Get User<br/>Location"]
        P3_1_2["3.1.2<br/>Get User<br/>Preferences"]
        P3_2_1["3.2.1<br/>Query Users<br/>by Gender"]
        P3_2_2["3.2.2<br/>Filter by<br/>Distance"]
        P3_2_3["3.2.3<br/>Filter by<br/>Age Range"]
        P3_2_4["3.2.4<br/>Exclude<br/>Seen/Blocked"]
        P3_3_1["3.3.1<br/>Send to<br/>BigQuery ML"]
        P3_3_2["3.3.2<br/>Apply<br/>Scores"]
        P3_3_3["3.3.3<br/>Sort &<br/>Limit"]
        P3_3_4["3.3.4<br/>Cache<br/>Results"]
    end

    subgraph "Data Stores"
        DS1[("Users")]
        DS4[("Likes")]
        DS7[("Blocks")]
        DS_BQ[("BigQuery")]
        DS_CACHE[("Local Cache")]
    end

    INPUT[/"userId"/] --> P3_1_1
    P3_1_1 <--> DS1
    P3_1_1 --> P3_1_2
    P3_1_2 <--> DS1

    P3_1_2 --> P3_2_1
    P3_2_1 <--> DS1
    P3_2_1 -->|"Gender Match"| P3_2_2

    P3_2_2 -->|"Haversine<br/>Calculation"| P3_2_3
    P3_2_3 --> P3_2_4

    P3_2_4 <--> DS4
    P3_2_4 <--> DS7
    P3_2_4 -->|"Clean List"| P3_3_1

    P3_3_1 <--> DS_BQ
    P3_3_1 --> P3_3_2
    P3_3_2 --> P3_3_3
    P3_3_3 -->|"Top 50"| P3_3_4
    P3_3_4 --> DS_CACHE

    P3_3_4 --> OUTPUT[/"Candidate Deck"/]
```

### 3.3 Messaging - Send Message (Process 4.1 + 4.8)

```mermaid
flowchart TB
    subgraph "4.1 + 4.8 Send Message - Detailed"
        P4_1_1["4.1.1<br/>Validate<br/>Match Access"]
        P4_1_2["4.1.2<br/>Check ID<br/>Verification"]
        P4_1_3["4.1.3<br/>Optimistic<br/>Local Update"]
        P4_8_1["4.8.1<br/>Text<br/>Moderation"]
        P4_8_2["4.8.2<br/>Check<br/>Banned Terms"]
        P4_8_3["4.8.3<br/>Assign<br/>Severity"]
        P4_1_4["4.1.4<br/>Create<br/>Message Doc"]
        P4_1_5["4.1.5<br/>Trigger<br/>Notification"]
        P4_1_6["4.1.6<br/>Update<br/>Send Status"]
    end

    subgraph "Data Stores"
        DS2[("Matches")]
        DS3[("Messages")]
        DS_FLAGS[("Mod Flags")]
        DS_LOCAL[("Local State")]
    end

    INPUT[/"matchId, text"/] --> P4_1_1
    P4_1_1 <--> DS2
    P4_1_1 -->|"Authorized"| P4_1_2
    P4_1_1 -->|"Denied"| ERROR1[/"Permission Error"/]

    P4_1_2 -->|"Verified"| P4_1_3
    P4_1_2 -->|"Not Verified"| ERROR2[/"Verification Required"/]

    P4_1_3 --> DS_LOCAL
    P4_1_3 -->|"sendStatus: sending"| P4_8_1

    P4_8_1 --> P4_8_2
    P4_8_2 -->|"Clean"| P4_1_4
    P4_8_2 -->|"Contains Banned"| P4_8_3

    P4_8_3 -->|"Low"| P4_1_4
    P4_8_3 -->|"High"| DS_FLAGS
    P4_8_3 -->|"High"| HELD[/"Message Held"/]

    P4_1_4 --> DS3
    P4_1_4 --> P4_1_5
    P4_1_5 --> FCM[/"FCM Trigger"/]

    P4_1_5 --> P4_1_6
    P4_1_6 --> DS_LOCAL
    P4_1_6 -->|"sendStatus: sent"| OUTPUT[/"Success"/]
```

---

## Level 4 - Sub-Process Details

### 4.1 Password Hashing (Sub-process of 1.3, 1.4, 1.6)

```mermaid
flowchart TB
    subgraph "Password Hashing Sub-Process"
        P_1["4.1.1<br/>Receive<br/>Plain Password"]
        P_2["4.1.2<br/>Generate<br/>Salt (16 bytes)"]
        P_3["4.1.3<br/>Apply<br/>scrypt Algorithm"]
        P_4["4.1.4<br/>Encode<br/>Base64"]
        P_5["4.1.5<br/>Store Hash<br/>+ Salt"]
    end

    INPUT[/"plainPassword"/] --> P_1
    P_1 --> P_2
    P_2 -->|"salt"| P_3
    P_1 -->|"password"| P_3
    P_3 -->|"N=16384, r=8, p=1"| P_4
    P_4 --> P_5
    P_5 --> OUTPUT[/"passwordHash"/]
```

### 4.2 Distance Calculation (Sub-process of 3.2.2)

```mermaid
flowchart TB
    subgraph "Haversine Distance Calculation"
        P_1["4.2.1<br/>Get User<br/>Coordinates"]
        P_2["4.2.2<br/>Get Candidate<br/>Coordinates"]
        P_3["4.2.3<br/>Convert to<br/>Radians"]
        P_4["4.2.4<br/>Apply Haversine<br/>Formula"]
        P_5["4.2.5<br/>Compare to<br/>Max Distance"]
    end

    USER[/"userLat, userLng"/] --> P_1
    CANDIDATE[/"candLat, candLng"/] --> P_2

    P_1 --> P_3
    P_2 --> P_3

    P_3 --> P_4
    P_4 -->|"distance (km)"| P_5

    PREF[/"maxDistance"/] --> P_5

    P_5 -->|"distance <= max"| INCLUDE[/"Include in Deck"/]
    P_5 -->|"distance > max"| EXCLUDE[/"Exclude"/]
```

### 4.3 Content Moderation Scoring (Sub-process of 4.8)

```mermaid
flowchart TB
    subgraph "Content Moderation Scoring"
        P_1["4.3.1<br/>Normalize<br/>Text"]
        P_2["4.3.2<br/>Check<br/>Banned Terms"]
        P_3["4.3.3<br/>Check<br/>Patterns"]
        P_4["4.3.4<br/>Calculate<br/>Severity Score"]
        P_5["4.3.5<br/>Determine<br/>Action"]
    end

    INPUT[/"messageText"/] --> P_1
    P_1 -->|"lowercase"| P_2

    P_2 -->|"matched terms"| P_4
    P_2 -->|"no match"| P_3

    P_3 -->|"pattern hits"| P_4
    P_3 -->|"clean"| CLEAN[/"status: clean"/]

    P_4 --> P_5

    P_5 -->|"score < 0.3"| ALLOW[/"action: allow"/]
    P_5 -->|"score 0.3-0.7"| HOLD[/"action: hold"/]
    P_5 -->|"score > 0.7"| FLAG[/"action: flag"/]
```

### 4.4 Rate Limiting Check (Sub-process of 1.1, 1.4)

```mermaid
flowchart TB
    subgraph "Rate Limiting Check"
        P_1["4.4.1<br/>Build<br/>Rate Key"]
        P_2["4.4.2<br/>Get Current<br/>Count"]
        P_3["4.4.3<br/>Check<br/>Window"]
        P_4["4.4.4<br/>Compare<br/>to Limit"]
        P_5["4.4.5<br/>Increment<br/>or Block"]
    end

    INPUT[/"action, identifier"/] --> P_1
    P_1 -->|"rate:action:id"| P_2

    DS_RATE[("Rate Limits")] <--> P_2
    P_2 --> P_3

    P_3 -->|"In window"| P_4
    P_3 -->|"Window expired"| RESET[/"Reset Count"/]

    RESET --> P_4

    CONFIG[/"limit, windowMs"/] --> P_4

    P_4 -->|"count < limit"| P_5
    P_4 -->|"count >= limit"| BLOCK[/"Blocked + retryAfterMs"/]

    P_5 -->|"Increment"| DS_RATE
    P_5 --> ALLOW[/"Allowed"/]
```

---

## Data Dictionary

### User Entity (D1)

| Field | Type | Description |
|-------|------|-------------|
| uid | string | Firebase Auth UID (primary key) |
| email | string | User's email address |
| emailLower | string | Lowercase email for queries |
| username | string | Unique username |
| usernameLower | string | Lowercase username for queries |
| phoneNumber | string? | Phone number (optional) |
| passwordHash | string | scrypt hashed password |
| passwordSalt | string | Salt for password hash |
| plan | enum | "free" \| "plus" |
| isEmailVerified | boolean | Email verification status |
| isPhoneVerified | boolean | Phone verification status |
| isIdVerified | boolean | ID verification status |
| hasAcceptedTerms | boolean | T&C acceptance |
| hasCompletedBasicInfo | boolean | Basic info complete |
| hasCompletedProfileSetup | boolean | Profile complete |
| profile | object | Nested profile data |
| profile.name | string | First name (private by default) |
| profile.lastName | string? | Last name (private by default) |
| profile.dateOfBirth | timestamp | Date of birth |
| profile.gender | enum | "female" \| "male" \| "non-binary" |
| profile.orientation | enum | Sexual orientation |
| profile.bio | string | About me (max 500) |
| profile.photoUrls | string[] | Profile photo URLs |
| profile.interests | string[] | Interest tags |
| profile.jobTitle | string? | Job title |
| profile.company | string? | Company name |
| profile.school | string? | School name |
| profile.city | string? | City |
| profile.country | string? | Country |
| profile.latitude | number? | GPS latitude |
| profile.longitude | number? | GPS longitude |
| profile.privacySettings | object | Privacy flags for profile fields |
| profile.privacySettings.showFirstName | boolean | Show first name publicly |
| profile.privacySettings.showLastName | boolean | Show last name publicly |
| notificationPrefs | object | Notification settings |
| notificationPrefs.push | boolean | Push enabled |
| notificationPrefs.email | boolean | Email enabled |
| notificationPrefs.sound | boolean | Sound enabled |
| notificationPrefs.vibration | boolean | Vibration enabled |
| createdAt | timestamp | Account creation |
| updatedAt | timestamp | Last update |

### Match Entity (D2)

| Field | Type | Description |
|-------|------|-------------|
| id | string | Match document ID |
| user1Id | string | First user UID |
| user2Id | string | Second user UID |
| participants | string[] | [user1Id, user2Id] for queries |
| status | enum | "active" \| "unmatched" |
| user1Typing | boolean | User 1 typing indicator |
| user2Typing | boolean | User 2 typing indicator |
| lastMessageAt | timestamp? | Last message timestamp |
| lastMessagePreview | string? | Preview text |
| createdAt | timestamp | Match creation |

### Message Entity (D3)

| Field | Type | Description |
|-------|------|-------------|
| id | string | Message document ID |
| matchId | string | Parent match ID |
| senderId | string | Sender UID |
| text | string | Message content |
| mediaUrl | string? | Attached media URL |
| mediaType | enum? | "image" \| "video" |
| replyTo | string? | Reply reference ID |
| reactions | map | {emoji: userId[]} |
| readBy | string[] | UIDs who read |
| sendStatus | enum | "sending" \| "sent" \| "failed" |
| moderationStatus | enum | "clean" \| "flagged" \| "held" |
| isDeleted | boolean | Soft delete flag |
| deletedFor | string[] | UIDs for whom deleted |
| createdAt | timestamp | Send timestamp |
| editedAt | timestamp? | Last edit timestamp |

### Message Request Entity (D8)

| Field | Type | Description |
|-------|------|-------------|
| id | string | Message request document ID (pair key) |
| fromUserId | string | Sender UID |
| toUserId | string | Recipient UID |
| content | string | Request message content |
| type | enum | "text" \| "image" \| "video" \| "voice" |
| sentAt | timestamp | Sent timestamp |
| expiresAt | timestamp | Auto-expire after 48 hours |
| fromUserName | string? | Denormalized sender name |
| fromUserPhotoUrl | string? | Denormalized sender photo |
| toUserName | string? | Denormalized recipient name |
| toUserPhotoUrl | string? | Denormalized recipient photo |

### Like Entity (D4)

| Field | Type | Description |
|-------|------|-------------|
| id | string | Like document ID |
| likerId | string | User who liked |
| likedId | string | User who was liked |
| type | enum | "like" \| "superlike" |
| createdAt | timestamp | Like timestamp |

### Report Entity (D7)

| Field | Type | Description |
|-------|------|-------------|
| id | string | Report document ID |
| reporterId | string | Reporter UID |
| reportedId | string | Reported user UID |
| reason | enum | Report reason category |
| details | string? | Additional details |
| status | enum | "pending" \| "reviewed" \| "resolved" |
| createdAt | timestamp | Report timestamp |
| reviewedAt | timestamp? | Review timestamp |

---

## Data Store Catalog

### Firestore Collections

| Store ID | Collection Path | Description | Access |
|----------|-----------------|-------------|--------|
| D1 | `/users/{uid}` | User profiles | Read: all, Write: owner |
| D1.1 | `/auth_email_otps/{id}` | OTP records | Server only |
| D1.2 | `/auth_rate_limits/{key}` | Rate limiting | Server only |
| D1.3 | `/auth_audit_logs/{id}` | Auth audit trail | Server only |
| D2 | `/matches/{id}` | Match records | Participants only |
| D3 | `/matches/{id}/messages/{id}` | Chat messages | Participants only |
| D8 | `/message_requests/{id}` | Pre-match message requests | Participants only |
| D4 | `/likes/{id}` | Like records | Server managed |
| D4.1 | `/like_limits/{uid}` | Daily like limits | Server only |
| D5.1 | `/users/{uid}/fcmTokens/{token}` | FCM tokens | Owner only |
| D6 | `/subscriptions/{uid}` | Subscription status | Owner + server |
| D6.1 | `/checkout_sessions/{id}` | Checkout tracking | Server only |
| D7 | `/reports/{id}` | User reports | Reporter + admin |
| D7.1 | `/blocks/{id}` | User blocks | Blocker only |
| D7.2 | `/automatedFlags/{id}` | Auto-moderation | Server only |
| D7.3 | `/safetyAppeals/{id}` | Appeals | Appellant + admin |

### Firebase Storage Buckets

| Store ID | Path Pattern | Description | Access |
|----------|--------------|-------------|--------|
| DS_MEDIA | `/users/{uid}/media/*` | Profile photos/videos | Public read |
| DS_CHAT | `/chat_media/{matchId}/{uid}/*` | Chat attachments | Participants |
| DS_VERIFY | `/verification/{uid}/*` | ID documents | Server only |

### Local Storage

| Store ID | Technology | Description |
|----------|------------|-------------|
| DS_LOCAL | SharedPreferences | Cache, settings, flags |
| DS_SECURE | FlutterSecureStorage | Auth tokens, identifiers |
| DS_FIRESTORE_CACHE | Firestore SDK | Offline document cache |

---

## Summary

| Level | Processes | Data Stores | External Entities |
|-------|-----------|-------------|-------------------|
| 0 | 1 (System) | - | 7 |
| 1 | 8 | 8 | 5 |
| 2 | 50+ | 15+ | 6 |
| 3 | 25+ detailed | - | - |
| 4 | 4 sub-processes | - | - |

**Total Data Flows Documented:** 60+
**Total Processes:** 80+
**Total Data Stores:** 21+

---

## Revision Notes

- **2026-02-23 (Web Discovery Stories):**
  - Added active profile story flow in discovery:
    - Story media upload (`users/{uid}/stories/*` media path in storage)
    - Story retrieval for discovery candidates
    - Story view tracking (`users/{ownerId}/stories/{storyId}/views/{viewerId}`)
  - Added story viewer process with per-story progress and persisted view-count increment.
