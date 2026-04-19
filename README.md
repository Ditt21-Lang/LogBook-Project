# 📘 Logbook App + Vision Filter

Aplikasi mobile berbasis Flutter untuk mencatat aktivitas (logbook) dengan dukungan **offline-first system** serta fitur tambahan **camera processing & image filtering**.

---

## 🚀 Features

### 📒 Logbook System

* ✏️ Create, Read, Update, Delete (CRUD) log
* 🔍 Search log berdasarkan judul & deskripsi
* 🏷️ Kategori log:

  * Electronic
  * Mechanical
  * Software
* 🌐 Mode Public / Private log
* ⚡ Offline-first (data tetap tersimpan tanpa internet)
* 🔄 Auto sync ke MongoDB saat online
* 🧠 Queue system untuk pending operations (insert, update, delete)

---

### 📷 Vision Camera & Image Processing

* 📸 Capture foto langsung dari kamera
* 🧩 Preview hasil sebelum disimpan
* 🎛️ Filter pilihan via dropdown:

  * Original
  * Low Pass (Blur)
  * Gaussian Blur
  * High Pass (Edge Detection)
  * Mean Filter
  * Median Filter
  * Histogram Equalization
* 👁️ Toggle overlay detection (mock detection system)
* 🔦 Flashlight control

---

## 🏗️ Tech Stack

* **Frontend**: Flutter
* **Local Storage**: Hive (Offline-first)
* **Cloud Database**: MongoDB Atlas
* **Camera**: Camera Plugin (CameraX Android)
* **State Management**: ValueNotifier
* **Image Processing**: image package (Dart)

---

## ⚙️ Installation Guide

### 1. Clone Repository

```bash
git clone https://github.com/username/logbook_app.git
cd logbook_app
```

---

### 2. Install Dependencies

```bash
flutter pub get
```

---

### 3. Setup Hive (Local Database)

Pastikan adapter sudah digenerate:

```bash
flutter pub run build_runner build
```

---

### 4. Konfigurasi MongoDB

Edit file:

```
lib/services/mongo_services.dart
```

Isi connection string MongoDB Atlas kamu:

```dart
final db = Db("mongodb+srv://<username>:<password>@cluster.mongodb.net/db_name");
```

---

### 5. Run Aplikasi

```bash
flutter run
```

---

## 📂 Project Structure

```
lib/
│
├── features/
│   ├── auth/              # Login system
│   ├── logbook/          # Logbook module
│   └── vision/           # Camera & image processing
│
├── services/
│   ├── mongo_services.dart
│   └── access_control_services.dart
│
├── helpers/
│   └── log_helper.dart
│
└── main.dart
```

---

## 🧠 Architecture

### 🔹 Offline-First Strategy

1. Data disimpan ke Hive (local)
2. UI langsung update (instant feedback)
3. Sync ke MongoDB (background)
4. Jika gagal → masuk queue
5. Akan retry saat online

---

### 🔹 Vision System Architecture

* **Layer 1**: Camera Preview (real-time)
* **Layer 2**: Overlay (Custom Painter)
* **Controller**: Handle camera & processing
* **Preview Page**: Apply filter dynamically

---

## 🧪 Filters Explanation

| Filter                 | Fungsi                     |
| ---------------------- | -------------------------- |
| Low Pass               | Blur / smoothing           |
| Gaussian               | Blur lebih halus           |
| High Pass              | Deteksi edge               |
| Mean                   | Average smoothing          |
| Median                 | Remove noise (salt-pepper) |
| Histogram Equalization | Improve contrast           |

---

## ⚠️ Known Issues

* Band-pass filter dinonaktifkan (hasil terlalu gelap)
* High-pass bisa menghasilkan gambar gelap (perlu brightness adjustment)
* Pastikan permission camera aktif di device

---

## 🔐 Permissions Required

### Android

Tambahkan di `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

---

## 👨‍💻 Author

Developed by **Gilang Sumarna**
Teknik Informatika 🎓

---

## 💡 Future Improvements

* 🔥 Real-time object detection (YOLO / TFLite)
* ☁️ Background sync service
* 📊 Statistik log activity
* 🎨 UI/UX enhancement

---

## 📜 License

This project is for educational purposes.
