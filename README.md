# Quick WiFi Share

**Quick WiFi Share** is a cross-platform file-sharing application built with Flutter. It allows users to instantly turn their device into a local FTP server and provides a Web Share Portal for easy file access over the local network.

## Key Features

- **Cross-Platform Compatibility**: Fully engineered to run natively on Android, iOS, Windows, and Linux.
- **Web Share Portal**: A built-in web server running on port `8080` that allows clients to browse, search, and download files directly via a web browser.
  - Supports Grid and List views.
  - Client-side search and filtering.
- **Background FTP Server**: A reliable backend FTP server running on port `2121`. On mobile devices, it utilizes background services to keep the connection alive while the app is minimized.
- **Hardware Monitoring**: Tracks real-time **Data Usage** (bytes transferred via both FTP and Web) and **Storage Capacity** of the host device.
- **File Management**: Create folders, delete files, and manage directories directly from the host application.
- **QR Code Scanning**: Seamlessly share connections with other devices on the network by allowing them to scan a generated QR code.

## Getting Started

### Prerequisites
- Flutter SDK (`^3.11.0` or higher)
- For Linux Desktop compiling: `sudo apt-get install clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev lld`

### Installation & Run

1. Clone this repository.
2. Fetch packages:
   ```bash
   flutter pub get
   ```
3. Run on your desired platform:
   ```bash
   # Android / iOS
   flutter run
   
   # Linux Desktop
   flutter run -d linux
   
   # Windows Desktop
   flutter run -d windows
   ```

### Troubleshooting
If you use Linuxbrew (Homebrew for Linux) and encounter a missing `gtk+-3.0` error during `flutter run -d linux`, point your `pkg-config` path back to your system libraries by executing:
```bash
export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH
```

---
*Built with Flutter.*
