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
          primary: Color(0xFF818CF8),
          secondary: Color(0xFFA78BFA),
          surface: Color(0xFF1E1E2E),
          onSurface: Color(0xFFE2E8F0),
          background: Color(0xFF13131F),
          onBackground: Color(0xFFE2E8F0),
          onPrimary: Color(0xFF13131F),
          onSecondary: Color(0xFF13131F),
          error: Color(0xFFF87171),
          tertiary: Color(0xFF34D399),
          surfaceContainerHighest: Color(0xFF2A2A3E),
          outline: Color(0xFF3A3A52),
          onSurfaceVariant: Color(0xFF94A3B8),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFF1E1E2E),
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
          fillColor: const Color(0xFF2A2A3E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3A3A52)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3A3A52)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
          hintStyle: const TextStyle(color: Color(0xFF64748B)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF13131F),
          foregroundColor: Color(0xFFE2E8F0),
          surfaceTintColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: const Color(0xFF13131F),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1E1E2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF2A2A3E),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF818CF8);
            }
            return const Color(0xFF64748B);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF818CF8).withOpacity(0.35);
            }
            return const Color(0xFF2A2A3E);
          }),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF818CF8);
              }
              return const Color(0xFF2A2A3E);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF13131F);
              }
              return const Color(0xFF94A3B8);
            }),
            side: WidgetStateProperty.all(
              const BorderSide(color: Color(0xFF3A3A52)),
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
  bool _autoRandomPassword = false;

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
    _autoRandomPassword = _prefs.getBool('auto_random_password') ?? false;

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
    _showSnackBar('Password copied', Icons.content_copy);
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
    if (_passwordMethod == 1 && _autoRandomPassword) {
      _generateRandomPassword();
    }
  }

  void _showSnackBar(String message, IconData icon, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon,
                color: isError
                    ? const Color(0xFFF87171)
                    : const Color(0xFF818CF8),
                size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message,
                    style: const TextStyle(color: Color(0xFFE2E8F0)))),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E2E),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        const String downloadPath =
            '/storage/emulated/0/Download/insta_saver';
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
        _showSnackBar('Saved to Downloads/insta_saver', Icons.download);
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
          '${newAccounts.length} accounts imported', Icons.upload);
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

  void _copyAuthCode(int index) {
    if (_accounts[index].auth_code.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _accounts[index].auth_code));
      _showSnackBar('2FA code copied', Icons.security);
    }
  }

  void _deleteAccount(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account',
              style: TextStyle(color: Color(0xFFE2E8F0))),
          content: const Text(
              'Are you sure you want to delete this account?',
              style: TextStyle(color: Color(0xFF94A3B8))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _accounts.removeAt(index));
                _saveAccounts();
                Navigator.of(context).pop();
                _showSnackBar('Account deleted', Icons.delete);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF87171).withOpacity(0.15),
                foregroundColor: const Color(0xFFF87171),
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
          title: const Text('Clear All',
              style: TextStyle(color: Color(0xFFE2E8F0))),
          content: Text(
              'Delete all ${_accounts.length} accounts?',
              style: const TextStyle(color: Color(0xFF94A3B8))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _accounts.clear());
                _saveAccounts();
                Navigator.of(context).pop();
                _showSnackBar('All accounts deleted', Icons.clear_all);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF87171).withOpacity(0.15),
                foregroundColor: const Color(0xFFF87171),
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF818CF8), Color(0xFFA78BFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.manage_accounts,
                  color: Color(0xFF13131F), size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Account Manager',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF818CF8),
          indicatorWeight: 3,
          labelColor: const Color(0xFF818CF8),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          dividerColor: const Color(0xFF2A2A3E),
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline, size: 18), text: 'Input'),
            Tab(icon: Icon(Icons.bookmark_border, size: 18), text: 'Saved'),
            Tab(icon: Icon(Icons.swap_vert, size: 18), text: 'Transfer'),
            Tab(icon: Icon(Icons.tune, size: 18), text: 'Settings'),
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
          if (_editingIndex != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF818CF8).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF818CF8).withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined,
                      color: Color(0xFF818CF8), size: 16),
                  const SizedBox(width: 8),
                  Text('Editing Account #${_editingIndex! + 1}',
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      )),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() => _editingIndex = null);
                      _clearFields();
                    },
                    child: const Text('Cancel',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (_showEmailInput) ...[
            _buildInputField(
                _emailController, 'Email Address (Optional)', Icons.email_outlined),
            const SizedBox(height: 12),
          ],
          _buildInputField(
              _usernameController, 'Username', Icons.person_outline),
          const SizedBox(height: 12),
          _buildPasswordField(),
          const SizedBox(height: 12),
          _buildInputField(
              _auth_codeController, '2FA Code (Optional)', Icons.shield_outlined),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(
                      _editingIndex != null
                          ? Icons.update
                          : Icons.save_outlined,
                      size: 18),
                  label: Text(_editingIndex != null ? 'Update' : 'Save Account',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF818CF8),
                    foregroundColor: const Color(0xFF13131F),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _clearFields,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A3E),
                  foregroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.all(14),
                ),
                child: const Icon(Icons.clear, size: 18),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF13131F),
              border:
                  Border(bottom: BorderSide(color: Color(0xFF2A2A3E))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF818CF8).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_accounts.length} accounts',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF818CF8))),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.delete_sweep_outlined,
                      size: 16, color: Color(0xFFF87171)),
                  label: const Text('Clear All',
                      style: TextStyle(
                          color: Color(0xFFF87171),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.inbox_outlined,
                            size: 40, color: Color(0xFF3A3A52)),
                      ),
                      const SizedBox(height: 16),
                      const Text('No accounts yet',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8))),
                      const SizedBox(height: 4),
                      const Text('Add accounts in the Input tab',
                          style: TextStyle(
                              color: Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _accounts.length,
                  itemBuilder: (context, i) {
                    final int accountIndex = _accounts.length - 1 - i;
                    final Account acc = _accounts[accountIndex];
                    return _buildSavedCard(acc, accountIndex, i + 1);
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
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF818CF8), Color(0xFFA78BFA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$cardNumber',
                    style: const TextStyle(
                      color: Color(0xFF13131F),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
                                color: Color(0xFFE2E8F0))),
                      Text('@${acc.username}',
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Info block
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF13131F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(acc.password,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                  fontFamily: 'monospace'))),
                    ],
                  ),
                  if (acc.auth_code.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(acc.auth_code,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                    fontFamily: 'monospace'))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Action buttons
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _actionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: const Color(0xFF94A3B8),
                  onTap: () => _editAccount(accountIndex),
                ),
                _actionButton(
                  icon: Icons.person_outline,
                  label: 'User',
                  color: const Color(0xFF818CF8),
                  onTap: () => _copyUsername(accountIndex),
                ),
                _actionButton(
                  icon: Icons.lock_outline,
                  label: 'Pass',
                  color: const Color(0xFFA78BFA),
                  onTap: () => _copyPassword(accountIndex),
                ),
                if (acc.auth_code.isNotEmpty)
                  _actionButton(
                    icon: Icons.shield_outlined,
                    label: '2FA',
                    color: const Color(0xFF34D399),
                    onTap: () => _copyAuthCode(accountIndex),
                  ),
                _actionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: const Color(0xFFF87171),
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
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: color.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600)),
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
          _buildCard(
            icon: Icons.file_download_outlined,
            iconColor: const Color(0xFF818CF8),
            title: 'Export',
            subtitle: 'Download all accounts as JSON',
            child: ElevatedButton.icon(
              onPressed: _downloadJson,
              icon: const Icon(Icons.download_outlined, size: 17),
              label: const Text('Download JSON',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF818CF8),
                foregroundColor: const Color(0xFF13131F),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildCard(
            icon: Icons.file_upload_outlined,
            iconColor: const Color(0xFFA78BFA),
            title: 'Import',
            subtitle: 'Paste JSON data to import accounts',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _importController,
                  style: const TextStyle(
                      color: Color(0xFFE2E8F0), fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Paste JSON here',
                    hintText: '[{"username": "...", "password": "..."}]',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                  minLines: 6,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _importJson,
                  icon: const Icon(Icons.upload_outlined, size: 17),
                  label: const Text('Import JSON',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA78BFA),
                    foregroundColor: const Color(0xFF13131F),
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
          _buildCard(
            icon: Icons.email_outlined,
            iconColor: const Color(0xFF818CF8),
            title: 'Display',
            child: _buildToggleRow(
              label: 'Show Email Field',
              subtitle: 'Toggle email input visibility',
              value: _showEmailInput,
              onChanged: (value) {
                setState(() => _showEmailInput = value);
                _prefs.setBool('show_email_input', value);
              },
            ),
          ),
          const SizedBox(height: 14),
          _buildCard(
            icon: Icons.password_outlined,
            iconColor: const Color(0xFFA78BFA),
            title: 'Password Method',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(value: 0, label: Text('Prefix Mode')),
                    ButtonSegment<int>(value: 1, label: Text('Word Mode')),
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
                if (_passwordMethod == 1) ...[
                  ..._buildWordMethodSettings(),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFF2A2A3E)),
                  const SizedBox(height: 10),
                  _buildToggleRow(
                    label: 'Auto Random Password',
                    subtitle: 'Generate a new password after each save',
                    value: _autoRandomPassword,
                    onChanged: (value) {
                      setState(() => _autoRandomPassword = value);
                      _prefs.setBool('auto_random_password', value);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildCard(
            icon: Icons.info_outline,
            iconColor: const Color(0xFF64748B),
            title: 'About',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Insta Saver v1.0',
                    style: TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontWeight: FontWeight.w500,
                        fontSize: 14)),
                SizedBox(height: 2),
                Text('Secure Instagram account manager',
                    style:
                        TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      color: Color(0xFF64748B), fontSize: 12)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3E)),
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
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    if (subtitle != null)
                      Text(subtitle,
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
              ),
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
        style: const TextStyle(color: Color(0xFFE2E8F0)),
        decoration: InputDecoration(
          labelText: 'Password Prefix',
          hintText: 'e.g. Yaseen',
          prefixIcon:
              const Icon(Icons.text_fields, color: Color(0xFF818CF8)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.content_copy,
                color: Color(0xFF94A3B8), size: 18),
            onPressed: _copyCurrentPassword,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preview',
                style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text(
              '${_prefixController.text.isNotEmpty ? _prefixController.text : 'prefix'}@${DateTime.now().day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF818CF8),
                  fontFamily: 'monospace'),
            ),
            const SizedBox(height: 6),
            Text(
                'Pattern: (prefix)@(day) — today is day ${DateTime.now().day.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 11)),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildWordMethodSettings() {
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Today: ${DateTime.now().day.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text(
                'Random mixed-case letters (8–13 chars) + today\'s 2-digit date. Total: 10–15 characters.',
                style:
                    TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ],
        ),
      ),
    ];
  }

  Widget _buildInputField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Color(0xFFE2E8F0)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF818CF8), size: 20),
      ),
    );
  }

  Widget _buildPasswordField() {
    if (_passwordMethod == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Password',
              style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3A3A52)),
                  ),
                  child: Text(
                    _currentPassword.isEmpty
                        ? 'Set a prefix in Settings'
                        : _currentPassword,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: _currentPassword.isEmpty
                          ? const Color(0xFF64748B)
                          : const Color(0xFF818CF8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _copyCurrentPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF818CF8).withOpacity(0.12),
                  foregroundColor: const Color(0xFF818CF8),
                  padding: const EdgeInsets.all(14),
                  elevation: 0,
                ),
                child: const Icon(Icons.content_copy, size: 17),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              'Format: (prefix)@${DateTime.now().day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  color: Color(0xFF64748B), fontSize: 11)),
        ],
      );
    } else {
      return TextField(
        controller: _passwordController,
        style: const TextStyle(
            color: Color(0xFFE2E8F0), fontFamily: 'monospace'),
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline,
              color: Color(0xFF818CF8), size: 20),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh_outlined,
                      color: Color(0xFF94A3B8), size: 18),
                  onPressed: _generateRandomPassword,
                  tooltip: 'Generate new',
                ),
                IconButton(
                  icon: const Icon(Icons.content_copy,
                      color: Color(0xFF94A3B8), size: 18),
                  onPressed: _copyCurrentPassword,
                  tooltip: 'Copy',
                ),
              ],
            ),
          ),
        ),
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
