import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
      title: 'Account Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFDFD0B8),
          secondary: Color(0xFF948979),
          surface: Color(0xFF2C3139),
          onSurface: Color(0xFFDFD0B8),
          background: Color(0xFF222831),
          onBackground: Color(0xFFDFD0B8),
          onPrimary: Color(0xFF222831),
          onSecondary: Color(0xFF222831),
          error: Color(0xFFEF4444),
          tertiary: Color(0xFF948979),
          surfaceContainerHighest: Color(0xFF393E46),
          outline: Color(0xFF4A5060),
          onSurfaceVariant: Color(0xFF948979),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFF2C3139),
          surfaceTintColor: Colors.transparent,
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
          fillColor: const Color(0xFF393E46),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A5060)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A5060)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDFD0B8), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF948979)),
          hintStyle: const TextStyle(color: Color(0xFF948979)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF222831),
          foregroundColor: Color(0xFFDFD0B8),
          surfaceTintColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: const Color(0xFF222831),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF2C3139),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF393E46),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFDFD0B8);
            }
            return const Color(0xFF948979);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFDFD0B8).withOpacity(0.4);
            }
            return const Color(0xFF393E46);
          }),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFFDFD0B8);
              }
              return const Color(0xFF393E46);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF222831);
              }
              return const Color(0xFF948979);
            }),
            side: WidgetStateProperty.all(
              const BorderSide(color: Color(0xFF4A5060)),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
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

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Account> _accounts = [];
  int? _editingIndex;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _auth_codeController = TextEditingController();
  final TextEditingController _importController = TextEditingController();
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late SharedPreferences _prefs;

  bool _showEmailInput = true;
  int _passwordMethod = 0;

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
    _passwordController.text = _prefs.getString('random_password') ?? '';
    _showEmailInput = _prefs.getBool('show_email_input') ?? true;
    _passwordMethod = _prefs.getInt('password_method') ?? 0;

    if (_passwordMethod == 1 && _passwordController.text.isEmpty) {
      _generateRandomPassword();
    }

    _emailController
        .addListener(() => _prefs.setString('email', _emailController.text));
    _usernameController.addListener(
        () => _prefs.setString('username', _usernameController.text));
    _auth_codeController.addListener(
        () => _prefs.setString('auth_code', _auth_codeController.text));
    _prefixController
        .addListener(() => _prefs.setString('prefix', _prefixController.text));
    _passwordController.addListener(
        () => _prefs.setString('random_password', _passwordController.text));
  }

  Future<void> _saveAccounts() async {
    final String accountsJson =
        jsonEncode(_accounts.map((acc) => acc.toJson()).toList());
    await _prefs.setString('accounts', accountsJson);
  }

  String get _currentPassword {
    if (_passwordMethod == 1) {
      return _passwordController.text.trim();
    } else {
      final String prefix = _prefixController.text.trim();
      final String day = DateTime.now().day.toString().padLeft(2, '0');
      return prefix.isNotEmpty ? '$prefix@$day' : '@$day';
    }
  }

  void _generateRandomPassword() {
    const String letters = 'abcdefghijklmnopqrstuvwxyz';
    final Random random = Random();
    final int randomLength = 8 + random.nextInt(6);
    String randomPart = '';
    for (int i = 0; i < randomLength; i++) {
      final int index = random.nextInt(letters.length);
      final String char = letters[index];
      randomPart += random.nextBool() ? char.toUpperCase() : char.toLowerCase();
    }
    final String day = DateTime.now().day.toString().padLeft(2, '0');
    _passwordController.text = randomPart + day;
  }

  void _copyCurrentPassword() {
    Clipboard.setData(ClipboardData(text: _currentPassword));
    _showSnackBar('Password copied to clipboard', Icons.content_copy);
  }

  void _submit() {
    if (_usernameController.text.isEmpty ||
        (_passwordMethod == 0 && _prefixController.text.isEmpty) ||
        (_passwordMethod == 1 && _currentPassword.isEmpty)) {
      _showSnackBar('Please fill in all required fields', Icons.error,
          isError: true);
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
    _passwordController.clear();
    if (_passwordMethod == 1) {
      _generateRandomPassword();
    }
  }

  void _showSnackBar(String message, IconData icon, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF393E46),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadJson() async {
    final PermissionStatus status =
        await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      final Directory? baseDir = await getExternalStorageDirectory();
      if (baseDir != null) {
        final String downloadPath = '/storage/emulated/0/Download/insta_saver';
        final Directory dir = Directory(downloadPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final String dateTime =
            DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final String filePath =
            '$downloadPath/instagram_accounts_$dateTime.json';
        final File file = File(filePath);
        final String jsonData =
            jsonEncode(_accounts.map((acc) => acc.toJson()).toList());
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
      final List<Account> newAccounts =
          imported.map((item) => Account.fromJson(item)).toList();
      setState(() {
        _accounts.addAll(newAccounts);
      });
      _saveAccounts();
      _importController.clear();
      _showSnackBar(
          '${newAccounts.length} accounts imported successfully', Icons.upload);
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

      final String password = _accounts[index].password;
      if (password.contains('@')) {
        _passwordMethod = 0;
        _prefixController.text = password.split('@').first;
      } else {
        _passwordMethod = 1;
        _passwordController.text = password;
      }
      _prefs.setInt('password_method', _passwordMethod);
    });
    _tabController.animateTo(0);
  }

  void _copyUsername(int index) {
    Clipboard.setData(ClipboardData(text: _accounts[index].username));
    _showSnackBar('Username copied', Icons.person);
  }

  void _copyPassword(int index) {
    Clipboard.setData(ClipboardData(text: _accounts[index].password));
    _showSnackBar('Password copied', Icons.lock);
  }

  void _deleteAccount(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C3139),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Account',
              style: TextStyle(color: Color(0xFFDFD0B8))),
          content: const Text('Are you sure you want to delete this account?',
              style: TextStyle(color: Color(0xFF948979))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF948979))),
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
                backgroundColor: const Color(0xFFEF4444),
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
          backgroundColor: const Color(0xFF2C3139),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Clear All Accounts',
              style: TextStyle(color: Color(0xFFDFD0B8))),
          content: Text(
              'Are you sure you want to delete all ${_accounts.length} accounts?',
              style: const TextStyle(color: Color(0xFF948979))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF948979))),
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
                backgroundColor: const Color(0xFFEF4444),
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
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFDFD0B8),
                    Color(0xFF948979),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.manage_accounts, color: Color(0xFF222831), size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Account Manager',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFDFD0B8),
          labelColor: const Color(0xFFDFD0B8),
          unselectedLabelColor: const Color(0xFF948979),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.add, size: 20), text: 'Input'),
            Tab(icon: Icon(Icons.bookmark, size: 20), text: 'Saved'),
            Tab(icon: Icon(Icons.swap_vert, size: 20), text: 'Import/Export'),
            Tab(icon: Icon(Icons.settings, size: 20), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInputTab(),
          _buildSavedTab(),
          _buildImportExportTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildInputTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_editingIndex != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF948979).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF948979).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Color(0xFF948979), size: 18),
                  const SizedBox(width: 8),
                  Text('Editing Account #${_editingIndex! + 1}',
                      style: const TextStyle(
                        color: Color(0xFF948979),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      )),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() => _editingIndex = null);
                      _clearFields();
                    },
                    child: const Text('Cancel',
                        style: TextStyle(color: Color(0xFF948979), fontSize: 12)),
                  ),
                ],
              ),
            ),
          if (_editingIndex != null) const SizedBox(height: 12),

          if (_showEmailInput) ...[
            _buildInputField(
                _emailController, 'Email Address (Optional)', Icons.email),
            const SizedBox(height: 12),
          ],
          _buildInputField(_usernameController, 'Username', Icons.person),
          const SizedBox(height: 12),
          _buildPasswordField(),
          const SizedBox(height: 12),
          _buildInputField(
              _auth_codeController, '2FA Code (Optional)', Icons.security),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(
                      _editingIndex != null ? Icons.update : Icons.save,
                      size: 20),
                  label: Text(_editingIndex != null ? 'Update' : 'Save Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDFD0B8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _clearFields,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF393E46),
                  foregroundColor: const Color(0xFF948979),
                  padding: const EdgeInsets.all(14),
                ),
                child: const Icon(Icons.clear, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedTab() {
    return Column(
      children: [
        if (_accounts.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF222831),
              border: Border(
                bottom: BorderSide(color: Color(0xFF4A5060)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('${_accounts.length} accounts saved',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF948979))),
                ),
                ElevatedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444).withOpacity(0.15),
                    foregroundColor: const Color(0xFFEF4444),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    elevation: 0,
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
                      Icon(Icons.inbox_outlined,
                          size: 64, color: Colors.grey.shade700),
                      const SizedBox(height: 16),
                      const Text('No accounts saved yet',
                          style: TextStyle(
                              fontSize: 16, color: Color(0xFF948979))),
                      const SizedBox(height: 6),
                      const Text('Add your first account in the Input tab',
                          style:
                              TextStyle(color: Color(0xFF948979), fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _accounts.length,
                  itemBuilder: (context, i) {
                    final int accountIndex = _accounts.length - 1 - i;
                    final Account acc = _accounts[accountIndex];
                    final int cardNumber = i + 1;
                    return _buildSavedCard(acc, accountIndex, cardNumber);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSavedCard(Account acc, int accountIndex, int cardNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3139),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4A5060)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDFD0B8), Color(0xFF948979)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$cardNumber',
                    style: const TextStyle(
                      color: Color(0xFF222831),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (acc.email.isNotEmpty)
                        Text(acc.email,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDFD0B8))),
                      Text('@${acc.username}',
                          style: const TextStyle(
                              color: Color(0xFF948979), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF393E46),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 14, color: Color(0xFF948979)),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text('Password: ${acc.password}',
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF948979)))),
                    ],
                  ),
                  if (acc.auth_code.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.security_outlined,
                            size: 14, color: Color(0xFF948979)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text('2FA: ${acc.auth_code}',
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF948979)))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: const Color(0xFF948979),
                  onTap: () => _editAccount(accountIndex),
                ),
                const SizedBox(width: 4),
                _actionButton(
                  icon: Icons.person,
                  label: 'User',
                  color: const Color(0xFFDFD0B8),
                  onTap: () => _copyUsername(accountIndex),
                ),
                const SizedBox(width: 4),
                _actionButton(
                  icon: Icons.lock_outline,
                  label: 'Pass',
                  color: const Color(0xFFDFD0B8),
                  onTap: () => _copyPassword(accountIndex),
                ),
                const SizedBox(width: 4),
                _actionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: const Color(0xFFEF4444),
                  onTap: () => _deleteAccount(accountIndex),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2C3139),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4A5060)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF948979).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.download,
                          color: Color(0xFF948979), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('Export Data',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                    'Download all your saved accounts as a JSON file.',
                    style: TextStyle(color: Color(0xFF948979), fontSize: 14)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _downloadJson,
                  icon: const Icon(Icons.file_download, size: 18),
                  label: const Text('Download JSON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF948979),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2C3139),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4A5060)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFD0B8).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.upload,
                          color: Color(0xFFDFD0B8), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('Import Data',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Paste JSON data to import accounts.',
                    style: TextStyle(color: Color(0xFF948979), fontSize: 14)),
                const SizedBox(height: 12),
                TextField(
                  controller: _importController,
                  style: const TextStyle(color: Color(0xFFDFD0B8)),
                  decoration: const InputDecoration(
                    labelText: 'Paste JSON here',
                    hintText: 'Paste your exported JSON data...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                  minLines: 6,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _importJson,
                  icon: const Icon(Icons.file_upload, size: 18),
                  label: const Text('Import JSON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDFD0B8),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSettingsCard(
            icon: Icons.email_outlined,
            iconColor: const Color(0xFFDFD0B8),
            title: 'Email Settings',
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Show Email Input',
                          style: TextStyle(
                              color: Color(0xFFDFD0B8), fontSize: 14)),
                      Text('Toggle email field visibility in input form',
                          style: TextStyle(
                              color: Color(0xFF948979), fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: _showEmailInput,
                  onChanged: (value) {
                    setState(() => _showEmailInput = value);
                    _prefs.setBool('show_email_input', value);
                  },
                  activeColor: const Color(0xFFDFD0B8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsCard(
            icon: Icons.password_outlined,
            iconColor: const Color(0xFF948979),
            title: 'Password Method',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(value: 0, label: Text('Prefix')),
                    ButtonSegment<int>(value: 1, label: Text('Word')),
                  ],
                  selected: {_passwordMethod},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _passwordMethod = newSelection.first;
                      if (_passwordMethod == 1 &&
                          _passwordController.text.isEmpty) {
                        _generateRandomPassword();
                      }
                    });
                    _prefs.setInt('password_method', _passwordMethod);
                  },
                ),
                const SizedBox(height: 16),
                if (_passwordMethod == 0) ..._buildPrefixMethodSettings(),
                if (_passwordMethod == 1) ..._buildWordMethodSettings(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsCard(
            icon: Icons.info_outline,
            iconColor: const Color(0xFF948979),
            title: 'About',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Insta Saver v1.0',
                    style: TextStyle(color: Color(0xFF948979), fontSize: 14)),
                SizedBox(height: 2),
                Text('Secure Instagram account manager',
                    style: TextStyle(color: Color(0xFF948979), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C3139),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A5060)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  List<Widget> _buildPrefixMethodSettings() {
    return [
      TextField(
        controller: _prefixController,
        style: const TextStyle(color: Color(0xFFDFD0B8)),
        decoration: InputDecoration(
          labelText: 'Password Prefix',
          hintText: 'Enter your password prefix',
          prefixIcon: const Icon(Icons.text_fields, color: Color(0xFFDFD0B8)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.content_copy, color: Color(0xFF948979)),
            onPressed: _copyCurrentPassword,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF393E46),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Password Format:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF948979),
                  fontSize: 13,
                )),
            const SizedBox(height: 4),
            Text(
                '${_prefixController.text.isNotEmpty ? _prefixController.text : '(prefix)'}@${DateTime.now().day.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDFD0B8))),
            const SizedBox(height: 6),
            Text(
                'Example: If prefix is "Yaseen" and today is ${DateTime.now().day}, password will be: Yaseen@${DateTime.now().day.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Color(0xFF948979), fontSize: 11)),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildWordMethodSettings() {
    return [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF393E46),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Current Date: ${DateTime.now().day.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF948979),
                  fontSize: 13,
                )),
            const SizedBox(height: 4),
            const Text(
                'Generated passwords will be random mixed case letters (8-13 chars) appended with today\'s date (2 digits).',
                style: TextStyle(color: Color(0xFF948979), fontSize: 11)),
            const SizedBox(height: 6),
            const Text(
                'Total length: 10-15 characters. You can generate and edit in the Input tab.',
                style: TextStyle(color: Color(0xFF948979), fontSize: 11)),
          ],
        ),
      ),
    ];
  }

  Widget _buildInputField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Color(0xFFDFD0B8)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFDFD0B8)),
      ),
    );
  }

  Widget _buildPasswordField() {
    if (_passwordMethod == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Password',
              style: TextStyle(color: Color(0xFF948979), fontSize: 14)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF393E46),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4A5060)),
                  ),
                  child: Text(
                    _currentPassword.isEmpty
                        ? 'Configure password in Settings'
                        : _currentPassword,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _currentPassword.isEmpty
                          ? const Color(0xFF948979)
                          : const Color(0xFFDFD0B8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _copyCurrentPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF948979),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                child: const Icon(Icons.content_copy, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              'Format: (prefix)@(today\'s date) • Today is ${DateTime.now().day.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Color(0xFF948979), fontSize: 11)),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Password',
              style: TextStyle(color: Color(0xFF948979), fontSize: 14)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            style: const TextStyle(color: Color(0xFFDFD0B8)),
            decoration: InputDecoration(
              hintText: 'Generate or enter password',
              prefixIcon: const Icon(Icons.lock, color: Color(0xFFDFD0B8)),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh,
                          color: Color(0xFF948979)),
                      onPressed: _generateRandomPassword,
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_copy,
                          color: Color(0xFF948979)),
                      onPressed: _copyCurrentPassword,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Format: Random mixed case letters + date • 10-15 chars',
              style: TextStyle(color: Color(0xFF948979), fontSize: 11)),
        ],
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _auth_codeController.dispose();
    _importController.dispose();
    _prefixController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}