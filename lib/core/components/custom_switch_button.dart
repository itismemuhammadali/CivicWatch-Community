import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

class CustomSwitchButton extends StatefulWidget {
  const CustomSwitchButton({
    super.key,
    required this.onToggle,
    this.isToggled = false,
  });
  final ValueChanged<bool> onToggle;
  final bool isToggled;

  @override
  State<CustomSwitchButton> createState() => _CustomSwitchButtonState();
}

class _CustomSwitchButtonState extends State<CustomSwitchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.isToggled ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant CustomSwitchButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isToggled != widget.isToggled) {
      if (widget.isToggled) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleButton() {
    // Controlled: delegate state change to parent via callback
    widget.onToggle(!widget.isToggled);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleButton,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: 57,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              // gradient: widget.isToggled
              //     ? LinearGradient(
              //         colors: [kGradientGreyColor, kLimeGreenColor],
              //         stops: [0.0, 1.0],
              //         begin: Alignment.centerLeft,
              //         end: Alignment.centerRight,
              //       )
              //     : null,
              color: widget.isToggled ? kPrimaryColor : kContainerGreyColor,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 2, left: 4),
              child: Stack(
                children: [
                  Positioned(
                    left: _animationController.value * 26,
                    child: CircleAvatar(
                      backgroundColor: kWhiteColor,
                      radius: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
