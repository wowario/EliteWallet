import 'package:flutter/material.dart';
import 'package:elite_wallet/palette.dart';

class PickerItemWidget extends StatelessWidget {
  const PickerItemWidget({
    required this.title,
    this.iconPath,
    this.isSelected = false,
    this.tag,
    this.onTap});

  final String? iconPath;
  final String title;
  final bool isSelected;
  final String? tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Theme.of(context)
            .accentTextTheme!
            .titleLarge!
            .color!,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
          child: Row(
            children: [
              Container(
                child: Image.asset(
                  iconPath ?? '',
                  height: 20.0,
                  width: 20.0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: isSelected
                            ? Palette.blueCraiola
                            : Theme.of(context)
                                .primaryTextTheme!
                                .titleLarge!
                                .color!,
                        fontSize: isSelected ? 16 : 14.0,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (tag != null)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 35.0,
                          height: 18.0,
                          child: Center(
                            child: Text(
                              tag!,
                              style: TextStyle(
                                  fontSize: 7.0,
                                  fontFamily: 'Lato',
                                  color: Theme.of(context)
                                      .textTheme!
                                      .bodyMedium!
                                      .color!),
                            ),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6.0),
                            //border: Border.all(color: ),
                            color: Theme.of(context)
                                .textTheme!
                                .bodyMedium!
                                .decorationColor!,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle,
                    color: Theme.of(context)
                        .accentTextTheme!
                        .bodyLarge!
                        .color!)
            ],
          ),
        ),
      ),
    );
  }
}
