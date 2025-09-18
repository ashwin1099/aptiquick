# AptiQuick 🧠📱  

**AptiQuick** is an aptitude preparation app built with Flutter. It helps students and job seekers practice for competitive exams like **TCS NQT**, **Wipro**, **Infosys**, and more. The app provides topic-wise practice, mock tests with timers, performance tracking, and even AI-powered explanations.  

---

## ✨ Features  

- 🎯 Topic-wise practice (e.g., Number System, Time & Work, Probability)  
- ⏱ Mock tests with timer and scoring  
- 🛡 Anti-cheating mode: If you switch tabs during a test, it gives 5 warnings. After that, the test auto-submits  
- 📶 Offline fallback: If internet goes down while submitting, results are saved offline and uploaded automatically when connection is back  
- 🤖 AI help: Get explanations and hints from ChatGPT, Gemini, DeepSeek, Grok, etc.  
- 📊 Performance tracking: Save scores, analyze progress, and revisit mistakes  
- 📂 Bulk upload: Add questions in bulk via JSON or admin panel  
- 📱 Cross-platform: Works on Android, iOS, and Web  
- 🔒 User profiles: Secure login, cloud backup, and offline caching  

---

## 🛠️ Tech Stack  

- **Flutter (Android, iOS, Web):** Cross-platform UI with custom widgets using a single codebase  
- **Dart:** Handles app logic, navigation, and state management  
- **Custom JSON:** Offline storage for mock tests & topics  
- **Firebase (Auth/Firestore):** Stores practice questions, test questions, user profiles, and test results  
- **SQLite:** Local cache for offline access  
- **Bulk Upload:** Import questions via JSON or admin panel  
- **AI Integration:** LLMs for auto-generated explanations & hints  

---

## 📁 Folder Structure

```
AptiQuick/
├── android/           # Android-specific code
├── assets/            # Fonts, images, question data
├── ios/               # iOS-specific code
├── lib/               # Flutter app source code
├── test/              # Test cases
├── web/               # Web support
├── pubspec.yaml       # Dependencies & assets
├── README.md          # This file
```

---

## 🚀 Getting Started

1. Clone the repo  
   ```bash
   git clone https://github.com/ashwin1099/AptiQuick.git
   cd AptiQuick
   ```

2. Get dependencies  
   ```bash
   flutter pub get
   ```

3. Run the app  
   ```bash
   flutter run
   ```

---


## 📸 Screenshots

### 🏠 Home Screen  
<img src="assets/screenshots/Homescreen.jpg" alt="Home Screen" width="400"/>

### 🧪 Live Test  
<img src="assets/screenshots/LiveTest.jpg" alt="Live Test" width="400"/>

### 📚 Practice Questions  
<img src="assets/screenshots/PracticeQuestions.jpg" alt="Practice Questions" width="400"/>

### 📊 Results Page  
<img src="assets/screenshots/ResultsPage.jpg" alt="Results Page" width="400"/>

### 🧠 Topic Selection  
<img src="assets/screenshots/Topics.jpg" alt="Topics" width="400"/>


---



Made with ❤️ using Flutter by Ashmin Saurav.
