# 📎 Sticky Links

A premium, modern Flutter Desktop application designed to help you organize, categorize, and preserve your most important web links with ease. Featuring a sleek UI, real-time local backups, and an intuitive user experience.

![Sticky Links Logo](app_logo.png)

## ✨ Features

- **📂 Smart Categorization**: Organize your links into custom categories. Rename, delete, or export specific categories via a right-click context menu.
- **🔍 Instant Search & Shortcuts**: Rapidly find links by title, URL, or description. Use `Ctrl+F` for search, `Ctrl+N` for new links, and `Ctrl+H` to toggle the archive.
- **📦 Archiving & Bulk Actions**: Move links to an Archive instead of deleting them. Use long-press to select multiple links for bulk archiving or deletion.
- **📈 Click Tracking**: Monitor which links you use the most with built-in click counting and popularity sorting.
- **🛡️ Auto-Backup System**: Your data is safe. The app performs silent background backups every hour and triggers an instant backup the moment you add, edit, or remove a link.
- **🎨 Custom Window & Themes**: Custom title bar and a variety of theme color options for both light and dark modes.
- **💾 Persistent Storage**: Powered by **Hive**, a lightweight and blazing-fast key-value database for local persistence.
- **✨ Animated UI**: Smooth entrance animations using `flutter_staggered_animations` for list and grid views.
- **🎓 Interactive Showcase**: Built-in tutorial walkthrough for first-time users to get started quickly.
- **📤 Import/Export**: Easily migrate your data by exporting or importing JSON backup files, with automatic category reconstruction.

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (Desktop Windows)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Database**: [Hive](https://pub.dev/packages/hive) & [Hive Flutter](https://pub.dev/packages/hive_flutter)
- **Animations**: [Flutter Staggered Animations](https://pub.dev/packages/flutter_staggered_animations)
- **Tutorials**: [ShowcaseView](https://pub.dev/packages/showcaseview)
- **Window Management**: [bitsdojo_window](https://pub.dev/packages/bitsdojo_window)
- **Icons**: [Flutter Launcher Icons](https://pub.dev/packages/flutter_launcher_icons)

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.
- Windows 10/11 for the native desktop experience.
- Visual Studio (with C++ development workload) for Windows builds.

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
   flutter run -d windows
   ```

## 📁 Backup Locations

By default, the application saves your automated backups to:
`C:\Users\<YourUser>\Documents\sticky_links\backup.json`

You can change this path at any time within the **Settings** menu.

## 📸 Screenshots

*(Add screenshots of your application here once you have them!)*

---
Developed with ❤️ using Flutter.
