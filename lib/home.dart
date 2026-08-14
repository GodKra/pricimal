import 'package:flutter/material.dart';
import 'package:pricimal/basket.dart';
import 'package:go_router/go_router.dart';


class HomeLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeLayout({
    super.key, 
    required this.navigationShell
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Header(
            selectedIndex: navigationShell.currentIndex,
            onPageSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
          ),

          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1300,
                ),
                child: navigationShell,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class Header extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onPageSelected;


  const Header({
    super.key,
    required this.selectedIndex,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      color: const Color(0xFF17191A),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          const Text(
            'Pricimal',
            style: TextStyle(
              color: Color(0xBC35E544),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 20),

          const VerticalDivider(
            color: Color(0xA09E9E9E),
            indent: 20,
            endIndent: 20,

          ),

          const SizedBox(width: 20),


          Expanded(
            child: NavBar(
              selectedIndex: selectedIndex,
              onPageSelected: onPageSelected,
            ),
          ),

          const SizedBox(width: 40),

          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 26,
              ),
              SizedBox(height: 4),
              Text(
                "Account",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onPageSelected;

  const NavBar({
    super.key,
    required this.selectedIndex,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      const _NavItemData(icon: Icons.shopping_cart_outlined, text: 'My Basket'),
      const _NavItemData(icon: Icons.storefront_outlined, text: 'My Shops'),
      const _NavItemData(icon: Icons.local_offer_outlined, text: 'Deals'),
      const _NavItemData(icon: Icons.history, text: 'Basket History'),
    ];


  return Row(
      children: List.generate(navItems.length, (index) {
        final item = navItems[index];
        return _NavItem(
          icon: item.icon,
          text: item.text,
          selected: selectedIndex == index,
          onTap: () => onPageSelected(index),
        );
      }),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String text;

  const _NavItemData({required this.icon, required this.text});
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.text,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material (
        color: Colors.transparent,
        child: InkWell (
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
          splashColor: const Color(0xBC35E544),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? const Color(0xBC35E544)
                      : Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white70,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
