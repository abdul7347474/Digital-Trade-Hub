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
            'Digital Trade Hub\\n\\nSupabase config missing. Run with --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=...',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB), brightness: Brightness.light),
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFF6F8FC),
  appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Color(0xFF101828), elevation: 0),
);

final db = Supabase.instance.client;

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
  bool signup = false, busy = false;
  String? error;

  Future<void> submit() async {
    setState(() { busy = true; error = null; });
    try {
      if (signup) {
        await db.auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'full_name': name.text.trim()},
        );
      } else {
        await db.auth.signInWithPassword(email: email.text.trim(), password: password.text);
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
  void dispose() { email.dispose(); password.dispose(); name.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Card(
        elevation: 0, child: Padding(padding: const EdgeInsets.all(24), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.storefront_rounded, size: 52, color: Color(0xFF2563EB)),
            const SizedBox(height: 12),
            const Text('Digital Trade Hub', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(signup ? 'Create your marketplace account' : 'Sign in to continue', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (signup) TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder())),
            if (signup) const SizedBox(height: 12),
            TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 18),
            FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Please wait…' : signup ? 'Create account' : 'Sign in')),
            TextButton(onPressed: () => setState(() { signup = !signup; error = null; }), child: Text(signup ? 'Already registered? Sign in' : 'New here? Create account')),
          ],
        )),
      )),
    ))),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab = 0;
  final pages = const [MarketplaceTab(), ReferralTab(), MyActivityTab(), AccountTab()];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Digital Trade Hub'), actions: [
      IconButton(tooltip: 'Sign out', onPressed: () => db.auth.signOut(), icon: const Icon(Icons.logout))
    ]),
    body: pages[tab],
    floatingActionButton: tab == 0 || tab == 1 ? FloatingActionButton.extended(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListingPage())),
      icon: const Icon(Icons.add), label: const Text('Create listing'),
    ) : null,
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
    future: db.from('listings').select().eq('status', 'approved').order('created_at', ascending: false),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return Center(child: Text('Could not load listings: ${snap.error}'));
      final items = snap.data ?? [];
      return ListView(padding: const EdgeInsets.all(16), children: [
        const _HeroCard(),
        const SizedBox(height: 16),
        const Text('Approved digital services', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        if (items.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No approved listings yet. Create a listing and wait for admin review.')),
        ...items.map((x) => ListingCard(item: x)),
      ]);
    },
  );
}
class _HeroCard extends StatelessWidget {
  const _HeroCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF102A56), Color(0xFF2563EB)])),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Trade digital services with confidence', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text('Discover approved services and official referral offers.', style: TextStyle(color: Colors.white70)),
    ]),
  );
}

class ListingCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const ListingCard({super.key, required this.item});
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0, margin: const EdgeInsets.only(top: 10),
    child: ListTile(
      leading: CircleAvatar(child: Icon(item['listing_type'] == 'referral' ? Icons.link : Icons.design_services)),
      title: Text(item['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${item['platform'] ?? 'General'} • ${item['description'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(item['price_amount'] == null ? 'Contact' : '${item['price_currency'] ?? 'PKR'} ${item['price_amount']}'),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailPage(item: item))),
    ),
  );
}

class ReferralTab extends StatelessWidget {
  const ReferralTab({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: db.from('listings').select().eq('status', 'approved').eq('listing_type', 'referral').order('created_at', ascending: false),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return Center(child: Text('Could not load referrals: ${snap.error}'));
      final rows = snap.data ?? [];
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Official referral offers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Only official links and promotion details. Never share passwords, OTPs, or account access.'),
        ...rows.map((x) => ListingCard(item: x)),
        const SizedBox(height: 80),
      ]);
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
        'request_type': item['listing_type'] == 'referral' ? 'referral' : 'service',
        'notes': 'Interested in listing: ${item['title']}',
        'status': 'pending',
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted for admin review.')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not submit request. Please try again.')));
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Listing details')),
    body: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(item['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('${item['platform'] ?? ''} • ${item['listing_type'] ?? ''}'),
      const SizedBox(height: 16),
      Text(item['description'] ?? ''),
      const Spacer(),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: () => request(context), child: const Text('Request / Contact'))),
    ])),
  );
}

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});
  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}
class _CreateListingPageState extends State<CreateListingPage> {
  final title = TextEditingController(), description = TextEditingController(), price = TextEditingController(), url = TextEditingController();
  String type = 'service', platform = 'Instagram';
  bool busy = false;
  final platforms = const ['Facebook', 'Instagram', 'LinkedIn', 'Binance', 'OKX', 'Bitget', 'Gate.io', 'Other'];
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
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing submitted for admin approval.'))); Navigator.pop(context); }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save listing. Check details and try again.')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  void dispose() { title.dispose(); description.dispose(); price.dispose(); url.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create listing')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      DropdownButtonFormField(value: type, decoration: const InputDecoration(labelText: 'Listing type', border: OutlineInputBorder()), items: const [
        DropdownMenuItem(value: 'service', child: Text('Digital service')),
        DropdownMenuItem(value: 'referral', child: Text('Official referral offer')),
      ], onChanged: (v) => setState(() => type = v ?? 'service')),
      const SizedBox(height: 12),
      DropdownButtonFormField(value: platform, decoration: const InputDecoration(labelText: 'Platform', border: OutlineInputBorder()), items: platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (v) => setState(() => platform = v ?? 'Other')),
      const SizedBox(height: 12),
      TextField(controller: title, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: description, maxLines: 4, decoration: const InputDecoration(labelText: 'Description (no passwords or OTPs)', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price in PKR (optional)', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: url, decoration: const InputDecoration(labelText: 'Official referral URL (optional)', border: OutlineInputBorder())),
      const SizedBox(height: 20),
      FilledButton(onPressed: busy ? null : save, child: Text(busy ? 'Submitting…' : 'Submit for approval')),
    ]),
  );
}

class MyActivityTab extends StatelessWidget {
  const MyActivityTab({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: db.from('referral_requests').select().eq('requester_id', db.auth.currentUser!.id).order('created_at', ascending: false),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return Center(child: Text('Could not load activity: ${snap.error}'));
      final rows = snap.data ?? [];
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('My requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (rows.isEmpty) const Text('Your requests will appear here.'),
        ...rows.map((r) => Card(elevation: 0, child: ListTile(
          title: Text(r['platform'] ?? 'Request'),
          subtitle: Text(r['notes'] ?? ''),
          trailing: Chip(label: Text(r['status'] ?? 'pending')),
        ))),
        const SizedBox(height: 80),
      ]);
    },
  );
}

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: db.from('profiles').select().eq('id', db.auth.currentUser!.id).maybeSingle(),
    builder: (context, snap) {
      final profile = snap.data ?? {};
      return ListView(padding: const EdgeInsets.all(20), children: [
        const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 36)),
        const SizedBox(height: 12),
        Text(profile['full_name'] ?? db.auth.currentUser?.email ?? 'User', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('Role: ${profile['role'] ?? 'user'}', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        const Card(elevation: 0, child: Padding(padding: EdgeInsets.all(16), child: Text('Payments: JazzCash and Easypaisa are planned. This MVP records payment references for admin review; live collection requires approved merchant API access.'))),
      ]);
    },
  );
}
