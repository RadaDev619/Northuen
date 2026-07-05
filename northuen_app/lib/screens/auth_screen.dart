import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/northuen_ui.dart';
import 'role_home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController(text: 'customer@northuen.bt');
  final _phone = TextEditingController(text: '+97517123456');
  final _password = TextEditingController(text: 'password123');
  bool _register = false;
  bool _passwordVisible = false;
  String _role = 'CUSTOMER';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40,
                maxWidth: 480,
              ),
              child: Center(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: NorthuenBrandMark(size: 54),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _register ? 'Create your account' : 'Welcome back',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _register
                            ? 'Join Northuen and start moving what matters.'
                            : 'Sign in to continue your deliveries.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: NorthuenTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Sign in'),
                            icon: Icon(Icons.login_rounded),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Register'),
                            icon: Icon(Icons.person_add_alt_1_rounded),
                          ),
                        ],
                        selected: {_register},
                        onSelectionChanged: (value) =>
                            setState(() => _register = value.first),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_register) ...[
                                TextFormField(
                                  controller: _name,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Full name',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: _required,
                                ),
                                const SizedBox(height: 12),
                                _RolePicker(
                                  value: _role,
                                  onChanged: (value) =>
                                      setState(() => _role = value),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phone,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone number',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                  validator: _required,
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email address',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                                validator: _required,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                obscureText: !_passwordVisible,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _passwordVisible
                                        ? 'Hide password'
                                        : 'Show password',
                                    onPressed: () => setState(
                                      () =>
                                          _passwordVisible = !_passwordVisible,
                                    ),
                                    icon: Icon(
                                      _passwordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                validator: _required,
                              ),
                              if (!_register)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: null,
                                    child: const Text('Forgot password?'),
                                  ),
                                )
                              else
                                const SizedBox(height: 18),
                              if (app.error != null) ...[
                                NorthuenErrorBanner(message: app.error!),
                                const SizedBox(height: 14),
                              ],
                              ElevatedButton.icon(
                                onPressed: app.loading ? null : _submit,
                                icon: app.loading
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        _register
                                            ? Icons.person_add_alt_1_rounded
                                            : Icons.arrow_forward_rounded,
                                      ),
                                label: Text(
                                  _register
                                      ? 'Create account'
                                      : 'Sign in to Northuen',r
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Food, shop and local delivery services in one app.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: NorthuenTheme.muted,
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
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final app = context.read<AppState>();
    if (_register) {
      await app.register(
        _name.text,
        _email.text,
        _phone.text,
        _password.text,
        _role,
      );
    } else {
      await app.login(_email.text, _password.text);
    }
    if (mounted && app.authenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleHomeScreen()),
      );
    }
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const roles = [
      ('CUSTOMER', 'Customer', Icons.person_outline),
      ('DRIVER', 'Runner', Icons.delivery_dining_outlined),
      ('VENDOR', 'Vendor', Icons.storefront_outlined),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account type',
          style: TextStyle(
            color: NorthuenTheme.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: roles.map((role) {
            final selected = value == role.$1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: role != roles.last ? 8 : 0),
                child: InkWell(
                  onTap: () => onChanged(role.$1),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? NorthuenTheme.primary.withValues(alpha: .08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? NorthuenTheme.primary
                            : NorthuenTheme.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          role.$3,
                          color: selected
                              ? NorthuenTheme.primary
                              : NorthuenTheme.muted,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          role.$2,
                          style: TextStyle(
                            color: selected
                                ? NorthuenTheme.primary
                                : NorthuenTheme.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
