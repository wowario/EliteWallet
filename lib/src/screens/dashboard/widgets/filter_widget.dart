import 'package:elite_wallet/src/screens/dashboard/widgets/filter_tile.dart';
import 'package:elite_wallet/src/widgets/section_divider.dart';
import 'package:elite_wallet/src/widgets/standard_checkbox.dart';
import 'package:elite_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:elite_wallet/src/widgets/picker_wrapper_widget.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
//import 'package:date_range_picker/date_range_picker.dart' as date_rage_picker;

class FilterWidget extends StatelessWidget {
  FilterWidget({required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    const sectionDivider = const SectionDivider();
    return PickerWrapperWidget(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            child: Container(
              color: Theme.of(context).textTheme!.bodyLarge!.decorationColor!,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        S.of(context).filter_by,
                        style: TextStyle(
                          color: Theme.of(context)
                              .primaryTextTheme!
                              .labelSmall!
                              .color!,
                          fontSize: 16,
                          fontFamily: 'Lato',
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    sectionDivider,
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dashboardViewModel.filterItems.length,
                      separatorBuilder: (context, _) => sectionDivider,
                      itemBuilder: (_, index1) {
                        final title = dashboardViewModel.filterItems.keys
                            .elementAt(index1);
                        final section = dashboardViewModel.filterItems.values
                            .elementAt(index1);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding:
                                  EdgeInsets.only(top: 20, left: 24, right: 24),
                              child: Text(
                                title,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .primaryTextTheme!
                                        .titleLarge!
                                        .color!,
                                    fontSize: 16,
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none),
                              ),
                            ),
                            ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: section.length,
                              itemBuilder: (_, index2) {
                                final item = section[index2];
                                final content = Observer(
                                    builder: (_) => StandardCheckbox(
                                          value: item.value(),
                                          caption: item.caption,
                                          gradientBackground: true,
                                          borderColor:
                                              Theme.of(context).dividerColor,
                                          iconColor: Colors.white,
                                          onChanged: (value) =>
                                              item.onChanged(),
                                        ));
                                return FilterTile(child: content);
                              },
                            )
                          ],
                        );
                      },
                    ),
                  ]),
            ),
          ),
        )
      ],
    );
  }
}
