# BMU Student Placement Portal — Frontend

A premium, highly aesthetic, and responsive Flutter Web client designed for the BML Munjal University (BMU) Student Placement Portal. The application utilizes modern design practices such as glassmorphism, rich gradients, and custom dark mode themes.

---

## 🎨 Design System & Visuals

The UI focuses on providing a dark space theme built around high-fidelity visuals:
*   **Background Colors**: Deep dark space backdrop (`#0F0C1B`) to `#201A30` and `#140D24` gradients.
*   **Accent Gradients**: Neon Indigo (`#6366F1`) and Purple (`#8B5CF6`) gradients for buttons, hover elements, and highlight rings.
*   **Card Styling**: Glassmorphic panels featuring container opacity blending (`0x33FFFFFF`), subtle inner shadows, and white borders with alpha transparency to emulate frosted glass.
*   **Typography**: Clean sans-serif hierarchy using the `Roboto` font family.

---

## 📁 Project Structure

```text
placement-portal-frontend/
├── assets/
│   └── fonts/                     # Roboto-Regular.ttf and Roboto-Bold.ttf local files
├── lib/
│   ├── main.dart                  # Theme declarations, MaterialApp settings, and initial routing
│   └── views/
│       └── auth/                  # Authentication View Components
│           ├── login_screen.dart           # Glassmorphic Login with unverified email check
│           ├── signup_screen.dart          # Register screen with Student/Recruiter toggle
│           ├── forgot_password_screen.dart # Recovery interface
│           └── otp_verification_screen.dart# 6-digit OTP layout with countdown timers
├── web/
│   ├── canvaskit/                 # Local CanvasKit files (wasm + js) for offline execution
│   ├── flutter_bootstrap.js       # Bypasses network resets by pointing loading parameters locally
│   └── index.html
└── pubspec.yaml                   # Flutter package manifest & font asset registration
```

---

## 📱 Screens & User Journeys

### 1. Login Screen (`/login`)
*   Includes validation for `@bmu.edu.in` emails.
*   Triggers password visibility toggles.
*   If the login API returns an `"Email not verified"` error, the screen intercepts this and forwards the user to the OTP verification view after 1.5 seconds.

### 2. Signup Screen (`/signup`)
*   Features a sleek segment selector to switch registration forms between **STUDENT** and **RECRUITER**.
*   Requires matching password confirmation and validation fields.
*   Redirects instantly to the OTP screen upon a successful register call.

### 3. OTP Verification Screen (`/verify-otp`)
*   Renders a central 6-digit numerical entry block.
*   Displays validation notifications in case of wrong entries or service failures.
*   Maintains an active 30-second resend countdown timer using a standard periodic Timer callback.
*   Handles resending calls asynchronously while restricting spam requests.

### 4. Forgot Password Screen (`/forgot-password`)
*   Provides email retrieval entry field.
*   Presents mock verification notification on submittal.

---

## 🔧 Workarounds for Restricted Environments

During execution under strict firewalls or offline networks, Flutter Web CanvasKit might fail to fetch WASM engines and font assets from Google hosts (`www.gstatic.com`). To combat this:
1.  **CanvasKit engine files** are stored locally under `web/canvaskit/`.
2.  **Font files** are kept under `assets/fonts/` and registered locally in `pubspec.yaml`.
3.  **Bootloader configuration** inside `web/flutter_bootstrap.js` directs the loaders to read from local paths:
    ```javascript
    _flutter.loader.load({
      config: {
        canvasKitBaseUrl: "canvaskit/",
      },
      onEntrypointLoaded: async function(engineInitializer) {
        const appRunner = await engineInitializer.initializeEngine({
          canvasKitBaseUrl: "canvaskit/",
          fontFallbackBaseUrl: "assets/fonts/"
        });
        await appRunner.runApp();
      }
    });
    ```
4.  **Git Attributes**: A root `.gitattributes` configuration enforces `*.ttf binary` checks to ensure these binary fonts do not corrupt during Windows CRLF checkouts.

---

## 🚀 Execution & commands

### Fetch Packages
```bash
flutter pub get
```

### Run Client locally
Run on Google Chrome browser:
```bash
flutter run -d chrome
```

### Static Analysis
Verify code syntax consistency and look for rules violations:
```bash
flutter analyze
```
