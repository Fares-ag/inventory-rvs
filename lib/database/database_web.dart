// Web-specific database initialization
// NOTE: This is legacy SQLite code - not used with Firebase
// Commented out because sqflite_common_ffi_web is not compatible with current SDK
// The app now uses Firebase Firestore instead

void initDatabaseFactory() {
  // Legacy SQLite initialization - not used with Firebase
  // sqfliteFfiInit();
  // databaseFactory = databaseFactoryFfiWeb;
}

