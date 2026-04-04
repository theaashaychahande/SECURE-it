# 🚀 SECURE-it: Development Phases & Instructions

> [!IMPORTANT]
> Follow these sequential phases to build the SECURE-it application efficiently. Establishing a strong foundation in the backend before building the mobile app is critical.

---

## Phase 1 — Setup Everything First
- Create a new Flutter project
- Create a new Python FastAPI project in a separate folder
- Create a Firebase project on firebase.google.com
- Create a Render account on render.com *(Note: Or Google Cloud Run as decided out of band)*
- Create a Google Cloud account for Safe Browsing API key
- Get Safe Browsing API key from Google Cloud Console — free
- Set up GitHub repository with two folders — one for Flutter app, one for FastAPI backend

---

## Phase 2 — Build the Backend First
> [!NOTE]
> Build backend before app because app needs backend to function

- Create FastAPI project structure with folders — models, services, routes
- Create the risk scoring endpoint — takes UPI ID, amount, payment note and returns risk score
- Create the link scanning endpoint — takes URL and calls Google Safe Browsing API
- Create the pattern checker endpoint — checks keywords and amount patterns
- Create the auto report endpoint — sends scammer details to cybercrime portal
- Train XGBoost model on sample Indian fraud dataset from Kaggle
- Save trained model using `joblib`
- Load model into FastAPI at startup
- Set up Redis on Render for caching
- Test all endpoints locally using Postman

---

## Phase 3 — Deploy Backend
- Push FastAPI code to GitHub
- Connect GitHub repo to Render (or Google Cloud Run)
- Add environment variables on Render — API keys, Firebase credentials, Redis URL
- Deploy and get live backend URL
- Set up `cron-job.org` to ping backend every 10 minutes so it never sleeps
- Test all live endpoints once more using Postman with the Render URL

---

## Phase 4 — Set Up Firebase
- Create Firebase project
- Enable Firebase Cloud Messaging for push notifications
- Connect Firebase to Flutter app using FlutterFire CLI
- Connect Firebase to FastAPI backend using Firebase Admin SDK
- Set up Firebase database structure for scam UPI IDs collection
- Add some sample known scam UPI IDs to database for testing
- Test that FastAPI can read and write to Firebase successfully

---

## Phase 5 — Build Flutter App
> [!TIP]
> Build screens in this exact order:

- Onboarding screen — permissions setup and trusted contact saving
- Home screen — animated shield showing protection is active
- Settings screen — language selection and trusted contact management
- Overlay warning widget — the red warning card that appears over UPI apps
- Education flash card screen — shows after every blocked payment

> [!TIP]
> Then build services in this exact order:

- Accessibility service — reads UPI payment screen
- Clipboard monitor service — watches for suspicious links
- Notification listener service — reads notification previews
- Overlay service — triggers warning card over UPI apps
- Screen sharing detector service — detects AnyDesk and similar apps
- API service — connects Flutter to FastAPI backend
- Firebase service — handles push notifications

---

## Phase 6 — Connect Everything Together
- Connect Flutter accessibility service to overlay trigger
- Connect clipboard monitor to link scanner API endpoint
- Connect payment screen reader to risk scoring API endpoint
- Connect risk score result to overlay warning display
- Connect high risk result to Firebase which triggers family guardian notification
- Connect high risk result to auto crime report endpoint
- Connect blocked payment result to education flash card screen
- Test full flow end-to-end — simulate a scam payment and verify every step triggers correctly

---

## Phase 7 — Test Everything
- Test overlay appearing over GPay
- Test link scanner with a known phishing URL
- Test family guardian notification on a second phone
- Test screen sharing detector by opening AnyDesk
- Test education card appearing after blocked payment
- Test in Hindi and Marathi languages
- Fix any bugs found

---

## Phase 8 — Final Polish
- Make sure all text is large enough for elderly users
- Check all colors are consistent navy and teal throughout
- Remove all test data and hardcoded values
- Move all API keys to environment variables
- Do a final full end-to-end test
- Prepare a demo scenario for judges — one complete scam attempt blocked by the app
