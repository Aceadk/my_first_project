# CrushHour Web App Testing Plan

**Created:** 2026-02-06
**Version:** 1.0
**Tester:** Manual Testing

---

## Phase 1: Critical - Authentication & Onboarding

### 1.1 Auth Gateway
| Test | Status | Notes |
|------|--------|-------|
| App loads at localhost | [ ] | |
| Splash screen displays | [ ] | |
| Auth gateway shows login/signup options | [ ] | |
| Logo and branding display correctly | [ ] | |

### 1.2 Sign Up Flow
| Test | Status | Notes |
|------|--------|-------|
| Sign up button navigates to signup screen | [ ] | |
| Email input validates format | [ ] | |
| Password strength indicator works | [ ] | |
| Username validation works | [ ] | |
| Show/hide password toggle | [ ] | |
| Sign up creates account successfully | [ ] | |
| Error messages display for invalid input | [ ] | |

### 1.3 Login Flow
| Test | Status | Notes |
|------|--------|-------|
| Login button navigates to login screen | [ ] | |
| Email/username input works | [ ] | |
| Password input works | [ ] | |
| Login succeeds with valid credentials | [ ] | |
| Error message for invalid credentials | [ ] | |
| Redirect to home after login | [ ] | |

### 1.4 Password Recovery
| Test | Status | Notes |
|------|--------|-------|
| Forgot password link works | [ ] | |
| Email input for reset | [ ] | |
| OTP/reset email sent | [ ] | |
| Password reset completes | [ ] | |

### 1.5 Onboarding Steps
| Test | Status | Notes |
|------|--------|-------|
| Terms & Conditions screen displays | [ ] | |
| Accept terms enables continue | [ ] | |
| Basic info form (name, DOB, gender) | [ ] | |
| Photo upload works | [ ] | |
| Bio text editor works | [ ] | |
| Profile setup completes | [ ] | |
| Redirect to home after onboarding | [ ] | |

---

## Phase 2: Critical - Discovery & Matching

### 2.1 Discovery Feed
| Test | Status | Notes |
|------|--------|-------|
| Discovery screen loads | [ ] | |
| Profile cards display with images | [ ] | |
| Name, age, location visible | [ ] | |
| Bio text displays | [ ] | |
| Swipe left (pass) works | [ ] | |
| Swipe right (like) works | [ ] | |
| Super like button works | [ ] | |
| Empty deck state shows | [ ] | |

### 2.2 Matching
| Test | Status | Notes |
|------|--------|-------|
| Match celebration shows on mutual like | [ ] | |
| Match appears in matches list | [ ] | |
| Can start chat from match | [ ] | |

---

## Phase 3: Critical - Chat & Messaging

### 3.1 Matches Screen
| Test | Status | Notes |
|------|--------|-------|
| Matches tab loads | [ ] | |
| All matches display | [ ] | |
| Last message preview shows | [ ] | |
| Unread badge appears | [ ] | |
| Click opens chat | [ ] | |

### 3.2 Chat Screen
| Test | Status | Notes |
|------|--------|-------|
| Chat screen loads | [ ] | |
| Message history displays | [ ] | |
| Send text message | [ ] | |
| Message appears in chat | [ ] | |
| Typing indicator shows | [ ] | |
| Read receipts work | [ ] | |
| Real-time messages arrive | [ ] | |

### 3.3 Chat Features
| Test | Status | Notes |
|------|--------|-------|
| Send image/media | [ ] | |
| Emoji support | [ ] | |
| Delete message | [ ] | |
| Report/block user | [ ] | |

---

## Phase 4: High - Profile & Settings

### 4.1 Profile View
| Test | Status | Notes |
|------|--------|-------|
| Profile tab loads | [ ] | |
| User photos display | [ ] | |
| Bio and info visible | [ ] | |
| Edit profile button works | [ ] | |

### 4.2 Profile Edit
| Test | Status | Notes |
|------|--------|-------|
| Edit mode opens | [ ] | |
| Can change photos | [ ] | |
| Can edit bio | [ ] | |
| Save changes works | [ ] | |
| Cancel discards changes | [ ] | |

### 4.3 Settings
| Test | Status | Notes |
|------|--------|-------|
| Settings screen opens | [ ] | |
| Privacy settings work | [ ] | |
| Notification settings work | [ ] | |
| Discovery filters work | [ ] | |
| Theme toggle works | [ ] | |
| Logout works | [ ] | |
| Delete account flow | [ ] | |

---

## Phase 5: High - Safety & Payments

### 5.1 Safety Features
| Test | Status | Notes |
|------|--------|-------|
| Block user works | [ ] | |
| Report user works | [ ] | |
| Date plan creation | [ ] | |
| Emergency contact notification | [ ] | |

### 5.2 Subscription
| Test | Status | Notes |
|------|--------|-------|
| Subscription screen shows | [ ] | |
| Plan options display | [ ] | |
| Payment flow initiates | [ ] | |
| Premium features unlock | [ ] | |

---

## Phase 6: Web-Specific Testing

### 6.1 Responsive Design
| Test | Status | Notes |
|------|--------|-------|
| Mobile layout (< 640px) | [ ] | |
| Tablet layout (640-1024px) | [ ] | |
| Desktop layout (> 1024px) | [ ] | |
| No horizontal scrolling | [ ] | |

### 6.2 Browser Compatibility
| Test | Status | Notes |
|------|--------|-------|
| Chrome | [ ] | |
| Firefox | [ ] | |
| Safari | [ ] | |
| Edge | [ ] | |

### 6.3 Navigation
| Test | Status | Notes |
|------|--------|-------|
| Browser back button works | [ ] | |
| Browser forward button works | [ ] | |
| Deep links work | [ ] | |
| URL updates on navigation | [ ] | |

### 6.4 Performance
| Test | Status | Notes |
|------|--------|-------|
| Page load < 3 seconds | [ ] | |
| Smooth animations | [ ] | |
| No console errors | [ ] | |
| Images load correctly | [ ] | |

---

## Test Results Summary

| Phase | Total Tests | Passed | Failed | Blocked |
|-------|-------------|--------|--------|---------|
| Phase 1: Auth | 25 | 0 | 0 | 0 |
| Phase 2: Discovery | 10 | 0 | 0 | 0 |
| Phase 3: Chat | 14 | 0 | 0 | 0 |
| Phase 4: Profile | 12 | 0 | 0 | 0 |
| Phase 5: Safety | 8 | 0 | 0 | 0 |
| Phase 6: Web | 12 | 0 | 0 | 0 |
| **TOTAL** | **81** | **0** | **0** | **0** |

---

## Issues Found

| ID | Severity | Description | Status |
|----|----------|-------------|--------|
| | | | |

---

## Notes

- Testing performed on: Chrome (version)
- Screen resolution:
- Date completed:
