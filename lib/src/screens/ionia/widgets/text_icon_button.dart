import 'package:elite_wallet/typography.dart';
import 'package:flutter/material.dart';

class TextIconButton extends StatelessWidget {
  const TextIconButton({
    Key? key,
    required this.label,
    this.onTap,
  }) : super(key: key);

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return 
       InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: textMediumSemiBold(
                color: Theme.of(context).primaryTextTheme!.titleLarge!.color!,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).primaryTextTheme!.titleLarge!.color!,
            ),
          ],
        ),
    );
  }
}
