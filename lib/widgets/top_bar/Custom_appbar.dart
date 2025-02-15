import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int goldCount;
  final int silverCount;
  final int purpleCount;

  const CustomAppBar({
    super.key,
    this.goldCount = 12,
    this.silverCount = 6,
    this.purpleCount = 2,
  });

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 4,
      centerTitle: false,
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: const CircleAvatar(
          backgroundColor: Color(0xFFEEEEEE),
          radius: 25,
          child: Icon(Icons.person, color: Colors.grey, size: 30),
        ),
      ),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Hi, Sketcher! Welcome!',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        _buildCounter('assets/image/3.png', goldCount),
        const SizedBox(width: 12),
        _buildCounter('assets/image/2.png', silverCount),
        const SizedBox(width: 12),
        _buildCounter('assets/image/1.png', purpleCount),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildCounter(String assetPath, int count) {
    return Row(
      children: [
        Image.asset(
          assetPath,
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 6),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
