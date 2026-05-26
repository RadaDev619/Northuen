import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
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
  String _role = 'CUSTOMER';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F6F1), Color(0xFFF1E7D3)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD2AB50),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.near_me_rounded,
                            color: Color(0xFF1E1E1E),
                            size: 38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Welcome to Northuen',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Move Anything, Anywhere',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(
                                    value: false,
                                    label: Text('Login'),
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
                              const SizedBox(height: 18),
                              if (_register) ...[
                                TextFormField(
                                  controller: _name,
                                  decoration: const InputDecoration(
                                    labelText: 'Full name',
                                    prefixIcon: Icon(Icons.person_rounded),
                                  ),
                                  validator: _required,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField(
                                  initialValue: _role,
                                  decoration: const InputDecoration(
                                    labelText: 'Role',
                                    prefixIcon: Icon(Icons.badge_rounded),
                                  ),
                                  items: const ['CUSTOMER', 'DRIVER', 'VENDOR']
                                      .map(
                                        (role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(role),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _role = value!),
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone number',
                                  prefixIcon: Icon(Icons.phone_rounded),
                                ),
                                validator: _required,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_rounded),
                                ),
                                validator: _required,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_rounded),
                                ),
                                validator: _required,
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                onPressed: app.loading ? null : _submit,
                                icon: app.loading
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.arrow_forward_rounded),
                                label: Text(
                                  _register ? 'Create Account' : 'Login',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (app.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            app.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
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
      value == null || value.trim().isEmpty ? 'Required' : null;

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
