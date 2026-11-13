Add-Content .gitignore "`n# Private files`n.env`n.env.*`n!.env.example`n*.jks`nkey.properties"import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';

const String supabaseUrl = 'https://hnjoqvqkmvgauvebqvts.supabase.co';
const String supabaseKey = 'sb_publishable_KbfC-G2OtAtwy9r9I6n1AA_b5xpVsxO';
const String googleClientId =
    '319575241801-l0g8qj787bf1f1pdegqoqvq1kjm3u3uq.apps.googleusercontent.com';
// Supabase Auth > URL Configuration > Redirect URLs mein yeh add hona chahiye:
const String passwordResetRedirect = 'io.supabase.janseva://reset-callback/';

const Map<String, String> officerCodes = {
  'Bijli Officer': 'BIJLI@2024',
  'Sadak Officer': 'SADAK@2024',
  'Swasthya Officer': 'HEALTH@2024',
  'Shiksha Officer': 'SCHOOL@2024',
  'Safai Officer': 'SAFAI@2024',
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  runApp(MyApp());
}

final supabase = Supabase.instance.client;
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

bool _isNetworkError(Object e) {
  final s = e.toString().toLowerCase();
  return s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('authretryablefetch') ||
      s.contains('clientexception') ||
      s.contains('network is unreachable') ||
      s.contains('connection timed out') ||
      s.contains('connection refused');
}

String _friendlyAuthError(Object e) {
  if (_isNetworkError(e)) {
    return 'Internet nahi mil raha. Phone/emulator ka Wi‑Fi on karein, emulator Cold Boot karein, phir dubara try karein.';
  }
  return 'Error: $e';
}

Future<T> _retryNetwork<T>(Future<T> Function() action) async {
  Object? lastError;
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      return await action();
    } catch (e) {
      lastError = e;
      if (!_isNetworkError(e) || attempt == 2) rethrow;
      await Future.delayed(Duration(seconds: 1 + attempt));
    }
  }
  throw lastError!;
}

void _showAuthSnack(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(_friendlyAuthError(e)),
    duration: Duration(seconds: 5),
  ));
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _openedResetScreen = false;

  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery &&
          !_openedResetScreen) {
        _openedResetScreen = true;
        appNavigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              onDone: () => _openedResetScreen = false,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jan Seva',
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: WelcomeScreen(),
    );
  }
}

// ==================== WELCOME SCREEN ====================
class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a3a5c),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/logo.png',
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 16),
              Text('Jan Seva',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              Text('Aapki Awaaz, Hamara Farz',
                  style: TextStyle(color: Color(0xFF93C5FD), fontSize: 14)),
              SizedBox(height: 60),
              _RoleButton(
                icon: Icons.person,
                label: 'Nagarik Login',
                sub: 'Shikayat darj karein',
                bgColor: Colors.white,
                textColor: Color(0xFF1a3a5c),
                iconBg: Color(0xFFFFF7ED),
                iconColor: Colors.orange,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => NagarikLoginScreen())),
              ),
              SizedBox(height: 14),
              _RoleButton(
                icon: Icons.shield,
                label: 'Officer Login',
                sub: 'Shikayatein dekhen',
                bgColor: Colors.white.withOpacity(0.1),
                textColor: Colors.white,
                iconBg: Colors.white.withOpacity(0.15),
                iconColor: Colors.white,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => OfficerLoginScreen())),
                border: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color bgColor;
  final Color textColor;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  final bool border;

  const _RoleButton({
    required this.icon,
    required this.label,
    required this.sub,
    required this.bgColor,
    required this.textColor,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border:
              border ? Border.all(color: Colors.white.withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                Text(sub,
                    style: TextStyle(
                        fontSize: 12, color: textColor.withOpacity(0.7))),
              ],
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, color: textColor, size: 16),
          ],
        ),
      ),
    );
  }
}

// ==================== NAGARIK LOGIN ====================
class NagarikLoginScreen extends StatefulWidget {
  @override
  _NagarikLoginScreenState createState() => _NagarikLoginScreenState();
}

class _NagarikLoginScreenState extends State<NagarikLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool isSignUp = false;

  Future<void> loginWithEmail() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kripya email aur password bharein!')));
      return;
    }
    setState(() => isLoading = true);
    try {
      if (isSignUp) {
        await _retryNetwork(() => supabase.auth.signUp(
            email: emailController.text.trim(),
            password: passwordController.text.trim()));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account ban gaya! Login karein!')));
        setState(() => isSignUp = false);
      } else {
        await _retryNetwork(() => supabase.auth.signInWithPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim()));
        final userName = emailController.text.split('@')[0];
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => HomeScreen(userName: userName)));
      }
    } catch (e) {
      _showAuthSnack(context, e);
    }
    setState(() => isLoading = false);
  }

  Future<void> loginWithGoogle() async {
    try {
      setState(() => isLoading = true);
      final GoogleSignIn googleSignIn =
          GoogleSignIn(clientId: googleClientId, scopes: ['email']);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      await _retryNetwork(() => supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      ));
      final userName = googleUser.displayName ?? googleUser.email.split('@')[0];
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => HomeScreen(userName: userName)));
    } catch (e) {
      _showAuthSnack(context, e);
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
          backgroundColor: Color(0xFF1a3a5c),
          foregroundColor: Colors.white,
          title: Text('👤 Nagarik Login')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10),
            GestureDetector(
              onTap: isLoading ? null : loginWithGoogle,
              child: Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFE2E8F0))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('G',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red)),
                    SizedBox(width: 10),
                    Text('Google se Login karein',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1a3a5c))),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(children: [
              Expanded(child: Divider()),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('YA', style: TextStyle(color: Colors.grey))),
              Expanded(child: Divider())
            ]),
            SizedBox(height: 16),
            TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none))),
            SizedBox(height: 12),
            TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none))),
            if (!isSignUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(
                                roleTitle: 'Nagarik',
                                initialEmail: emailController.text.trim(),
                              ),
                            ),
                          ),
                  child: Text('Password bhool gaye?',
                      style: TextStyle(color: Color(0xFF1a3a5c))),
                ),
              ),
            SizedBox(height: isSignUp ? 24 : 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1a3a5c),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: isLoading ? null : loginWithEmail,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(isSignUp ? 'Account Banayein' : 'Login Karein',
                      style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => isSignUp = !isSignUp),
              child: Text(
                  isSignUp
                      ? 'Pehle se account hai? Login karein'
                      : 'Naya account banayein',
                  style: TextStyle(color: Color(0xFF1a3a5c))),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== OFFICER LOGIN ====================
class OfficerLoginScreen extends StatefulWidget {
  @override
  _OfficerLoginScreenState createState() => _OfficerLoginScreenState();
}

class _OfficerLoginScreenState extends State<OfficerLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final secretCodeController = TextEditingController();
  String selectedDistrict = 'Indore';
  String selectedPost = 'Bijli Officer';
  bool isLoading = false;
  bool isSignUp = false;

  final districts = [
    'Indore',
    'Bhopal',
    'Jabalpur',
    'Gwalior',
    'Ujjain',
    'Rewa',
    'Sagar'
  ];
  final posts = [
    'Bijli Officer',
    'Sadak Officer',
    'Swasthya Officer',
    'Shiksha Officer',
    'Safai Officer'
  ];

  Future<void> officerLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kripya email aur password bharein!')));
      return;
    }
    if (isSignUp &&
        secretCodeController.text.trim() != officerCodes[selectedPost]) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Secret code galat hai!'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => isLoading = true);
    try {
      if (isSignUp) {
        await _retryNetwork(() => supabase.auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          data: {
            'role': 'officer',
            'post': selectedPost,
            'district': selectedDistrict
          },
        ));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Officer account ban gaya! Login karein!')));
        setState(() => isSignUp = false);
      } else {
        await _retryNetwork(() => supabase.auth.signInWithPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim()));
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => OfficerDashboard(
                      officerName: emailController.text.split('@')[0],
                      district: selectedDistrict,
                      post: selectedPost,
                    )));
      }
    } catch (e) {
      _showAuthSnack(context, e);
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
          backgroundColor: Color(0xFF1a3a5c),
          foregroundColor: Colors.white,
          title: Text('👮 Officer Login')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                    value: selectedPost,
                    isExpanded: true,
                    items: posts
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedPost = val!)),
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                    value: selectedDistrict,
                    isExpanded: true,
                    items: districts
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedDistrict = val!)),
              ),
            ),
            SizedBox(height: 12),
            TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none))),
            SizedBox(height: 12),
            TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none))),
            if (!isSignUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(
                                roleTitle: 'Officer',
                                initialEmail: emailController.text.trim(),
                              ),
                            ),
                          ),
                  child: Text('Password bhool gaye?',
                      style: TextStyle(color: Color(0xFF1a3a5c))),
                ),
              ),
            if (isSignUp) ...[
              SizedBox(height: 12),
              TextField(
                  controller: secretCodeController,
                  decoration: InputDecoration(
                      labelText: 'Secret Code (Admin se milega)',
                      prefixIcon: Icon(Icons.key, color: Colors.orange),
                      filled: true,
                      fillColor: Color(0xFFFFF7ED),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none))),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.3))),
                child: Text('⚠️ Secret code sirf admin ke paas hota hai!',
                    style: TextStyle(fontSize: 11, color: Colors.orange[800])),
              ),
            ],
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1a3a5c),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: isLoading ? null : officerLogin,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isSignUp
                          ? 'Officer Account Banayein'
                          : 'Officer Login Karein',
                      style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => isSignUp = !isSignUp),
              child: Text(
                  isSignUp
                      ? 'Pehle se account hai? Login karein'
                      : 'Naya Officer Account Banayein',
                  style: TextStyle(color: Color(0xFF1a3a5c))),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== FORGOT PASSWORD ====================
InputDecoration _authFieldDecoration({
  required String label,
  required IconData icon,
  Color fillColor = Colors.white,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: fillColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

class ForgotPasswordScreen extends StatefulWidget {
  final String roleTitle;
  final String? initialEmail;

  const ForgotPasswordScreen({
    required this.roleTitle,
    this.initialEmail,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController emailController;
  final linkController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool isLoading = false;
  bool linkSent = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    emailController.dispose();
    linkController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  bool _validEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  String? _extractResetToken(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    Uri? uri;
    try {
      if (text.contains('://')) {
        uri = Uri.parse(text);
      } else if (text.contains('code=') ||
          text.contains('token=') ||
          text.contains('token_hash=')) {
        uri = Uri.parse(
            'http://dummy/?${text.replaceFirst(RegExp(r'^\?'), '')}');
      }
    } catch (_) {}
    if (uri != null) {
      final q = Map<String, String>.from(uri.queryParameters);
      if (uri.fragment.contains('=')) {
        q.addAll(Uri.splitQueryString(uri.fragment));
      }
      final token = q['code'] ??
          q['token'] ??
          q['token_hash'] ??
          q['access_token'];
      if (token != null && token.isNotEmpty) return token;
    }
    return text;
  }

  Future<void> _establishRecoverySession(String email, String token) async {
    final isShortOtp = RegExp(r'^\d{6,8}$').hasMatch(token);
    if (isShortOtp) {
      try {
        await supabase.auth.verifyOTP(
          email: email,
          token: token,
          type: OtpType.recovery,
        );
        return;
      } catch (_) {
        await supabase.auth.verifyOTP(
          email: email,
          token: token,
          type: OtpType.email,
        );
        return;
      }
    }
    try {
      await supabase.auth.exchangeCodeForSession(token);
    } catch (_) {
      await supabase.auth.verifyOTP(
        tokenHash: token,
        type: OtpType.recovery,
      );
    }
  }

  Future<void> sendResetLink() async {
    final email = emailController.text.trim();
    if (!_validEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sahi email address likhein!')));
      return;
    }
    setState(() => isLoading = true);
    try {
      await _retryNetwork(() => supabase.auth.resetPasswordForEmail(
            email,
            redirectTo: passwordResetRedirect,
          ));
      setState(() => linkSent = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Mail chali gayi. Gmail mein link ko open mat karo — COPY karke yahan paste karo.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 6),
      ));
    } catch (e) {
      _showAuthSnack(context, e);
    }
    setState(() => isLoading = false);
  }

  Future<void> updatePassword() async {
    final email = emailController.text.trim();
    final pasted = linkController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (pasted.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gmail wala poora link yahan paste karo!')));
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password kam se kam 6 characters ka ho!')));
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Dono password match nahi kar rahe!')));
      return;
    }

    final token = _extractResetToken(pasted);
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Link galat hai. Gmail se poora link copy karo.')));
      return;
    }

    setState(() => isLoading = true);
    try {
      await _establishRecoverySession(email, token);
      await supabase.auth.updateUser(UserAttributes(password: password));
      await supabase.auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Password badal gaya! Ab naya password se login karein.'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Password update nahi hua. Gmail se naya mail lo, poora link copy karke paste karo.\n${_friendlyAuthError(e)}'),
        duration: Duration(seconds: 6),
      ));
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Color(0xFF1a3a5c),
        foregroundColor: Colors.white,
        title: Text('🔑 ${widget.roleTitle} Password Reset'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Apna registered email likhein. Password yahin app mein badlega — Gmail ka page open karne ki zaroorat nahi.',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _authFieldDecoration(
                  label: 'Email', icon: Icons.email),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1a3a5c),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading ? null : sendResetLink,
              child: isLoading && !linkSent
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(linkSent ? 'Link dubara bhejein' : 'Reset link bhejein',
                      style: TextStyle(fontSize: 16)),
            ),
            if (linkSent) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  'Gmail mein jo link aayi hai usko OPEN mat karo (localhost error aayega).\n\n1) Link ko 2 second daba ke Copy link\n2) Neeche paste karo\n3) Naya password likho aur save karo\n\nAgar link khul hi gaya ho to upar address bar ka poora address copy karke paste karo.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1a3a5c), height: 1.4),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: linkController,
                keyboardType: TextInputType.url,
                minLines: 2,
                maxLines: 4,
                decoration: _authFieldDecoration(
                    label: 'Gmail wala poora link paste karo',
                    icon: Icons.link),
              ),
              SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: _authFieldDecoration(
                        label: 'Naya password', icon: Icons.lock)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: _authFieldDecoration(
                    label: 'Password confirm karein', icon: Icons.lock_outline),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading ? null : updatePassword,
                child: isLoading
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Naya password save karein',
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const ResetPasswordScreen({this.onDone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> savePassword() async {
    final password = passwordController.text.trim();
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password kam se kam 6 characters ka ho!')));
      return;
    }
    if (password != confirmController.text.trim()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Dono password match nahi kar rahe!')));
      return;
    }
    setState(() => isLoading = true);
    try {
      await supabase.auth.updateUser(UserAttributes(password: password));
      await supabase.auth.signOut();
      widget.onDone?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Password badal gaya! Ab login karein.'),
        backgroundColor: Colors.green,
      ));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Color(0xFF1a3a5c),
        foregroundColor: Colors.white,
        title: Text('Naya Password'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: _authFieldDecoration(
                  label: 'Naya password', icon: Icons.lock),
            ),
            SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: _authFieldDecoration(
                  label: 'Password confirm karein', icon: Icons.lock_outline),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1a3a5c),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading ? null : savePassword,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Password save karein', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== HOME SCREEN ====================
class HomeScreen extends StatelessWidget {
  final String userName;
  const HomeScreen({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Color(0xFF1a3a5c),
        automaticallyImplyLeading: false,
        title: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 8),
          Text('Jan Seva', style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        actions: [
          IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await supabase.auth.signOut();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => WelcomeScreen()));
              })
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Color(0xFF1a3a5c),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Namaskar, $userName ji 🙏',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Aapki Awaaz, Hamara Farz',
                        style:
                            TextStyle(color: Color(0xFF93C5FD), fontSize: 12)),
                  ]),
            ),
            SizedBox(height: 16),
            Text('SEVA CHUNEIN',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
              children: [
                _ServiceCard(
                    icon: Icons.edit_document,
                    cameraIcon: true,
                    label: 'Shikayat Darz',
                    sub: 'Photo + Location',
                    color: Colors.orange,
                    bgColor: Color(0xFFFFF7ED),
                    borderColor: Colors.orange,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ShikayatScreen(userName: userName)))),
                _ServiceCard(
                    icon: Icons.search,
                    label: 'Status Dekho',
                    sub: 'Shikayat track karein',
                    color: Colors.green,
                    bgColor: Color(0xFFF0FDF4),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => StatusScreen(userName: userName)))),
                _ServiceCard(
                    icon: Icons.campaign,
                    label: 'Notices',
                    sub: 'Sarkari soochna',
                    color: Colors.blue,
                    bgColor: Color(0xFFEFF6FF),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => NoticesScreen()))),
                _ServiceCard(
                    icon: Icons.phone_in_talk,
                    label: 'Helpline',
                    sub: 'Seedha sampark',
                    color: Colors.purple,
                    bgColor: Color(0xFFFAF5FF),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => HelplineScreen()))),
              ],
            ),
            SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => AIHelperScreen())),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10)),
                      child:
                          Icon(Icons.smart_toy, color: Colors.white, size: 20)),
                  SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Sahayak se Baat Karein',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        Text('24/7 Hindi mein madad upalabdh',
                            style: TextStyle(
                                color: Color(0xFFC4B5FD), fontSize: 10)),
                      ]),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Color(0xFF1a3a5c),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.edit_outlined), label: 'Shikayat'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Track'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onTap: (index) {
          if (index == 1)
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ShikayatScreen(userName: userName)));
          if (index == 2)
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => StatusScreen(userName: userName)));
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final Color bgColor;
  final Color? borderColor;
  final bool cameraIcon;
  final VoidCallback onTap;

  const _ServiceCard(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.color,
      required this.bgColor,
      required this.onTap,
      this.borderColor,
      this.cameraIcon = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: borderColor ?? Color(0xFFE2E8F0), width: 1.2)),
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 22)),
              if (cameraIcon)
                Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                            color: Color(0xFF1a3a5c),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 1.5)),
                        child: Icon(Icons.camera_alt,
                            color: Colors.white, size: 9))),
            ]),
            SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
            SizedBox(height: 2),
            Text(sub,
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ==================== SHIKAYAT SCREEN ====================
class ShikayatScreen extends StatefulWidget {
  final String userName;
  const ShikayatScreen({required this.userName});

  @override
  _ShikayatScreenState createState() => _ShikayatScreenState();
}

class _ShikayatScreenState extends State<ShikayatScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final descController = TextEditingController();
  String selectedCategory = 'Sadak';
  bool isSubmitted = false;
  bool isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String? _locationText;
  bool _loadingLocation = false;

  final categories = ['Sadak', 'Bijli', 'Paani', 'Safai', 'Hospital', 'School'];

  @override
  void initState() {
    super.initState();
    nameController.text = widget.userName;
  }

  Future<void> getLocation() async {
    setState(() => _loadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _locationText =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationText = 'Location nahi mili';
        _loadingLocation = false;
      });
    }
  }

  Future<void> pickImage() async {
    showModalBottomSheet(
        context: context,
        builder: (ctx) => Container(
              padding: EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Photo Chunein',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _photoOption(Icons.camera_alt, 'Camera', () async {
                        Navigator.pop(ctx);
                        final XFile? img = await _picker.pickImage(
                            source: ImageSource.camera, imageQuality: 70);
                        if (img != null)
                          setState(() => _selectedImage = File(img.path));
                      }),
                      _photoOption(Icons.photo_library, 'Gallery', () async {
                        Navigator.pop(ctx);
                        final XFile? img = await _picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 70);
                        if (img != null)
                          setState(() => _selectedImage = File(img.path));
                      }),
                    ]),
              ]),
            ));
  }

  Widget _photoOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.orange, size: 28)),
          SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12)),
        ]));
  }

  Future<void> submitComplaint() async {
    if (nameController.text.isEmpty || descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kripya sabhi fields bharein!')));
      return;
    }
    setState(() => isLoading = true);
    try {
      await supabase.from('shikayatein').insert({
        'naam': nameController.text,
        'phone': phoneController.text,
        'category': selectedCategory,
        'description': descController.text,
        'location': _locationText ?? 'Location nahi di',
        'status': 'Pending',
        'district': 'Indore',
      });
      setState(() {
        isLoading = false;
        isSubmitted = true;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
          title: Text('📝 Shikayat Darz Karein'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white),
      body: isSubmitted
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 80),
                  SizedBox(height: 16),
                  Text('Shikayat Darz Ho Gayi! ✅',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Officer ko notification bhej di gayi!',
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Wapas Jao')),
                ]))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                            labelText: 'Aapka Naam',
                            prefixIcon: Icon(Icons.person),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none))),
                    SizedBox(height: 12),
                    TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                            labelText: 'Mobile Number',
                            prefixIcon: Icon(Icons.phone),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none))),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true,
                              items: categories
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => selectedCategory = val!))),
                    ),
                    SizedBox(height: 12),
                    TextField(
                        controller: descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                            labelText: 'Shikayat Likhein',
                            prefixIcon: Icon(Icons.edit),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none))),
                    SizedBox(height: 12),
                    GestureDetector(
                      onTap: getLocation,
                      child: Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _locationText != null
                                    ? Colors.green
                                    : Colors.blue,
                                width: 1.5)),
                        child: Row(children: [
                          Icon(
                              _locationText != null
                                  ? Icons.location_on
                                  : Icons.location_off,
                              color: _locationText != null
                                  ? Colors.green
                                  : Colors.blue),
                          SizedBox(width: 10),
                          Expanded(
                              child: _loadingLocation
                                  ? Text('Location dhundh raha hai...',
                                      style: TextStyle(color: Colors.blue))
                                  : Text(
                                      _locationText ??
                                          'Location Add Karein (GPS)',
                                      style: TextStyle(
                                          color: _locationText != null
                                              ? Colors.green
                                              : Colors.blue,
                                          fontWeight: FontWeight.w500))),
                          if (_loadingLocation)
                            SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                        ]),
                      ),
                    ),
                    SizedBox(height: 12),
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        width: double.infinity,
                        height: _selectedImage != null ? 180 : 90,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.orange, width: 1.5)),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(children: [
                                  Image.file(_selectedImage!,
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover),
                                  Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                          onTap: () => setState(
                                              () => _selectedImage = null),
                                          child: CircleAvatar(
                                              radius: 14,
                                              backgroundColor: Colors.red,
                                              child: Icon(Icons.close,
                                                  color: Colors.white,
                                                  size: 16)))),
                                ]))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Icon(Icons.camera_alt,
                                        color: Colors.orange, size: 30),
                                    SizedBox(height: 6),
                                    Text('Photo Khicho ya Gallery se Chunein',
                                        style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500)),
                                  ]),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: isLoading ? null : submitComplaint,
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Shikayat Darz Karein',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ]),
            ),
    );
  }
}

// ==================== STATUS SCREEN ====================
class StatusScreen extends StatefulWidget {
  final String userName;
  const StatusScreen({required this.userName});

  @override
  _StatusScreenState createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  List<Map<String, dynamic>> complaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadComplaints();
  }

  Future<void> loadComplaints() async {
    try {
      final data = await supabase
          .from('shikayatein')
          .select()
          .eq('naam', widget.userName)
          .order('created_at', ascending: false);
      setState(() {
        complaints = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Jari hai':
        return Colors.blue;
      case 'Hal hua':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
          title: Text('🔍 Meri Shikayatein'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: Icon(Icons.refresh), onPressed: loadComplaints)
          ]),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : complaints.isEmpty
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Icon(Icons.inbox, size: 60, color: Colors.grey[300]),
                      SizedBox(height: 12),
                      Text('Koi shikayat nahi mili',
                          style: TextStyle(color: Colors.grey))
                    ]))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final item = complaints[index];
                    final color = getStatusColor(item['status'] ?? 'Pending');
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Color(0xFFE2E8F0))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text(item['category'] ?? '',
                                      style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500))),
                              Spacer(),
                              Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text(item['status'] ?? 'Pending',
                                      style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500))),
                            ]),
                            SizedBox(height: 8),
                            Text(item['description'] ?? '',
                                style: TextStyle(fontSize: 13)),
                            SizedBox(height: 6),
                            Text('📍 ${item['location'] ?? ''}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500])),
                          ]),
                    );
                  }),
    );
  }
}

// ==================== NOTICES SCREEN ====================
class NoticesScreen extends StatefulWidget {
  @override
  _NoticesScreenState createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  List<Map<String, dynamic>> notices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotices();
  }

  Future<void> loadNotices() async {
    try {
      final data = await supabase
          .from('notices')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        notices = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
          title: Text('📢 Sarkari Notices'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: Icon(Icons.refresh), onPressed: loadNotices)
          ]),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notices.isEmpty
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Icon(Icons.campaign, size: 60, color: Colors.grey[300]),
                      SizedBox(height: 12),
                      Text('Koi notice nahi hai',
                          style: TextStyle(color: Colors.grey))
                    ]))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: notices.length,
                  itemBuilder: (context, index) {
                    final item = notices[index];
                    final isEmergency = item['type'] == 'emergency';
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isEmergency ? Colors.red : Colors.blue,
                              width: isEmergency ? 1.5 : 0.5)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(isEmergency ? Icons.warning : Icons.campaign,
                                  color: isEmergency ? Colors.red : Colors.blue,
                                  size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                  child: Text(item['title'] ?? '',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isEmergency
                                              ? Colors.red
                                              : Colors.blue))),
                            ]),
                            SizedBox(height: 8),
                            Text(item['description'] ?? '',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[700])),
                            SizedBox(height: 6),
                            Text(
                                '📍 ${item['district'] ?? ''} · 👮 ${item['officer'] ?? ''}',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[500])),
                          ]),
                    );
                  }),
    );
  }
}

// ==================== OFFICER DASHBOARD ====================
class OfficerDashboard extends StatefulWidget {
  final String officerName;
  final String district;
  final String post;
  const OfficerDashboard(
      {required this.officerName, required this.district, required this.post});

  @override
  _OfficerDashboardState createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends State<OfficerDashboard> {
  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> notices = [];
  bool isLoading = true;
  int currentTab = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  String _getCategory(String post) {
    switch (post) {
      case 'Bijli Officer':
        return 'Bijli';
      case 'Sadak Officer':
        return 'Sadak';
      case 'Swasthya Officer':
        return 'Hospital';
      case 'Shiksha Officer':
        return 'School';
      case 'Safai Officer':
        return 'Safai';
      default:
        return '';
    }
  }

  Future<void> loadData() async {
    try {
      final complaintData = await supabase
          .from('shikayatein')
          .select()
          .eq('district', widget.district)
          .eq('category', _getCategory(widget.post))
          .order('created_at', ascending: false);
      final noticeData = await supabase
          .from('notices')
          .select()
          .eq('district', widget.district)
          .order('created_at', ascending: false);
      setState(() {
        complaints = List<Map<String, dynamic>>.from(complaintData);
        notices = List<Map<String, dynamic>>.from(noticeData);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateStatus(int id, String status) async {
    try {
      await supabase
          .from('shikayatein')
          .update({'status': status}).eq('id', id);
      loadData();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Status update ho gaya! ✅')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Jari hai':
        return Colors.blue;
      case 'Hal hua':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Color(0xFF1a3a5c),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('👮 ${widget.officerName}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Text('${widget.post} · ${widget.district}',
              style: TextStyle(fontSize: 11, color: Color(0xFF93C5FD))),
        ]),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: loadData),
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await supabase.auth.signOut();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => WelcomeScreen()));
              }),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(children: [
              // Stats
              Container(
                padding: EdgeInsets.all(14),
                color: Color(0xFF1a3a5c),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(
                          'Kul', complaints.length.toString(), Colors.white),
                      _StatCard(
                          'Pending',
                          complaints
                              .where((c) => c['status'] == 'Pending')
                              .length
                              .toString(),
                          Colors.orange),
                      _StatCard(
                          'Jari hai',
                          complaints
                              .where((c) => c['status'] == 'Jari hai')
                              .length
                              .toString(),
                          Colors.blue),
                      _StatCard(
                          'Hal hua',
                          complaints
                              .where((c) => c['status'] == 'Hal hua')
                              .length
                              .toString(),
                          Colors.green),
                    ]),
              ),
              // Tabs
              Container(
                color: Colors.white,
                child: Row(children: [
                  _Tab('📋 Shikayatein', 0),
                  _Tab('📢 Notice Board', 1),
                  _Tab('📊 Analytics', 2),
                ]),
              ),
              Expanded(child: _buildTabContent()),
            ]),
      floatingActionButton: currentTab == 1
          ? FloatingActionButton(
              backgroundColor: Color(0xFF1a3a5c),
              child: Icon(Icons.add),
              onPressed: () => _showAddNoticeDialog(),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Color(0xFF1a3a5c),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: 'Shikayat'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Notice'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Analytics'),
        ],
        onTap: (index) => setState(() => currentTab = index == 0
            ? 0
            : index == 1
                ? 0
                : index == 2
                    ? 1
                    : 2),
      ),
    );
  }

  Widget _Tab(String label, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => currentTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: currentTab == index
                          ? Color(0xFF1a3a5c)
                          : Colors.transparent,
                      width: 2))),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      currentTab == index ? FontWeight.w600 : FontWeight.normal,
                  color:
                      currentTab == index ? Color(0xFF1a3a5c) : Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (currentTab) {
      case 0:
        return _buildComplaintsTab();
      case 1:
        return _buildNoticeTab();
      case 2:
        return _buildAnalyticsTab();
      default:
        return _buildComplaintsTab();
    }
  }

  Widget _buildComplaintsTab() {
    if (complaints.isEmpty)
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox, size: 60, color: Colors.grey[300]),
        SizedBox(height: 12),
        Text('Koi shikayat nahi hai', style: TextStyle(color: Colors.grey))
      ]));
    return ListView.builder(
      padding: EdgeInsets.all(14),
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        final item = complaints[index];
        final color = getStatusColor(item['status'] ?? 'Pending');
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Color(0xFFE2E8F0))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(item['category'] ?? '',
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w500))),
              SizedBox(width: 8),
              Text(item['naam'] ?? '',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Spacer(),
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(item['status'] ?? 'Pending',
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w500))),
            ]),
            SizedBox(height: 8),
            Text(item['description'] ?? '', style: TextStyle(fontSize: 12)),
            SizedBox(height: 6),
            Text('📍 ${item['location'] ?? ''}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            Text('📞 ${item['phone'] ?? ''}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            SizedBox(height: 10),
            Row(children: [
              _StatusBtn('Jari hai', Colors.blue,
                  () => updateStatus(item['id'], 'Jari hai')),
              SizedBox(width: 8),
              _StatusBtn('Hal hua', Colors.green,
                  () => updateStatus(item['id'], 'Hal hua')),
              SizedBox(width: 8),
              _StatusBtn('Reject', Colors.red,
                  () => updateStatus(item['id'], 'Rejected')),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildNoticeTab() {
    return Column(children: [
      if (notices.isEmpty)
        Expanded(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
              Icon(Icons.campaign, size: 60, color: Colors.grey[300]),
              SizedBox(height: 12),
              Text('Koi notice nahi hai', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 12),
              Text('+ button se notice add karein',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12))
            ])))
      else
        Expanded(
            child: ListView.builder(
          padding: EdgeInsets.all(14),
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final item = notices[index];
            final isEmergency = item['type'] == 'emergency';
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isEmergency ? Colors.red : Colors.blue,
                      width: isEmergency ? 1.5 : 0.5)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(isEmergency ? Icons.warning : Icons.campaign,
                          color: isEmergency ? Colors.red : Colors.blue,
                          size: 16),
                      SizedBox(width: 6),
                      Expanded(
                          child: Text(item['title'] ?? '',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600))),
                      GestureDetector(
                        onTap: () async {
                          await supabase
                              .from('notices')
                              .delete()
                              .eq('id', item['id']);
                          loadData();
                        },
                        child: Icon(Icons.delete, color: Colors.red, size: 18),
                      ),
                    ]),
                    SizedBox(height: 6),
                    Text(item['description'] ?? '',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ]),
            );
          },
        )),
    ]);
  }

  Widget _buildAnalyticsTab() {
    final total = complaints.length;
    final pending = complaints.where((c) => c['status'] == 'Pending').length;
    final jariHai = complaints.where((c) => c['status'] == 'Jari hai').length;
    final halHua = complaints.where((c) => c['status'] == 'Hal hua').length;
    final rejected = complaints.where((c) => c['status'] == 'Rejected').length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(14),
      child: Column(children: [
        // Analytics Cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _AnalyticsCard('Kul Shikayatein', total.toString(), Icons.list_alt,
                Colors.blue),
            _AnalyticsCard(
                'Pending', pending.toString(), Icons.pending, Colors.orange),
            _AnalyticsCard(
                'Jari Hai', jariHai.toString(), Icons.work, Colors.purple),
            _AnalyticsCard(
                'Hal Hua', halHua.toString(), Icons.check_circle, Colors.green),
          ],
        ),
        SizedBox(height: 14),
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Color(0xFFE2E8F0))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Shikayat Progress',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            if (total > 0) ...[
              _ProgressBar('Pending', pending, total, Colors.orange),
              SizedBox(height: 8),
              _ProgressBar('Jari Hai', jariHai, total, Colors.blue),
              SizedBox(height: 8),
              _ProgressBar('Hal Hua', halHua, total, Colors.green),
              SizedBox(height: 8),
              _ProgressBar('Rejected', rejected, total, Colors.red),
            ] else
              Text('Koi data nahi hai', style: TextStyle(color: Colors.grey)),
          ]),
        ),
      ]),
    );
  }

  Widget _AnalyticsCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Color(0xFFE2E8F0))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ]),
    );
  }

  Widget _ProgressBar(String label, int value, int total, Color color) {
    final percent = total > 0 ? value / total : 0.0;
    return Row(children: [
      SizedBox(width: 70, child: Text(label, style: TextStyle(fontSize: 11))),
      Expanded(
          child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 8))),
      SizedBox(width: 8),
      Text('$value',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    ]);
  }

  void _showAddNoticeDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String noticeType = 'normal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('📢 Naya Notice Daalo'),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: titleController,
                decoration: InputDecoration(
                    labelText: 'Notice Title', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                    labelText: 'Notice Description',
                    border: OutlineInputBorder())),
            SizedBox(height: 12),
            Row(children: [
              Text('Type: '),
              ChoiceChip(
                  label: Text('Normal'),
                  selected: noticeType == 'normal',
                  onSelected: (_) => setS(() => noticeType = 'normal')),
              SizedBox(width: 8),
              ChoiceChip(
                  label: Text('Emergency'),
                  selected: noticeType == 'emergency',
                  onSelected: (_) => setS(() => noticeType = 'emergency'),
                  selectedColor: Colors.red[100]),
            ]),
          ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFF1a3a5c)),
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                await supabase.from('notices').insert({
                  'title': titleController.text,
                  'description': descController.text,
                  'type': noticeType,
                  'district': widget.district,
                  'officer': widget.officerName,
                });
                Navigator.pop(ctx);
                loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Notice add ho gaya! ✅')));
              },
              child: Text('Add Karein', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _StatCard(String label, String value, Color color) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
    ]);
  }

  Widget _StatusBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

// ==================== HELPLINE SCREEN ====================
class HelplineScreen extends StatelessWidget {
  Future<void> makeCall(String number) async {
    final Uri callUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(callUri)) await launchUrl(callUri);
  }

  final helplines = [
    {
      'section': '🏛️ Sabse Pehle Karein',
      'items': [
        {
          'name': 'CM Helpline MP',
          'sub': 'Sabhi shikayat · 24/7',
          'number': '181',
          'color': Color(0xFF1a3a5c)
        }
      ]
    },
    {
      'section': '⚡ Bijli',
      'items': [
        {
          'name': 'MPPKVVCL (Indore/Ujjain)',
          'sub': 'Bijli shikayat · 24/7',
          'number': '1912',
          'color': Colors.amber
        },
        {
          'name': 'MPEZ (Jabalpur)',
          'sub': 'Bijli shikayat',
          'number': '18001801234',
          'color': Colors.amber
        }
      ]
    },
    {
      'section': '🛣️ Sadak',
      'items': [
        {
          'name': 'MP Lok Nirman Vibhag',
          'sub': 'Sadak shikayat',
          'number': '18002333555',
          'color': Colors.orange
        }
      ]
    },
    {
      'section': '🏥 Hospital',
      'items': [
        {
          'name': 'MP Health Helpline',
          'sub': '24/7 free',
          'number': '104',
          'color': Colors.red
        },
        {
          'name': 'Ambulance',
          'sub': 'Turant madad',
          'number': '108',
          'color': Colors.red
        }
      ]
    },
    {
      'section': '🚨 Emergency',
      'items': [
        {
          'name': 'Police',
          'sub': 'Turant madad',
          'number': '100',
          'color': Colors.red
        },
        {
          'name': 'Fire Brigade',
          'sub': 'Aag lagne par',
          'number': '101',
          'color': Colors.deepOrange
        }
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
          title: Text('📞 Helpline Numbers'),
          backgroundColor: Color(0xFF1a3a5c),
          foregroundColor: Colors.white),
      body: ListView.builder(
        padding: EdgeInsets.all(14),
        itemCount: helplines.length,
        itemBuilder: (context, sIndex) {
          final section = helplines[sIndex];
          final items = section['items'] as List;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(section['section'] as String,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700]))),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Color(0xFFE2E8F0))),
                  child: Column(
                      children: items.map((item) {
                    final isLast = items.indexOf(item) == items.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(
                                  bottom:
                                      BorderSide(color: Color(0xFFF1F5F9)))),
                      child: ListTile(
                        leading: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                (item['color'] as Color).withOpacity(0.1),
                            child: Icon(Icons.phone,
                                color: item['color'] as Color, size: 16)),
                        title: Text(item['name'] as String,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500)),
                        subtitle: Text(item['sub'] as String,
                            style: TextStyle(fontSize: 10)),
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(item['number'] as String,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500)),
                          SizedBox(width: 6),
                          GestureDetector(
                              onTap: () => makeCall(item['number'] as String),
                              child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                      color: Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.call,
                                      color: Colors.green, size: 16))),
                        ]),
                      ),
                    );
                  }).toList()),
                ),
                SizedBox(height: 4),
              ]);
        },
      ),
    );
  }
}

// ==================== AI HELPER SCREEN ====================
class AIHelperScreen extends StatefulWidget {
  @override
  _AIHelperScreenState createState() => _AIHelperScreenState();
}

class _AIHelperScreenState extends State<AIHelperScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = [];
  bool isLoading = false;

  Future<void> sendMessage(String userMessage) async {
    setState(() {
      messages.add({'role': 'user', 'content': userMessage});
      isLoading = true;
    });
    _controller.clear();
    await Future.delayed(Duration(milliseconds: 800));
    setState(() {
      messages.add({
        'role': 'assistant',
        'content': getAIResponse(userMessage.toLowerCase())
      });
      isLoading = false;
    });
  }

  String getAIResponse(String message) {
    if (message.contains('bijli') || message.contains('light'))
      return '⚡ Bijli ki shikayat ke liye:\n\n• MPPKVVCL: 1912\n• CM Helpline: 181';
    if (message.contains('sadak') || message.contains('road'))
      return '🛣️ Sadak ki shikayat ke liye:\n\n• PWD: 1800-233-3555\n• CM Helpline: 181';
    if (message.contains('paani') || message.contains('water'))
      return '💧 Paani ki shikayat ke liye:\n\n• CM Helpline: 181';
    if (message.contains('hospital') || message.contains('doctor'))
      return '🏥 Hospital ke liye:\n\n• Health Helpline: 104\n• Ambulance: 108';
    if (message.contains('namaste') ||
        message.contains('hello') ||
        message.contains('hi'))
      return '🙏 Namaskar! Main Jan Seva AI hun!\n\nKya madad chahiye?\n• Bijli\n• Sadak\n• Paani\n• Hospital';
    return '🙏 Apni samasya batayein!\n\nYa seedha CM Helpline 181 pe call karein!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
          title: Text('🤖 AI Sahayak'),
          backgroundColor: Color(0xFF4F46E5),
          foregroundColor: Colors.white),
      body: Column(children: [
        Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(Icons.smart_toy,
                            size: 60, color: Colors.purple[200]),
                        SizedBox(height: 12),
                        Text('AI Sahayak se kuch bhi puchein!',
                            style: TextStyle(color: Colors.grey))
                      ]))
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            padding: EdgeInsets.all(12),
                            constraints: BoxConstraints(maxWidth: 280),
                            decoration: BoxDecoration(
                                color:
                                    isUser ? Color(0xFF4F46E5) : Colors.white,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(msg['content']!,
                                style: TextStyle(
                                    color:
                                        isUser ? Colors.white : Colors.black87,
                                    fontSize: 13))),
                      );
                    })),
        if (isLoading)
          Padding(
              padding: EdgeInsets.all(8),
              child: Row(children: [
                SizedBox(width: 16),
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF4F46E5))),
                SizedBox(width: 8),
                Text('AI soch raha hai...',
                    style: TextStyle(color: Colors.grey, fontSize: 12))
              ])),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)]),
          child: Row(children: [
            Expanded(
                child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                        hintText: 'Sawaal likhein...',
                        filled: true,
                        fillColor: Color(0xFFF0F4F8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10)))),
            SizedBox(width: 8),
            CircleAvatar(
                backgroundColor: Color(0xFF4F46E5),
                child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () {
                      if (_controller.text.isNotEmpty)
                        sendMessage(_controller.text);
                    })),
          ]),
        ),
      ]),
    );
  }
}
