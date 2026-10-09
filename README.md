# 📍 Live Location Share

A real-time location sharing application built with **Flutter**. This app allows users to see their live location on a map, share it with others, and view multiple users seamlessly on an interactive map.

## ✨ Features

- **Real-Time Location Tracking:** Uses the device's GPS to continuously update and display the user's location.
- **Interactive Map:** Beautiful map interface powered by `flutter_map` and OpenStreetMap.
- **Location Sharing:** Seamlessly share your live coordinates with other users in the hub.
- **State Management:** Efficient and scalable state management using `provider`.
- **Smooth Animations:** Includes `flutter_animate` for a polished UI experience.
- **Cross-Platform:** Works on Android, iOS, and Web.

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Maps:** `flutter_map` (OpenStreetMap integration)
- **Geolocation:** `geolocator`
- **State Management:** `provider`
- **Local Storage:** `shared_preferences`
- **Networking:** `http`

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing.

### Prerequisites

You need to have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.12.0 or higher)
- Android Studio or Xcode (for emulation/builds)
- VS Code (optional, but recommended)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Haridh432/Location_Sharing_App.git
   ```

2. **Navigate to the project directory:**
   ```bash
   cd Location_Sharing_App
   ```

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the app:**
   Connect a device or start an emulator, then run:
   ```bash
   flutter run
   ```

## 📂 Project Structure

```text
lib/
 ┣ models/           # Data models (e.g., user_model.dart)
 ┣ providers/        # State management (e.g., location_provider.dart)
 ┣ screens/          # UI Screens (Home, Map, Username, etc.)
 ┣ services/         # API, location, and storage services
 ┗ main.dart         # Entry point of the application
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/Haridh432/Location_Sharing_App/issues) if you want to contribute.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is open-source and available under the standard MIT License.
