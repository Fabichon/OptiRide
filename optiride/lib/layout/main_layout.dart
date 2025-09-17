import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.3),
        title: Row(
          children: [
            // Logo OptiRide
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'OptiRide',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Spacer(),
            // Navigation tabs comme Uber
            Row(
              children: [
                _buildNavTab(
                  context,
                  title: 'Recherche',
                  route: '/',
                  icon: Icons.search,
                  isActive: currentRoute == '/',
                ),
                const SizedBox(width: 8),
                _buildNavTab(
                  context,
                  title: 'Offres',
                  route: '/offers',
                  icon: Icons.local_offer,
                  isActive: currentRoute == '/offers',
                ),
              ],
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: child,
    );
  }

  Widget _buildNavTab(
    BuildContext context, {
    required String title,
    required String route,
    required IconData icon,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive 
            ? Border.all(color: Colors.blue, width: 1)
            : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.blue : Colors.grey[600],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
