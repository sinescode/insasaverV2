import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insta Saver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFE1306C),
          secondary: Color(0xFF405DE6),
          surface: Color(0xFFFAFAFA),
          background: Color(0xFFF8FAFC),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF1F2937),
          onBackground: Color(0xFF374151),
          error: Color(0xFFEF4444),
          tertiary: Color(0xFFF56040),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE1306C), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1F2937),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class Account {
  String email;
  String username;
  String password;
  String auth_code;

  Account({
    required this.email,
    required this.username,
    required this.password,
    required this.auth_code,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      auth_code: json['auth_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'password': password,
      'auth_code': auth_code,
    };
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Account> _accounts = [];
  int? _editingIndex;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _auth_codeController = TextEditingController();
  final TextEditingController _importController = TextEditingController();
  final TextEditingController _prefixController = TextEditingController();
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    final String? accountsJson = _prefs.getString('accounts');
    if (accountsJson != null) {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      setState(() {
        _accounts = decoded.map((item) => Account.fromJson(item)).toList();
      });
    }
    _emailController.text = _prefs.getString('email') ?? '';
    _usernameController.text = _prefs.getString('username') ?? '';
    _auth_codeController.text = _prefs.getString('auth_code') ?? '';
    _prefixController.text = _prefs.getString('prefix') ?? '';

    _emailController.addListener(() => _prefs.setString('email', _emailController.text));
    _usernameController.addListener(() => _prefs.setString('username', _usernameController.text));
    _auth_codeController.addListener(() => _prefs.setString('auth_code', _auth_codeController.text));
    _prefixController.addListener(() => _prefs.setString('prefix', _prefixController.text));
  }

  Future<void> _saveAccounts() async {
    final String accountsJson = jsonEncode(_accounts.map((acc) => acc.toJson()).toList());
    await _prefs.setString('accounts', accountsJson);
  }

  String get _currentPassword {
    final String prefix = _prefixController.text.trim();
    final String day = DateTime.now().day.toString();
    return prefix.isNotEmpty ? '$prefix@$day' : '@$day';
  }

  void _copyPassword() {
    Clipboard.setData(ClipboardData(text: _currentPassword));
    _showSnackBar('Password copied to clipboard', Icons.content_copy);
  }

  void _submit() {
    if (_emailController.text.isEmpty || _usernameController.text.isEmpty || _prefixController.text.isEmpty) {
      _showSnackBar('Please fill in all required fields', Icons.error, isError: true);
      return;
    }

    final Account newAccount = Account(
      email: _emailController.text,
      username: _usernameController.text,
      password: _currentPassword,
      auth_code: _auth_codeController.text,
    );
    setState(() {
      if (_editingIndex != null) {
        _accounts[_editingIndex!] = newAccount;
        _editingIndex = null;
      } else {
        _accounts.add(newAccount);
      }
    });
    _saveAccounts();
    _clearFields();
    _showSnackBar('Account saved successfully', Icons.check_circle);
  }

  void _clearFields() {
    _emailController.clear();
    _usernameController.clear();
    _auth_codeController.clear();
  }

  void _showSnackBar(String message, IconData icon, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _downloadJson() async {
    final PermissionStatus status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      final Directory? baseDir = await getExternalStorageDirectory();
      if (baseDir != null) {
        final String downloadPath = '/storage/emulated/0/Download/insta_saver';
        final Directory dir = Directory(downloadPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final String dateTime = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final String filePath = '$downloadPath/instagram_accounts_$dateTime.json';
        final File file = File(filePath);
        final String jsonData = jsonEncode(_accounts.map((acc) => acc.toJson()).toList());
        await file.writeAsString(jsonData);
        _showSnackBar('Downloaded to Downloads/insta_saver', Icons.download);
      }
    } else {
      _showSnackBar('Storage permission denied', Icons.error, isError: true);
    }
  }

  void _importJson() {
    try {
      final List<dynamic> imported = jsonDecode(_importController.text);
      final List<Account> newAccounts = imported.map((item) => Account.fromJson(item)).toList();
      setState(() {
        _accounts.addAll(newAccounts);
      });
      _saveAccounts();
      _importController.clear();
      _showSnackBar('${newAccounts.length} accounts imported successfully', Icons.upload);
    } catch (e) {
      _showSnackBar('Invalid JSON format', Icons.error, isError: true);
    }
  }

  void _editAccount(int index) {
    setState(() {
      _editingIndex = index;
      _emailController.text = _accounts[index].email;
      _usernameController.text = _accounts[index].username;
      _auth_codeController.text = _accounts[index].auth_code;
      _prefixController.text = _accounts[index].password.split('@').first;
    });
    _tabController.animateTo(0);
  }

  void _copyAccountPassword(int index) {
    Clipboard.setData(ClipboardData(text: _accounts[index].password));
    _showSnackBar('Password copied', Icons.content_copy);
  }

  void _deleteAccount(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete this account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _accounts.removeAt(index);
                });
                _saveAccounts();
                Navigator.of(context).pop();
                _showSnackBar('Account deleted', Icons.delete);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _clearAll() {
    if (_accounts.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Clear All Accounts'),
          content: Text('Are you sure you want to delete all ${_accounts.length} accounts?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _accounts.clear();
                });
                _saveAccounts();
                Navigator.of(context).pop();
                _showSnackBar('All accounts deleted', Icons.clear_all);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary!,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Insta Saver', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'Input'),
            Tab(icon: Icon(Icons.swap_vert), text: 'Import/Export'),
            Tab(icon: Icon(Icons.list), text: 'Saved'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Input
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_editingIndex != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.tertiary!.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Theme.of(context).colorScheme.tertiary),
                        const SizedBox(width: 8),
                        Text('Editing Account', style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                        )),
                      ],
                    ),
                  ),
                if (_editingIndex != null) const SizedBox(height: 16),
                
                _buildInputField(_emailController, 'Email Address', Icons.email),
                const SizedBox(height: 16),
                _buildInputField(_usernameController, 'Username', Icons.person),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 16),
                _buildInputField(_auth_codeController, '2FA Code (Optional)', Icons.security),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: Icon(_editingIndex != null ? Icons.update : Icons.save),
                        label: Text(_editingIndex != null ? 'Update' : 'Save Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _clearFields,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Icon(Icons.clear),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tab 2: Import/Export
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.download, color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 8),
                            const Text('Export Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Download all your saved accounts as a JSON file.', 
                          style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _downloadJson,
                          icon: const Icon(Icons.file_download),
                          label: const Text('Download JSON'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.upload, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('Import Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Paste JSON data to import accounts.', 
                          style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _importController,
                          decoration: const InputDecoration(
                            labelText: 'Paste JSON here',
                            hintText: 'Paste your exported JSON data...',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 8,
                          minLines: 8,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _importJson,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Import JSON'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tab 3: Saved
          Column(
            children: [
              if (_accounts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${_accounts.length} accounts saved', 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                      ElevatedButton.icon(
                        onPressed: _clearAll,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Clear All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _accounts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('No accounts saved yet', 
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            Text('Add your first account in the Input tab', 
                              style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _accounts.length,
                        itemBuilder: (context, i) {
                          final int accountIndex = _accounts.length - 1 - i;
                          final Account acc = _accounts[accountIndex];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(acc.email, style: const TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.bold)),
                                            Text(acc.username, style: TextStyle(
                                              color: Colors.grey.shade600)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.lock, size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text('Password: ${acc.password}')),
                                          ],
                                        ),
                                        if (acc.auth_code.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.security, size: 16),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text('2FA: ${acc.auth_code}')),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _editAccount(accountIndex),
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Edit'),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _copyAccountPassword(accountIndex),
                                        icon: const Icon(Icons.content_copy, size: 16),
                                        label: const Text('Copy'),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _deleteAccount(accountIndex),
                                        icon: const Icon(Icons.delete, size: 16),
                                        label: const Text('Delete'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Theme.of(context).colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // Tab 4: Settings
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.password, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('Password Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _prefixController,
                          decoration: InputDecoration(
                            labelText: 'Password Prefix',
                            hintText: 'Enter your password prefix',
                            prefixIcon: Icon(Icons.text_fields, color: Theme.of(context).colorScheme.primary),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.content_copy),
                              onPressed: _copyPassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current Password Format:', 
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                )),
                              const SizedBox(height: 4),
                              Text('${_prefixController.text.isNotEmpty ? _prefixController.text : '(prefix)'}@${DateTime.now().day}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('Example: If prefix is "Yaseen" and today is ${DateTime.now().day}, password will be: Yaseen@${DateTime.now().day}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 8),
                            const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Insta Saver v1.0', 
                          style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text('Secure Instagram account manager', 
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password', style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 16,
        )),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _currentPassword,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _copyPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Icon(Icons.content_copy),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Format: (prefix)@(today\'s date) • Today is ${DateTime.now().day}',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _auth_codeController.dispose();
    _importController.dispose();
    _prefixController.dispose();
    super.dispose();
  }
}