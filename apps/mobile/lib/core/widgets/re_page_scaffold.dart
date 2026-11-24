import 'package:material_ui/material_ui.dart';

import '../theme/re_tokens.dart';

/// Canonical Neo-Brutalist page scaffold (`COMPONENT_SPEC.md` §1).
///
/// Provides warm paper background (`ReTokens.paper`), `SafeArea`, consistent
/// horizontal gutters, constrained content width (`ReTokens.contentWidth`),
/// optional `appBar`, `bottomBar` (sticky footer), `bottomNavigationBar`, and
/// scrollable or fixed body behavior.
class RePageScaffold extends StatelessWidget {
  const RePageScaffold({
    super.key,
    this.children,
    this.body,
    this.appBar,
    this.bottomBar,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.all(ReTokens.spaceLg),
    this.scrollable = true,
    this.maxWidth = ReTokens.contentWidth,
    this.backgroundColor = ReTokens.paper,
  }) : assert(
         (children != null) ^ (body != null),
         'Provide either children or body, not both.',
       );

  final List<Widget>? children;
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomBar;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry padding;
  final bool scrollable;
  final double maxWidth;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (children != null) {
      content = scrollable
          ? ListView(
              scrollCacheExtent: const ScrollCacheExtent.pixels(0),
              padding: padding,
              children: children!,
            )
          : Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children!,
              ),
            );
    } else {
      content = scrollable
          ? SingleChildScrollView(padding: padding, child: body!)
          : Padding(padding: padding, child: body!);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: content,
                ),
              ),
            ),
            if (bottomBar != null)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: ReTokens.paper,
                  border: Border(top: ReTokens.standardBorderSide),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ReTokens.spaceLg,
                        vertical: ReTokens.spaceCompact,
                      ),
                      child: bottomBar!,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
