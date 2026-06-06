import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home_screen.dart';
import 'login_screen.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _restaurantNameController = TextEditingController();

  bool _obscurePassword = true;
  String _businessType = 'restaurant';

  final List<String> _foodImages = [
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500&q=80',
    'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=500&q=80',
    'https://images.unsplash.com/photo-1484723091791-c11756247fb2?w=500&q=80',
    'https://images.unsplash.com/photo-1493770348161-369560ae357d?w=500&q=80',
    'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=500&q=80',
    'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=500&q=80',
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&q=80',
    'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=500&q=80',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _restaurantNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = context.read<AuthProvider>();
    
    await authProvider.register(
      name: _restaurantNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: '0000000000', // Placeholder since phone was removed from UI
    );

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Center(child: _buildForm(context)),
                  ),
                  Expanded(
                    flex: 1,
                    child: _buildImageGrid(),
                  ),
                ],
              );
            } else {
              return Center(child: _buildForm(context));
            }
          },
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _foodImages.length,
        itemBuilder: (context, index) {
          return Image.network(
            _foodImages[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.restaurant)),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Logo
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: AppRadius.borderMedium,
              ),
              child: const Icon(Icons.restaurant, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 24),
            Text(
              'Create Account',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account? ",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: Text(
                    'Sign In',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Business Type', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.inputDecorationTheme.fillColor,
                      borderRadius: AppRadius.borderMedium,
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _businessType,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: const [
                          DropdownMenuItem(value: 'restaurant', child: Text('Restaurant')),
                          DropdownMenuItem(value: 'food_truck', child: Text('Food Truck')),
                          DropdownMenuItem(value: 'cafe', child: Text('Cafe')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _businessType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Full Name', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Type your full name',
                    icon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'Name required' : null,
                  ),
                  const SizedBox(height: 20),
                  Text('Business Name', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _restaurantNameController,
                    hint: 'Type your business name',
                    icon: Icons.storefront_outlined,
                    validator: (v) => v!.isEmpty ? 'Business name required' : null,
                  ),
                  const SizedBox(height: 20),
                  Text('Email', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Type your email address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Password', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Type your password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: theme.iconTheme.color?.withOpacity(0.5),
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: auth.state == AuthState.loading ? null : _register,
                          child: auth.state == AuthState.loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Sign Up'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}
