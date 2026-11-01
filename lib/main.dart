import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(const ConfigApp());
    return;
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const DigitalTradeHubApp());
}

const Color brandNavy = Color(0xFF101B3F);
const Color brandBlue = Color(0xFF3157D5);
const Color brandSky = Color(0xFF6C8CFF);
const Color pageBackground = Color(0xFFF3F6FF);

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: brandBlue,
    brightness: Brightness.light,
    primary: brandBlue,
    surface: Colors.white,
  ),
  useMaterial3: true,
  scaffoldBackgroundColor: pageBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: brandNavy,
    elevation: 0,
    centerTitle: false,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF7F8FC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    labelStyle: const TextStyle(color: Color(0xFF667085)),
    prefixIconColor: brandBlue,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFE3E8F4)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFE3E8F4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: brandBlue, width: 1.6),
    ),
  ),
);

final db = Supabase.instance.client;

class ConfigApp extends StatelessWidget {
  const ConfigApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Digital Trade Hub\n\nSupabase config missing. Run with --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=...',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
}

class DigitalTradeHubApp extends StatelessWidget {
  const DigitalTradeHubApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Digital Trade Hub',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: const AuthGate(),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
        stream: db.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (db.auth.currentSession == null) return const AuthPage();
          return const HomePage();
        },
      );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool signup = false;
  bool busy = false;
  bool hidePassword = true;
  String? error;

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (signup) {
        await db.auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'full_name': name.text.trim()},
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account request submitted. Check your email if confirmation is enabled.'),
            ),
          );
        }
      } else {
        await db.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on AuthException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Something went wrong. Please try again.';
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [brandNavy, Color(0xFF1C3475), brandBlue],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 17),
                    const Text(
                      'DIGITAL TRADE HUB',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Your trusted digital marketplace',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Card(
                      elevation: 18,
                      shadowColor: Colors.black.withOpacity(0.25),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(23, 27, 23, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              signup ? 'Create your account' : 'Welcome back',
                              style: const TextStyle(
                                color: brandNavy,
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              signup
                                  ? 'Join the hub and explore digital services.'
                                  : 'Sign in to continue to your marketplace.',
                              style: const TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 25),
                            if (signup) ...[
                              TextField(
                                controller: name,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextField(
                              controller: email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: password,
                              obscureText: hidePassword,
                              autofillHints: [
                                signup
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  tooltip: hidePassword ? 'Show password' : 'Hide password',
                                  onPressed: () => setState(
                                    () => hidePassword = !hidePassword,
                                  ),
                                  icon: Icon(
                                    hidePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),
                            if (error != null) ...[
                              const SizedBox(height: 13),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  error!,
                                  style: const TextStyle(
                                    color: Color(0xFFB42318),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 54,
                              child: FilledButton(
                                onPressed: busy ? null : submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: brandBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: busy
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        signup ? 'CREATE ACCOUNT' : 'SIGN IN',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () => setState(() {
                                        signup = !signup;
                                        error = null;
                                      }),
                              child: Text(
                                signup
                                    ? 'Already have an account? Sign in'
                                    : 'New to Digital Trade Hub? Create account',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: brandBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Trade smarter. Connect with confidence.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  final pages = const [
    MarketplaceTab(),
    ReferralTab(),
    MyActivityTab(),
    AccountTab(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Digital Trade Hub'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => db.auth.signOut(),
              icon: const Icon(Icons.logout),
            )
          ],
        ),
        body: pages[tab],
        floatingActionButton: tab == 0 || tab == 1
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateListingPage(),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Create listing'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.storefront), label: 'Market'),
            NavigationDestination(icon: Icon(Icons.link), label: 'Referrals'),
            NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Activity'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      );
}

class MarketplaceTab extends StatelessWidget {
  const MarketplaceTab({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: db
            .from('listings')
            .select()
            .eq('status', 'approved')
            .order('created_at', ascending: false),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Could not load listings: ${snap.error}'));
          }
          final items = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _HeroCard(),
              const SizedBox(height: 16),
              const Text(
                'Approved digital services',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No approved listings yet. Create a listing and wait for admin review.',
                  ),
                ),
              ...items.map((x) => ListingCard(item: x)),
            ],
          );
        },
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [brandNavy, brandBlue],
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trade digital services with confidence',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Discover approved services and official referral offers.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
}

class ListingCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const ListingCard({super.key, required this.item});
  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(top: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE7EAF2)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFEAF0FF),
            foregroundColor: brandBlue,
            child: Icon(
              item['listing_type'] == 'referral'
                  ? Icons.link
                  : Icons.design_services,
            ),
          ),
          title: Text(
            item['title'] ?? 'Untitled',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${item['platform'] ?? 'General'} • ${item['description'] ?? ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            item['price_amount'] == null
                ? 'Contact'
                : '${item['price_currency'] ?? 'PKR'} ${item['price_amount']}',
            style: const TextStyle(
              color: brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailPage(item: item),
            ),
          ),
        ),
      );
}

class ReferralTab extends StatelessWidget {
  const ReferralTab({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: db
            .from('listings')
            .select()
            .eq('status', 'approved')
            .eq('listing_type', 'referral')
            .order('created_at', ascending: false),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Could not load referrals: ${snap.error}'));
          }
          final rows = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Official referral offers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Only official links and promotion details. Never share passwords, OTPs, or account access.',
              ),
              ...rows.map((x) => ListingCard(item: x)),
              const SizedBox(height: 80),
            ],
          );
        },
      );
}

class ListingDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;
  const ListingDetailPage({super.key, required this.item});

  Future<void> request(BuildContext context) async {
    try {
      await db.from('referral_requests').insert({
        'requester_id': db.auth.currentUser!.id,
        'platform': item['platform'],
        'request_type':
            item['listing_type'] == 'referral' ? 'referral' : 'service',
        'notes': 'Interested in listing: ${item['title']}',
        'status': 'pending',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted for admin review.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not submit request. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Listing details')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['title'] ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('${item['platform'] ?? ''} • ${item['listing_type'] ?? ''}'),
              const SizedBox(height: 16),
              Text(item['description'] ?? ''),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => request(context),
                  child: const Text('Request / Contact'),
                ),
              ),
            ],
          ),
        ),
      );
}

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});
  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final title = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final url = TextEditingController();
  String type = 'service';
  String platform = 'Instagram';
  bool busy = false;
  final platforms = const [
    'Facebook',
    'Instagram',
    'LinkedIn',
    'Binance',
    'OKX',
    'Bitget',
    'Gate.io',
    'Other',
  ];

  Future<void> save() async {
    if (title.text.trim().isEmpty || description.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      await db.from('listings').insert({
        'seller_id': db.auth.currentUser!.id,
        'title': title.text.trim(),
        'description': description.text.trim(),
        'listing_type': type,
        'platform': platform,
        'price_amount': double.tryParse(price.text),
        'price_currency': 'PKR',
        'official_url': url.text.trim().isEmpty ? null : url.text.trim(),
        'status': 'pending',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing submitted for admin approval.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save listing. Check details and try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    price.dispose();
    url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create listing')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField(
              value: type,
              decoration: const InputDecoration(
                labelText: 'Listing type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'service',
                  child: Text('Digital service'),
                ),
                DropdownMenuItem(
                  value: 'referral',
                  child: Text('Official referral offer'),
                ),
              ],
              onChanged: (v) => setState(() => type = v ?? 'service'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: platform,
              decoration: const InputDecoration(
                labelText: 'Platform',
                border: OutlineInputBorder(),
              ),
              items: platforms
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => platform = v ?? 'Other'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description (no passwords or OTPs)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price in PKR (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: url,
              decoration: const InputDecoration(
                labelText: 'Official referral URL (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: busy ? null : save,
              child: Text(busy ? 'Submitting…' : 'Submit for approval'),
            ),
          ],
        ),
      );
}

class MyActivityTab extends StatelessWidget {
  const MyActivityTab({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: db
            .from('referral_requests')
            .select()
            .eq('requester_id', db.auth.currentUser!.id)
            .order('created_at', ascending: false),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Could not load activity: ${snap.error}'));
          }
          final rows = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'My requests',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (rows.isEmpty) const Text('Your requests will appear here.'),
              ...rows.map(
                (r) => Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(r['platform'] ?? 'Request'),
                    subtitle: Text(r['notes'] ?? ''),
                    trailing: Chip(label: Text(r['status'] ?? 'pending')),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      );
}

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: () async {
          final result = await db
              .from('profiles')
              .select()
              .eq('id', db.auth.currentUser!.id)
              .maybeSingle();
          return result ?? <String, dynamic>{};
        }(),
        builder: (context, snap) {
          final profile = snap.data ?? {};
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const CircleAvatar(
                radius: 34,
                child: Icon(Icons.person, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                profile['full_name'] ??
                    db.auth.currentUser?.email ??
                    'User',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Role: ${profile['role'] ?? 'user'}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Card(
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Payments: JazzCash and Easypaisa are planned. This MVP records payment references for admin review; live collection requires approved merchant API access.',
                  ),
                ),
              ),
            ],
          );
        },
      );
}
