import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../models/product.dart';
import '../models/product_variant.dart';
import '../models/location.dart';
import '../models/stock.dart';
import '../models/stock_movement.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    
    if (kIsWeb) {
      // For web, use a simple path
      path = filePath;
    } else {
      // For mobile/desktop, use the standard database path
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    final db = await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
    
    // Ensure default user exists (for both new and existing databases)
    await _ensureDefaultUser(db);
    
    return db;
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Migrate to new simplified schema
      try {
        // Add new columns - check if they exist first to avoid errors
        try {
          await db.execute('ALTER TABLE products ADD COLUMN part_number TEXT');
        } catch (e) {
          // Column might already exist
        }
        try {
          await db.execute('ALTER TABLE products ADD COLUMN supplier TEXT');
        } catch (e) {
          // Column might already exist
        }
        try {
          await db.execute('ALTER TABLE products ADD COLUMN current_quantity REAL');
        } catch (e) {
          // Column might already exist
        }
        try {
          await db.execute('ALTER TABLE products ADD COLUMN unit_cost REAL');
        } catch (e) {
          // Column might already exist
        }
        try {
          await db.execute('ALTER TABLE products ADD COLUMN minimum_stock REAL');
        } catch (e) {
          // Column might already exist
        }
        try {
          await db.execute('ALTER TABLE products ADD COLUMN maximum_stock REAL');
        } catch (e) {
          // Column might already exist
        }
        try {
          await db.execute('ALTER TABLE products ADD COLUMN location_id INTEGER');
        } catch (e) {
          // Column might already exist
        }
        try {
          await db.execute('ALTER TABLE products ADD COLUMN warranty TEXT');
        } catch (e) {
          // Column might already exist
        }
        try {
          await db.execute('ALTER TABLE products ADD COLUMN notes TEXT');
        } catch (e) {
          // Column might already exist
        }
        try {
          await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
        } catch (e) {
          // Column might already exist
        }
        
        // Add foreign key constraint if supported
        try {
          await db.execute('''
            CREATE TABLE products_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              category TEXT,
              unit_of_measurement TEXT NOT NULL,
              description TEXT,
              sku TEXT UNIQUE NOT NULL,
              part_number TEXT,
              manufacturer TEXT,
              supplier TEXT,
              current_quantity REAL,
              unit_cost REAL,
              minimum_stock REAL,
              maximum_stock REAL,
              location_id INTEGER,
              warranty TEXT,
              notes TEXT,
              image_path TEXT
            )
          ''');
          
          // Copy data from old table
          await db.execute('''
            INSERT INTO products_new 
            (id, name, category, unit_of_measurement, description, sku, manufacturer, 
             part_number, supplier, current_quantity, unit_cost, minimum_stock, maximum_stock, 
             location_id, warranty, notes, image_path)
            SELECT 
              id, name, category, unit_of_measurement, description, sku, manufacturer,
              NULL, NULL, NULL, cost_price, NULL, NULL, NULL, NULL, tags, NULL
            FROM products
          ''');
          
          await db.execute('DROP TABLE products');
          await db.execute('ALTER TABLE products_new RENAME TO products');
        } catch (e) {
          // Migration failed, keep old structure and just add new columns
        }
      } catch (e) {
        // Columns might already exist, ignore
      }
    }
    
    // Version 3 to 4: Ensure image_path column exists and add foreign key constraints
    if (oldVersion < 4) {
      try {
        // Check if image_path column exists, if not add it
        final tableInfo = await db.rawQuery('PRAGMA table_info(products)');
        final hasImagePath = tableInfo.any((column) => column['name'] == 'image_path');
        if (!hasImagePath) {
          await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
        }
      } catch (e) {
        // Ignore errors - column might already exist
        developer.log('Error checking/adding image_path column', error: e);
      }
      
      // Note: Foreign key constraints are added in the table creation
      // For existing databases, recreating tables with constraints is complex
      // So we handle it gracefully - constraints will apply to new databases
    }
    
    // Version 4 to 5: Add image_paths column for multiple images
    if (oldVersion < 5) {
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(products)');
        final hasImagePaths = tableInfo.any((column) => column['name'] == 'image_paths');
        if (!hasImagePaths) {
          await db.execute('ALTER TABLE products ADD COLUMN image_paths TEXT');
        }
      } catch (e) {
        developer.log('Error checking/adding image_paths column', error: e);
      }
    }
  }

  Future<void> _ensureDefaultUser(Database db) async {
    // Check if admin user exists
    final adminCheck = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
    );
    
    // If admin doesn't exist, create it
    if (adminCheck.isEmpty) {
      try {
        await db.insert('users', {
          'username': 'admin',
          'email': 'admin@inventory.com',
          'password_hash': 'admin123', // In production, use proper hashing
          'role': 'admin',
          'full_name': 'Administrator',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // User might already exist, ignore error
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        full_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        unit_of_measurement TEXT NOT NULL,
        description TEXT,
        sku TEXT UNIQUE NOT NULL,
        part_number TEXT,
        manufacturer TEXT,
        supplier TEXT,
        current_quantity REAL,
        unit_cost REAL,
        minimum_stock REAL,
        maximum_stock REAL,
        location_id INTEGER,
        warranty TEXT,
        notes TEXT,
        image_path TEXT,
        image_paths TEXT
      )
    ''');

    // Product variants table
    await db.execute('''
      CREATE TABLE product_variants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        size TEXT,
        color TEXT,
        material TEXT,
        style TEXT,
        other_attributes TEXT,
        variant_sku TEXT,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // Locations table
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        description TEXT,
        address TEXT
      )
    ''');

    // Stock table
    await db.execute('''
      CREATE TABLE stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        location_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        minimum_threshold REAL,
        maximum_threshold REAL,
        batch_number TEXT,
        expiry_date TEXT,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
        FOREIGN KEY (location_id) REFERENCES locations (id) ON DELETE CASCADE,
        UNIQUE(product_id, location_id, batch_number)
      )
    ''');

    // Stock movements table
    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        from_location_id INTEGER,
        to_location_id INTEGER,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        reason TEXT,
        notes TEXT,
        user_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        batch_number TEXT,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
        FOREIGN KEY (from_location_id) REFERENCES locations (id) ON DELETE SET NULL,
        FOREIGN KEY (to_location_id) REFERENCES locations (id) ON DELETE SET NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_stock_product ON stock(product_id)');
    await db.execute('CREATE INDEX idx_stock_location ON stock(location_id)');
    await db.execute('CREATE INDEX idx_movements_product ON stock_movements(product_id)');
    await db.execute('CREATE INDEX idx_movements_timestamp ON stock_movements(timestamp)');

    // Insert default admin user (password: admin123)
    await db.insert('users', {
      'username': 'admin',
      'email': 'admin@inventory.com',
      'password_hash': 'admin123', // In production, use proper hashing
      'role': 'admin',
      'full_name': 'Administrator',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'created_at DESC');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // Product operations
  Future<int> insertProduct(Product product) async {
    final db = await database;
    
    // Ensure all required columns exist before inserting
    await _ensureProductColumns(db);
    
    return await db.insert('products', product.toMap());
  }
  
  // Helper method to ensure all product columns exist
  Future<void> _ensureProductColumns(Database db) async {
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(products)');
      final existingColumns = tableInfo.map((col) => col['name'] as String).toSet();
      
      // List of required columns
      final requiredColumns = {
        'part_number': 'TEXT',
        'supplier': 'TEXT',
        'current_quantity': 'REAL',
        'unit_cost': 'REAL',
        'minimum_stock': 'REAL',
        'maximum_stock': 'REAL',
        'location_id': 'INTEGER',
        'warranty': 'TEXT',
        'notes': 'TEXT',
        'image_path': 'TEXT',
        'image_paths': 'TEXT',
      };
      
      // Add missing columns
      for (final entry in requiredColumns.entries) {
        if (!existingColumns.contains(entry.key)) {
          try {
            await db.execute('ALTER TABLE products ADD COLUMN ${entry.key} ${entry.value}');
            developer.log('Added missing column: ${entry.key}');
          } catch (e) {
            developer.log('Error adding column ${entry.key}', error: e);
          }
        }
      }
    } catch (e) {
      developer.log('Error ensuring product columns', error: e);
    }
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<Product?> getProductBySku(String sku) async {
    final db = await database;
    final maps = await db.query('products', where: 'sku = ?', whereArgs: [sku]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    
    // Ensure all required columns exist before updating
    await _ensureProductColumns(db);
    
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Product variant operations
  Future<int> insertProductVariant(ProductVariant variant) async {
    final db = await database;
    return await db.insert('product_variants', variant.toMap());
  }

  Future<List<ProductVariant>> getProductVariants(int productId) async {
    final db = await database;
    final maps = await db.query(
      'product_variants',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return maps.map((map) => ProductVariant.fromMap(map)).toList();
  }

  Future<ProductVariant?> getProductVariantById(int id) async {
    final db = await database;
    final maps = await db.query('product_variants', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ProductVariant.fromMap(maps.first);
  }

  Future<int> updateProductVariant(ProductVariant variant) async {
    final db = await database;
    return await db.update(
      'product_variants',
      variant.toMap(),
      where: 'id = ?',
      whereArgs: [variant.id],
    );
  }

  Future<int> deleteProductVariant(int id) async {
    final db = await database;
    return await db.delete('product_variants', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProductVariants(int productId) async {
    final db = await database;
    return await db.delete('product_variants', where: 'product_id = ?', whereArgs: [productId]);
  }

  // Search operations
  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final searchTerm = '%$query%';
    final maps = await db.query(
      'products',
      where: 'name LIKE ? OR sku LIKE ? OR category LIKE ? OR description LIKE ? OR brand LIKE ? OR tags LIKE ?',
      whereArgs: [searchTerm, searchTerm, searchTerm, searchTerm, searchTerm, searchTerm],
      orderBy: 'name',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  // Location operations
  Future<int> insertLocation(Location location) async {
    final db = await database;
    return await db.insert('locations', location.toMap());
  }

  Future<List<Location>> getAllLocations() async {
    final db = await database;
    final maps = await db.query('locations', orderBy: 'name');
    return maps.map((map) => Location.fromMap(map)).toList();
  }

  Future<Location?> getLocationById(int id) async {
    final db = await database;
    final maps = await db.query('locations', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Location.fromMap(maps.first);
  }

  Future<int> updateLocation(Location location) async {
    final db = await database;
    return await db.update(
      'locations',
      location.toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }

  Future<int> deleteLocation(int id) async {
    final db = await database;
    return await db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  // Stock operations
  Future<int> insertStock(Stock stock) async {
    final db = await database;
    return await db.insert('stock', stock.toMap());
  }

  Future<List<Stock>> getAllStock() async {
    final db = await database;
    final maps = await db.query('stock');
    return maps.map((map) => Stock.fromMap(map)).toList();
  }

  Future<List<Stock>> getStockByProduct(int productId) async {
    final db = await database;
    final maps = await db.query(
      'stock',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return maps.map((map) => Stock.fromMap(map)).toList();
  }

  Future<List<Stock>> getStockByLocation(int locationId) async {
    final db = await database;
    final maps = await db.query(
      'stock',
      where: 'location_id = ?',
      whereArgs: [locationId],
    );
    return maps.map((map) => Stock.fromMap(map)).toList();
  }

  Future<Stock?> getStock(int productId, int locationId, {String? batchNumber}) async {
    final db = await database;
    final maps = await db.query(
      'stock',
      where: 'product_id = ? AND location_id = ? AND (batch_number = ? OR (batch_number IS NULL AND ? IS NULL))',
      whereArgs: [productId, locationId, batchNumber, batchNumber],
    );
    if (maps.isEmpty) return null;
    return Stock.fromMap(maps.first);
  }

  Future<int> updateStock(Stock stock) async {
    final db = await database;
    return await db.update(
      'stock',
      stock.toMap(),
      where: 'id = ?',
      whereArgs: [stock.id],
    );
  }

  Future<int> deleteStock(int id) async {
    final db = await database;
    return await db.delete('stock', where: 'id = ?', whereArgs: [id]);
  }

  // Stock movement operations
  Future<int> insertStockMovement(StockMovement movement) async {
    final db = await database;
    return await db.insert('stock_movements', movement.toMap());
  }

  Future<List<StockMovement>> getAllStockMovements() async {
    final db = await database;
    final maps = await db.query(
      'stock_movements',
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => StockMovement.fromMap(map)).toList();
  }

  Future<List<StockMovement>> getStockMovementsByProduct(int productId) async {
    final db = await database;
    final maps = await db.query(
      'stock_movements',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => StockMovement.fromMap(map)).toList();
  }

  Future<List<StockMovement>> getStockMovementsByLocation(int locationId) async {
    final db = await database;
    final maps = await db.query(
      'stock_movements',
      where: 'from_location_id = ? OR to_location_id = ?',
      whereArgs: [locationId, locationId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => StockMovement.fromMap(map)).toList();
  }

  Future<List<StockMovement>> getStockMovementsByUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      'stock_movements',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => StockMovement.fromMap(map)).toList();
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

