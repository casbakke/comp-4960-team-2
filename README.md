# Campus Lost and Found Portal | Wentworth Institute of Technology

A cross-platform Lost & Found application for WIT with iOS, web, and backend components.

## Project Structure

- **iOS/** - Native iOS app (Swift)
- **lostandfound/frontend/** - React web app
- **lostandfound/backend/** - Node.js/Firebase backend

## Accessing the Deployed Apps

### iOS App (TestFlight Beta)
The iOS app is available for beta testing through TestFlight:
- **Link:** https://testflight.apple.com/join/9rKVNquy

**Note:** The public link will not work until the app has passed Apple's "Beta App Review". The review is expected to be complete by December 9th, but there are no guarantees of that date or if the app will pass. If you would like immediate access to the beta, please reach out to **bakkec@wit.edu** to request a private invitation.

### Web App
Visit the deployed web app at: https://wit-campus-lost-and-found.web.app/ and sign in with your Wentworth Microsoft account (@wit.edu).

## Local Development

### iOS
```bash
# Download the `GoogleService-Info.plist` file from Firebase Console
# Place it at: `iOS/LostAndFound/LostAndFound/GoogleService-Info.plist`

cd iOS/LostAndFound
open LostAndFound.xcodeproj
```



To run the iOS app locally, you'll need to be running MacOS with the Xcode IDE installed.

### Frontend (React)
```bash
cd lostandfound/frontend
npm install
npm start
```

### Backend
```bash
cd lostandfound/backend
npm install
npm run dev
```

These commands will run the web app locally


