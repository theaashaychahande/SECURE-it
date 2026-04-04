# 🛡️ SECURE-it: Product Requirements Document

> [!IMPORTANT]  
> **SECURE-it** is the only invisible anti-scam payment protector that sits on top of ALL UPI apps simultaneously (GPay, PhonePe, Paytm), designed specifically to safeguard elderly and digitally unaware Indian users. It works *proactively*—before the money is sent.

---

##  What Makes Us Unique
- **Universal Protection:** Operates on top of *every single* UPI app simultaneously without needing modifications to any of them.
- **Holistic Context Connection:** We link the entire scam journey—from a suspicious message to a fake link, down to the unusual payment—into one consolidated risk decision. Nobody else does this.
- **Proactive Intervention:** We work *before* money is sent. Every other solution is reactive.
- **Localized AI:** Our model is trained exclusively on Indian scam patterns (fake KYC, fake TRAI calls, fake lottery), not generic global data.
- **Crowdsourced Shield:** When one user gets scammed and reports it, *every* other user on the network is instantly protected against that same scammer.

##  What Makes Us Practical
- **Zero Friction:** The user does absolutely nothing. No settings to configure, no manual scanning, no technical knowledge needed.
- **Highly Accessible:** Fully functional on cheap, low-end Android smartphones commonly used by the elderly.
- **Regional Languages:** Warnings are displayed in Hindi, Marathi, and Gujarati so elderly users actually understand them.
- **Lightning Fast:** The entire risk check runs silently in under **500 milliseconds**—the user does not even notice it running.
- **Offline Capabilities:** Core basic checks still function securely without a fast internet connection.

##  How We Differ from Existing Solutions
- **Telecom Companies:** Block fake websites... **We:** Block fake *payments*.
- **Google Safe Browsing:** Warns about links... **We:** Warn about the *full transaction context*.
- **Banks:** Detect fraud *after* transfer... **We:** Detect *before* transfer.
- **Existing Fraud Apps:** Scan only links... **We:** Scan links + user behavior + UPI ID + payment patterns simultaneously.

---

## ✨ The 8 Core Features

### 1. Warning Popup 
When you are about to make a risky payment, a big red warning appears on-screen overlaying GPay or PhonePe to immediately halt the transaction.

### 2. Link Scanner 
Automatically and silently scans any suspicious link you received *before* opening a payment app.

### 3. AI Risk Score 
Assigns every payment a definitive score from 0 to 100 based on how risky the live transaction looks.

### 4. Pattern Checker 
Checks if the UPI ID is known for scams, if the amount is unusually large, or if the payment note contains suspicious trigger words.

### 5. Family Guardian 
Sends an instant push notification to your trusted family member the moment a high-risk payment is detected.

### 6. Auto Crime Report 
Automatically reports the scammer to the government cybercrime portal (1930) without the user having to do anything.

### 7. Screen Sharing Detector 
Detects if someone is remotely controlling your phone and immediately blocks all payment functionality.

### 8. Scam Education Card 
After every blocked scam, shows you a simple, illustrative card explaining exactly the type of trick that was just tried on you.

---

##  Tech We Are Using
- **Flutter:** The cross-platform app framework.
- **Python FastAPI:** The brain on the server handling high-speed risk checks.
- **Firebase:** Real-time database and instant push alerts.
- **XGBoost:** The machine learning AI model that scores transaction risk.
- **Google Safe Browsing API:** Scans inputted or detected links securely.
- **Google Cloud Run:** Hosts our backend server efficiently and for free *(specifically avoiding Render)*.

---

##  What the App Looks Like
- **Color Palette:** Dark navy blue and teal colors.
- **Aesthetic:** Professional design, built to look like a premium banking application.
- **Accessibility:** Extra-large typography customized for elderly users.
- **Multilingual Support:** Functions natively in English, Hindi, and Marathi.
- **Home Screen:** Features an animated, protective shield indicating active status.

---

## 🔐 How Data is Kept Safe

> [!WARNING]  
> User trust and data privacy are non-negotiable. 

- **Zero Persistence:** Nothing sensitive is permanently stored on the device.
- **Encrypted Transmission:** All data is sent heavily encrypted.
- **Auto-Purge:** Data is deleted immediately off servers right after the risk check concludes.
- **Absolute Privacy:** SECURE-it never reads, parses, or stores passwords or OTPs at any time.
