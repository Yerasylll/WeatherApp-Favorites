# Weather App with Firebase Integration - Assignment 8


**Student:** Yerasyl Alimbek  
**Platform:** iOS (Swift/SwiftUI)  

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Learning Goals Achieved](#learning-goals-achieved)
3. [Features](#features)
4. [Firebase Setup](#firebase-setup)
5. [Data Model](#data-model)
6. [Security Rules](#security-rules)
7. [Architecture](#architecture)
8. [Installation & Setup](#installation--setup)
9. [Usage Guide](#usage-guide)
10. [Technical Implementation](#technical-implementation)
11. [Screenshots & Evidence](#screenshots--evidence)
12. [Challenges & Solutions](#challenges--solutions)
13. [Future Enhancements](#future-enhancements)

---

## Project Overview

This project extends the Weather App from Assignment 7 by adding a **Favorites & Notes** module backed by Firebase Realtime Database. Users can authenticate (anonymously or via email/password), save their favorite cities with personal notes, and see real-time updates across all their devices.

### Key Technologies
- **Platform:** iOS 16.0+
- **Language:** Swift 5.9
- **UI Framework:** SwiftUI
- **Backend:** Firebase Realtime Database
- **Authentication:** Firebase Anonymous Auth & Email/Password Auth
- **Weather API:** OpenWeatherMap API (replaced Open-Meteo for better geocoding)
- **Architecture:** MVVM with Repository Pattern

---

## Learning Goals Achieved

**Firebase Configuration:** Successfully integrated Firebase SDK using Swift Package Manager  
**Cloud Data Model:** Designed per-user data structure with proper indexing  
**CRUD Operations:** Implemented Create, Read, Update, and Delete with proper error handling  
**Real-time Listeners:** UI updates automatically when data changes in Firebase  
**Security Rules:** Implemented authentication-based access control  
**App Integration:** Seamlessly integrated Firebase with existing Weather App features

---

## Features

### Core Features
1. **Weather Information**
   - Search any city worldwide (automatic geocoding via OpenWeatherMap)
   - Current weather with temperature, humidity, wind speed
   - 3-day forecast
   - Hourly forecast data
   - Temperature unit toggle (Celsius/Fahrenheit)
   - Offline caching support

2. **User Authentication**
   - Anonymous sign-in (quick guest access)
   - Email/Password authentication
   - Persistent authentication state
   - Sign out functionality

3. **Favorites Management**
   - Add cities to favorites with custom notes
   - Real-time synchronization across devices
   - Edit notes for existing favorites
   - Delete favorites with swipe gesture
   - View detailed weather for favorite cities
   - Automatic coordinates storage

4. **Real-time Updates**
   - Instant UI updates when data changes
   - Multi-device synchronization
   - No manual refresh required
   - Firebase value observers

---

## Firebase Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and name it (e.g., "WeatherApp-Favorites")
3. Disable Google Analytics (optional for this project)
4. Click "Create project"

### Step 2: Add iOS App to Firebase

1. In Firebase Console, click "Add app" → iOS
2. Enter your Bundle ID: `com.yourname.WeatherApp-Favorites`
3. Download `GoogleService-Info.plist`
4. Drag the file into Xcode project (root level, alongside `Info.plist`)
5. Ensure "Copy items if needed" is checked

### Step 3: Install Firebase SDK

Using Swift Package Manager:
1. In Xcode: File → Add Package Dependencies
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: 10.20.0 or later
4. Add packages:
   - FirebaseAuth
   - FirebaseDatabase

### Step 4: Enable Authentication Methods

1. In Firebase Console → Authentication → Sign-in method
2. Enable **Anonymous** authentication
3. Enable **Email/Password** authentication
4. Save changes

### Step 5: Create Realtime Database

1. In Firebase Console → Realtime Database → Create Database
2. Choose location (e.g., us-central1)
3. Start in **Test mode** (we'll add rules later)
4. Database URL: `https://[your-project-id].firebaseio.com`

### Step 6: Configure Security Rules

See [Security Rules](#security-rules) section below for the final rules configuration.

---

## Data Model

### Database Structure

```json
{
  "users": {
    "USER_UID_123": {
      "favorites": {
        "FAVORITE_ID_1": {
          "id": "FAVORITE_ID_1",
          "name": "Almaty",
          "note": "Best time to visit: May-September",
          "createdAt": 1707318600.0,
          "createdBy": "USER_UID_123",
          "latitude": 43.2389,
          "longitude": 76.8897
        },
        "FAVORITE_ID_2": {
          "id": "FAVORITE_ID_2",
          "name": "London",
          "note": "Bring umbrella always!",
          "createdAt": 1707318750.0,
          "createdBy": "USER_UID_123",
          "latitude": 51.5074,
          "longitude": -0.1278
        }
      }
    },
    "USER_UID_456": {
      "favorites": {
        "FAVORITE_ID_3": {
          "id": "FAVORITE_ID_3",
          "name": "Tokyo",
          "note": "Cherry blossoms in April",
          "createdAt": 1707318900.0,
          "createdBy": "USER_UID_456",
          "latitude": 35.6762,
          "longitude": 139.6503
        }
      }
    }
  }
}
```

### FavoriteCity Model (Swift)

```swift
struct FavoriteCity: Codable, Identifiable {
    let id: String              // Unique identifier (UUID)
    let name: String            // City name
    let note: String?           // Optional user note
    let createdAt: Date         // Timestamp
    let createdBy: String       // User UID
    let latitude: Double        // City latitude
    let longitude: Double       // City longitude
}
```

### Data Model Design Rationale

1. **Per-User Structure:** Each user's favorites are stored under their UID for security and scalability
2. **Denormalization:** City coordinates are stored with favorites to avoid additional API calls
3. **Timestamps:** `createdAt` enables sorting by recency
4. **Optional Notes:** Users can add personal context to their favorite cities
5. **Unique IDs:** UUID ensures no collision across users

---

## Security Rules

### Firebase Realtime Database Rules

```json
{
  "rules": {
    "users": {
      "$uid": {
        "favorites": {
          ".read": "auth != null && auth.uid == $uid",
          ".write": "auth != null && auth.uid == $uid",
          "$favoriteId": {
            ".validate": "newData.hasChildren(['id', 'name', 'createdAt', 'createdBy', 'latitude', 'longitude']) && newData.child('createdBy').val() == auth.uid"
          }
        }
      }
    }
  }
}
```

### Rules Explanation

1. **Authentication Required:**
   - `auth != null` - Only authenticated users can access data
   - Prevents anonymous/public access to the database

2. **User Isolation:**
   - `auth.uid == $uid` - Users can only access their own favorites
   - Prevents users from reading or modifying other users' data

3. **Data Validation:**
   - `.validate` - Ensures all required fields are present
   - Verifies `createdBy` matches the authenticated user's UID
   - Prevents users from creating favorites under another user's identity

4. **Write Protection:**
   - Users cannot write to other users' paths
   - Each user has a private namespace under `/users/{uid}/favorites/`

### Testing Security Rules

You can test these rules in the Firebase Console:
1. Go to Realtime Database → Rules → Playground
2. Test read/write operations with different authentication states
3. Verify unauthorized access is denied

---

## Architecture

### Overview

The app follows **MVVM (Model-View-ViewModel)** architecture with a **Repository Pattern** for data access.

```
┌─────────────────────────────────────────────────────────────┐
│                          Views                               │
│  (SwiftUI) - FavoritesView, WeatherView, AddFavoriteView   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ @StateObject / @ObservedObject
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      ViewModels                              │
│        WeatherViewModel, FirebaseRepository                 │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ Calls services
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                       Services                               │
│    AuthenticationService, WeatherService, CacheManager      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ API calls / Firebase SDK
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    External Services                         │
│         Firebase Realtime Database, OpenWeatherMap API      │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

#### 1. Models
- **FavoriteCity:** Data model for favorite cities
- **WeatherResponse:** Weather data from OpenWeatherMap API
- **CurrentWeather, DailyForecast, HourlyForecast:** Weather detail models

#### 2. Services
- **AuthenticationService:** Singleton managing Firebase Authentication
  - Anonymous sign-in
  - Email/Password authentication
  - Auth state management
  
- **WeatherService:** Handles OpenWeatherMap API calls
  - Automatic city geocoding
  - Current weather fetching
  - Forecast data retrieval
  
- **CacheManager:** Local weather data caching
  - Offline support
  - 1-hour cache validity

#### 3. Repository
- **FirebaseRepository:** Manages all Firebase Realtime Database operations
  - CRUD operations for favorites
  - Real-time listeners
  - Data synchronization

#### 4. Views
- **MainTabView:** Tab-based navigation
- **WeatherView:** Weather search and display
- **FavoritesView:** List of favorite cities
- **AddFavoriteView:** Add new favorite with preview
- **FavoriteDetailView:** Detailed view of a favorite city
- **EditNoteView:** Edit notes for favorites

### Separation of Concerns

**No Firebase logic in UI:** All database operations are in `FirebaseRepository`  
**No UI logic in services:** Services only handle data operations  
**Single Responsibility:** Each class has one clear purpose  
**Dependency Injection:** Views receive repository instances, not creating them

---

## Installation & Setup

### Prerequisites
- macOS 13.0+ with Xcode 15.0+
- iOS 16.0+ device or simulator
- Firebase account
- OpenWeatherMap API key (free tier)

### Step-by-Step Setup

#### 1. Clone Repository
```bash
git clone https://github.com/yourusername/WeatherApp-Favorites.git
cd WeatherApp-Favorites
```

#### 2. Configure Firebase
1. Add your `GoogleService-Info.plist` to the project root
2. Verify it's included in the target (check Target Membership in Xcode)

#### 3. Get OpenWeatherMap API Key
1. Sign up at https://openweathermap.org/api
2. Get your free API key from the dashboard
3. Open `WeatherService.swift`
4. Replace `YOUR_API_KEY_HERE` with your actual API key:
```swift
private let apiKey = "your_actual_api_key_here"
```

#### 4. Install Dependencies
Dependencies are managed via Swift Package Manager and should be automatically resolved by Xcode:
- Firebase iOS SDK (FirebaseAuth, FirebaseDatabase)

If dependencies don't resolve:
1. File → Packages → Resolve Package Versions
2. Product → Clean Build Folder
3. Rebuild project

#### 5. Run the App
1. Select a simulator or connected device
2. Press Cmd+R or click the Play button
3. App should launch successfully

---

## Usage Guide

### First Launch

1. **Weather Tab:**
   - Enter any city name (e.g., "Almaty", "London", "Tokyo")
   - Press the search button (magnifying glass)
   - View current weather and 3-day forecast
   - Toggle temperature units in settings (gear icon)

2. **Favorites Tab:**
   - You'll see a "Sign In Required" screen
   - Choose authentication method:
     - **Quick Start:** Tap "Sign In Anonymously"
     - **Full Account:** Tap "Sign In with Email" and create an account

### Adding Favorites

1. After signing in, tap the **+ button** in Favorites tab
2. Enter a city name (must match a valid city)
3. Wait for weather preview to load
4. Optionally add a note (e.g., "Best in summer")
5. Tap **Save**
6. City appears in your favorites list instantly

### Managing Favorites

- **View Details:** Tap any favorite to see full weather and info
- **Edit Note:** In detail view, tap "Edit Note" button
- **Delete:** Swipe left on a favorite and tap "Delete"
- **Sync:** Changes sync in real-time across all your devices

### Real-time Sync Demo

**To see real-time updates:**
1. Run the app on two simulators or devices with the same account
2. Add a favorite on Device 1
3. Watch it appear instantly on Device 2 (no refresh needed!)
4. Edit or delete on either device
5. Changes appear immediately on the other

---

## Technical Implementation

### Authentication Flow

```swift
// Anonymous Authentication
func signInAnonymously() async throws {
    let result = try await Auth.auth().signInAnonymously()
    self.user = result.user
    self.isAuthenticated = true
}

// Email/Password Authentication
func signIn(email: String, password: String) async throws {
    let result = try await Auth.auth().signIn(withEmail: email, password: password)
    self.user = result.user
    self.isAuthenticated = true
}
```

### CRUD Operations

#### Create
```swift
func addFavorite(city: String, note: String?, coordinates: (lat: Double, lon: Double)) async throws {
    guard let userId = userId else { throw FirebaseError.unauthenticated }
    guard let favoritesRef = userFavoritesPath() else { throw FirebaseError.invalidReference }
    
    let favorite = FavoriteCity(
        name: city,
        note: note,
        createdBy: userId,
        latitude: coordinates.lat,
        longitude: coordinates.lon
    )
    
    try await favoritesRef.child(favorite.id).setValue(favorite.dictionary)
}
```

#### Read (Real-time Listener)
```swift
func startListening() {
    guard let favoritesRef = userFavoritesPath() else { return }
    
    handle = favoritesRef.observe(.value) { [weak self] snapshot in
        var cities: [FavoriteCity] = []
        
        for child in snapshot.children {
            if let snapshot = child as? DataSnapshot,
               let dict = snapshot.value as? [String: Any],
               let city = FavoriteCity(dictionary: dict) {
                cities.append(city)
            }
        }
        
        DispatchQueue.main.async {
            self?.favoriteCities = cities.sorted { $0.createdAt > $1.createdAt }
        }
    }
}
```

#### Update
```swift
func updateFavorite(id: String, note: String?) async throws {
    guard let favoritesRef = userFavoritesPath() else { throw FirebaseError.invalidReference }
    
    let updates: [String: Any] = ["note": note ?? ""]
    
    try await withCheckedThrowingContinuation { continuation in
        favoritesRef.child(id).updateChildValues(updates) { error, _ in
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume()
            }
        }
    }
}
```

#### Delete
```swift
func deleteFavorite(id: String) async throws {
    guard let favoritesRef = userFavoritesPath() else { throw FirebaseError.invalidReference }
    
    try await withCheckedThrowingContinuation { continuation in
        favoritesRef.child(id).removeValue { error, _ in
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume()
            }
        }
    }
}
```

### Real-time Listener Management

The app uses Firebase's `.observe(.value)` to listen for changes:

1. **Start Listening:** When user authenticates and enters Favorites tab
2. **Handle Changes:** Callback fires whenever data changes in Firebase
3. **Update UI:** Main thread updates the `@Published` array
4. **SwiftUI Reacts:** Views automatically refresh via Combine
5. **Stop Listening:** When user signs out or leaves Favorites tab

### Weather API Integration

```swift
func fetchWeather(for city: String, units: TemperatureUnit) async throws -> WeatherResponse {
    // 1. Fetch current weather (includes coordinates)
    let currentWeather = try await fetchCurrentWeather(city: city, units: units)
    
    // 2. Fetch forecast using coordinates
    let forecast = try await fetchForecast(
        lat: currentWeather.coord.lat,
        lon: currentWeather.coord.lon,
        units: units
    )
    
    // 3. Convert and combine data
    return WeatherResponse(
        current: convertToCurrentWeather(currentWeather),
        daily: convertToDailyForecast(forecast),
        hourly: convertToHourlyForecast(forecast),
        name: currentWeather.name,
        coord: WeatherResponse.Coordinates(
            lat: currentWeather.coord.lat,
            lon: currentWeather.coord.lon
        )
    )
}
```

---


### 5. Real-time Sync Evidence

**Console Logs:**
```
Firebase configured successfully
User already signed in: xYz123AbC456
Starting Firebase listener on: users/xYz123AbC456/favorites
Firebase listener triggered
Total favorites found: 3
UI updated with 3 favorites

Attempting to save favorite: Tokyo
Coordinates: (35.6762, 139.6503)
Calling repository.addFavorite...
Favorite saved to Firebase: Tokyo
Firebase listener triggered
Added: Tokyo
Total favorites found: 4
UI updated with 4 favorites
```

### 6. Multi-Device Demo

**Video Evidence:** [Link to demo video showing real-time sync between two simulators]

In the video, you can see:
1. Two iPhone simulators running the app with the same account
2. Adding a favorite on Simulator 1
3. The favorite instantly appearing on Simulator 2
4. Editing a note on Simulator 2
5. The updated note appearing on Simulator 1 within 1 second

---


## Future Enhancements

### Planned Features
1. **Push Notifications:** Alert users when weather changes significantly in favorite cities
2. **Weather Alerts:** Notify for severe weather conditions
3. **Sharing:** Share favorite cities and notes with friends
4. **Weather History:** Track weather trends for favorite cities over time
5. **Widget Support:** Home screen widget showing favorites' weather
6. **Siri Integration:** "Hey Siri, what's the weather in my favorite cities?"
7. **Multiple User Profiles:** Switch between work/personal favorite lists
8. **Import/Export:** Backup and restore favorites list

### Technical Improvements
1. **Pagination:** For users with 50+ favorites
2. **Search/Filter:** Search within favorites list
3. **Sorting Options:** By name, date added, temperature
4. **Analytics:** Track which cities are most popular
5. **Error Retry Logic:** Automatic retry on network failures
6. **Unit Tests:** Comprehensive test coverage for repository and services
7. **UI Tests:** Automated UI testing for critical flows

---

**Use of AI/External Resources:**
- Used Claude AI assistant for debugging the "favorites not saving" issue
- Consulted Firebase documentation for real-time listener implementation
- Referenced OpenWeatherMap API documentation for geocoding integration
- All code was written and understood by the student
- AI suggestions were reviewed, modified, and integrated thoughtfully

**Original Work:**
- Architecture design is original
- UI/UX implementation is original
- Integration strategy is original
- All debugging and problem-solving was student-led


**Repository Link:** https://github.com/Yerasylll/WeatherApp-Favorites.git

