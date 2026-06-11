# 📎 Sticky Links (v2.4.4)

A premium, modern Flutter application designed to help you organize, categorize, and preserve your most important web links with ease. Featuring a sleek UI, real-time local backups, and a powerful local API for seamless integration.

![Sticky Links Logo](app_logo.png)

## ✨ Features

- **📂 Smart Categorization**: Organize your links into custom categories. Rename, delete, or export specific categories via a right-click context menu.
- **📖 Reader Mode**: View article content in a clean, distraction-free interface directly within the app, powered by `flutter_widget_from_html`.
- **🌐 Local API Server**: Built-in HTTP server running on port `7551`. Add links remotely from browser extensions or other tools via simple POST requests.
- **🖱️ Drag & Drop**: Instantly add new links by dragging and dropping URLs or text directly onto the application window.
- **🔍 Instant Search & Shortcuts**: Rapidly find links by title, URL, or description.
    - `Ctrl + F`: Focus Search
    - `Ctrl + N`: Create New Link
    - `Ctrl + G`: Toggle Grid/List View
    - `Ctrl + B`: Trigger Manual Backup
    - `Ctrl + H`: Toggle Archive View
- **📦 Archiving & Bulk Actions**: Move links to an Archive instead of deleting them. Use long-press or selection mode to bulk archive or delete.
- **📈 Click Tracking**: Monitor which links you use the most with built-in click counting and popularity sorting.
- **🛡️ Auto-Backup System**: Your data is safe. The app performs silent background backups and triggers an instant backup the moment you make changes.
- **🎨 Custom Window & Themes**: Custom title bar (Windows) and a variety of dynamic theme color options with glassmorphism effects.
- **💾 Persistent Storage**: Powered by **Hive**, a lightweight and blazing-fast key-value database for local persistence.
- **📤 Import/Export**: Easily migrate your data by exporting or importing JSON backup files.

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (Windows & Android)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Database**: [Hive](https://pub.dev/packages/hive)
- **Networking/API**: [Shelf](https://pub.dev/packages/shelf) & [Shelf Router](https://pub.dev/packages/shelf_router)
- **Animations**: [Flutter Staggered Animations](https://pub.dev/packages/flutter_staggered_animations) & [Lottie](https://pub.dev/packages/lottie)
- **UI Components**: [ShowcaseView](https://pub.dev/packages/showcaseview), [Desktop Drop](https://pub.dev/packages/desktop_drop)
- **Window Management**: [bitsdojo_window](https://pub.dev/packages/bitsdojo_window)

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.
- **Windows**: Windows 10/11 and Visual Studio (with C++ development workload).
- **Android**: Android Studio and SDK.

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/nishtechs/Sticky-Links.git
   cd Sticky-Links
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Hive Adapters**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**:
   ```bash
   flutter run -d windows  # For Windows
   flutter run -d android  # For Android
   ```

## 🔌 Local API Usage

You can add links to Sticky Links using a simple POST request:

**Endpoint**: `POST http://localhost:7551/add`
**Body (JSON)**:
```json
{
  "url": "https://flutter.dev",
  "title": "Flutter - Build apps for any screen"
}
```

## 📁 Backup Folders

By default, the application saves your automated backups to:
`C:\Users\<YourUser>\Documents\sticky_links\backup.json` (on Windows)

You can change this path or trigger manual backups (`Ctrl+B`) at any time within the **Settings** menu.

## 🤝 Contributing

Sticky Links is an **open-source** project and contributions are welcome! Whether it's fixing bugs, adding new features, or improving documentation, feel free to:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.

---
Developed with ❤️ by [Nishant Sharma](https://github.com/nishtechs)
