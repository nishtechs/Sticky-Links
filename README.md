# Sticky Links

A Flutter desktop application for managing and organizing your favorite links in a sticky note style interface.

## Features

- Add links with custom titles
- View all saved links in a clean card-based interface
- Remove links when no longer needed
- Simple and intuitive user interface

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Windows 10/11 (for Windows desktop support)

### Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   ```

2. Navigate to the project directory:
   ```
   cd sticky_links
   ```

3. Enable Windows desktop support:
   ```
   flutter config --enable-windows-desktop
   ```

4. Get dependencies:
   ```
   flutter pub get
   ```

### Running the Application

To run the application on Windows desktop:

```
flutter run -d windows
```

To build a release version:

```
flutter build windows
```

The executable will be located at `build\windows\x64\runner\Release\sticky_links.exe`

## Project Structure

- `lib/main.dart` - Main application entry point and UI implementation
- `pubspec.yaml` - Project dependencies and configuration

## Dependencies

- Flutter SDK
- Dart SDK

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
