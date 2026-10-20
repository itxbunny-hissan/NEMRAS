import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

/// `.hd-top` - the 54dp desktop top bar.
///
/// Structural slots only. Search and notifications are affordances with no
/// behaviour attached; wiring them is a later phase.
class NemrasDesktopTopBar extends StatelessWidget {
  const NemrasDesktopTopBar({
    super.key,
    required this.title,
    this.breadcrumb,
    this.searchHint = 'Search',
    this.showSearch = true,
    this.showNotifications = true,
    this.hasUnreadNotifications = false,
    this.onSearchTap,
    this.onNotificationsTap,
    this.avatar,
  });

  final String title;

  /// `.crumb` - the monospace context line under the title.
  final String? breadcrumb;

  final String searchHint;
  final bool showSearch;
  final bool showNotifications;

  /// Draws the red indicator dot. A real unread count is not modelled yet.
  final bool hasUnreadNotifications;

  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationsTap;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return Container(
      height: NemrasTouchTargets.barHeight,
      padding: const EdgeInsets.symmetric(horizontal: NemrasSpacing.barPadding),
      decoration: BoxDecoration(
        color: semantics.barBackground,
        border: Border(bottom: BorderSide(color: semantics.barBorder)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: NemrasTextStyles.screenTitle.copyWith(
                    color: semantics.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (breadcrumb != null)
                  Text(
                    breadcrumb!,
                    style: NemrasTextStyles.screenSubtitle.copyWith(
                      color: semantics.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (showSearch) ...<Widget>[
            const SizedBox(width: NemrasSpacing.l),
            _SearchAffordance(hint: searchHint, onTap: onSearchTap),
          ],
          if (showNotifications) ...<Widget>[
            const SizedBox(width: NemrasSpacing.l),
            _NotificationButton(
              hasUnread: hasUnreadNotifications,
              onTap: onNotificationsTap,
            ),
          ],
          if (avatar != null) ...<Widget>[
            const SizedBox(width: NemrasSpacing.l),
            SizedBox(
              width: NemrasTouchTargets.iconButtonVisual,
              height: NemrasTouchTargets.iconButtonVisual,
              child: ClipRRect(
                borderRadius: NemrasRadii.smallBorder,
                child: avatar,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.hd-search` - a 240dp affordance, not a live search field.
class _SearchAffordance extends StatelessWidget {
  const _SearchAffordance({required this.hint, this.onTap});

  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return SizedBox(
      width: 240,
      child: Semantics(
        button: true,
        label: hint,
        child: InkWell(
          onTap: onTap,
          borderRadius: NemrasRadii.smallBorder,
          child: Container(
            // [REC] Raised from the reference's 34dp to the accessible
            // baseline.
            height: NemrasTouchTargets.minimum,
            padding: const EdgeInsets.symmetric(horizontal: NemrasSpacing.m),
            decoration: BoxDecoration(
              color: semantics.controlBackground,
              borderRadius: NemrasRadii.smallBorder,
              border: Border.all(color: semantics.cardBorder),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.search, size: 16, color: semantics.textSecondary),
                const SizedBox(width: NemrasSpacing.s),
                Expanded(
                  child: Text(
                    hint,
                    style: NemrasTextStyles.bodySmall.copyWith(
                      color: semantics.textPlaceholder,
                    ),
                    overflow: TextOverflow.ellipsis,
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

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.hasUnread, this.onTap});

  final bool hasUnread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return Semantics(
      button: true,
      label: hasUnread ? 'Notifications, unread' : 'Notifications',
      child: InkWell(
        onTap: onTap,
        borderRadius: NemrasRadii.smallBorder,
        child: SizedBox(
          width: NemrasTouchTargets.minimum,
          height: NemrasTouchTargets.minimum,
          child: Center(
            child: SizedBox(
              width: NemrasTouchTargets.iconButtonVisual,
              height: NemrasTouchTargets.iconButtonVisual,
              child: Container(
                decoration: BoxDecoration(
                  color: semantics.controlBackground,
                  borderRadius: NemrasRadii.smallBorder,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.notifications_none,
                      size: 18,
                      color: semantics.textPrimary,
                    ),
                    if (hasUnread)
                      Positioned(
                        top: 8,
                        right: 9,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: NemrasColors.red,
                            shape: BoxShape.circle,
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
    );
  }
}
