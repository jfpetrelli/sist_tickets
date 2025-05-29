// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'package:sist_tickets/administrator/home_page.dart';


const Color kPrimaryColor = Color(0xFFE74C3C); // E74C3C

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column( 
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [

              Container(
                height: constraints.maxHeight * 0.28, 
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -constraints.maxWidth * 0.1,
                      left: -constraints.maxWidth * 0.1,
                      child: Container(
                        width: constraints.maxWidth * 0.6,
                        height: constraints.maxWidth * 0.6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: constraints.maxWidth * 0.1,
                      right: -constraints.maxWidth * 0.1,
                      child: Container(
                        width: constraints.maxWidth * 0.4,
                        height: constraints.maxWidth * 0.4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                     Positioned(
                      top: constraints.maxWidth * 0.05,
                      left: constraints.maxWidth * 0.05,
                      child: Container(
                        width: constraints.maxWidth * 0.5,
                        height: constraints.maxWidth * 0.5,
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                    ),
                     Positioned(
                      bottom: constraints.maxWidth * 0.1,
                      right: constraints.maxWidth * 0.1,
                      child: Container(
                        width: constraints.maxWidth * 0.2,
                        height: constraints.maxWidth * 0.2,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'App UTP',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              Expanded( 
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0), 
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 26, 
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 15), 
                      _buildTextField(
                        hint: 'Usuario, email, teléfono celular',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 10), 
                      _buildTextField(
                        hint: 'Contraseña',
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 10), 
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(color: Colors.grey[700], fontSize: 13), 
                          ),
                        ),
                      ),
                      const SizedBox(height: 15), 
                      _buildLoginButton(context),
                      const SizedBox(height: 15), 
                      Center(
                        child: Text(
                          'O Ingresa con',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 15), 
                      _buildSocialLoginButtons(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10), 
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage(initialIndex: 1)), 
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor, 
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
        ),
        child: const Text(
          'Ingresar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          icon: Icons.g_mobiledata,
          onPressed: () {},
        ),
        const SizedBox(width: 15), 
        _buildSocialButton(
          icon: Icons.facebook,
          onPressed: () {},
        ),
        const SizedBox(width: 15), 
        _buildSocialButton(
          icon: Icons.apple,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSocialButton({required IconData icon, required VoidCallback onPressed, Widget? child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: child ?? Icon(icon, size: 28, color: Colors.grey[700]), 
        onPressed: onPressed,
      ),
    );
  }
}
