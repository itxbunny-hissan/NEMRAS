import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

import 'content/portfolio_copy.dart';
import 'portfolio_sections.dart';
import 'widgets/portfolio_widgets.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final Map<PortfolioSection, GlobalKey> _sectionKeys = <PortfolioSection, GlobalKey>{
    for (final section in PortfolioSection.values) section: GlobalKey(),
  };

  void _go(PortfolioSection section) {
    final target = _sectionKeys[section]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openMenu() async {
    final selected = await showModalBottomSheet<PortfolioSection>(
      context: context,
      backgroundColor: NemrasColors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              for (final section in PortfolioSection.values)
                TextButton(
                  style: portfolioButtonStyle(
                    padding: const EdgeInsets.symmetric(
                      horizontal: NemrasSpacing.section,
                    ),
                  ).copyWith(
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () => Navigator.pop(sheetContext, section),
                  child: Text('${section.number}  ${section.navLabel}'),
                ),
            ],
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    _go(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NemrasColors.paper,
      body: Column(
        children: <Widget>[
          _SectionIndex(
            onSelect: _go,
            onOpenMenu: _openMenu,
          ),
          Expanded(
            child: SelectionArea(
              child: SingleChildScrollView(
                child: _PageWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      HeroSection(
                        key: _sectionKeys[PortfolioSection.hero],
                        onExplore: () => _go(PortfolioSection.surfaces),
                        onArchitecture: () => _go(PortfolioSection.architecture),
                        onCaseStudy: () => _go(PortfolioSection.status),
                      ),
                      const _Gap(),
                      ProblemSection(key: _sectionKeys[PortfolioSection.problem]),
                      const _Gap(),
                      ArchitectureSection(
                        key: _sectionKeys[PortfolioSection.architecture],
                        onHome: () => _go(PortfolioSection.hero),
                        onStatus: () => _go(PortfolioSection.status),
                      ),
                      const _Gap(),
                      SurfacesSection(
                        key: _sectionKeys[PortfolioSection.surfaces],
                      ),
                      const _Gap(),
                      IntelligenceSection(
                        key: _sectionKeys[PortfolioSection.intelligence],
                      ),
                      const _Gap(),
                      SecuritySection(key: _sectionKeys[PortfolioSection.security]),
                      const _Gap(),
                      DataSection(key: _sectionKeys[PortfolioSection.data]),
                      const _Gap(),
                      TechnologySection(
                        key: _sectionKeys[PortfolioSection.technology],
                      ),
                      const _Gap(),
                      ShowcaseSection(
                        key: _sectionKeys[PortfolioSection.showcase],
                      ),
                      const _Gap(),
                      StatusSection(
                        key: _sectionKeys[PortfolioSection.status],
                        onShowcase: () => _go(PortfolioSection.showcase),
                      ),
                      const _Gap(),
                      TeamSection(key: _sectionKeys[PortfolioSection.team]),
                      const _Gap(),
                      const PortfolioFooter(),
                      const SizedBox(height: NemrasSpacing.section),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: NemrasSpacing.section * 3);
  }
}

class _PageWidth extends StatelessWidget {
  const _PageWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            NemrasBreakpoints.fromWidth(constraints.maxWidth) ==
                NemrasWindowSize.compact;
        final pad = compact ? NemrasSpacing.xxl : NemrasSpacing.section;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: portfolioContentWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                pad,
                NemrasSpacing.section * 2,
                pad,
                NemrasSpacing.section,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _SectionIndex extends StatelessWidget {
  const _SectionIndex({
    required this.onSelect,
    required this.onOpenMenu,
  });

  final ValueChanged<PortfolioSection> onSelect;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NemrasColors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: NemrasColors.line2)),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final window = NemrasBreakpoints.fromWidth(constraints.maxWidth);
              final useMenu = window != NemrasWindowSize.expanded;
              final pad = useMenu ? NemrasSpacing.s : NemrasSpacing.section;
              final links = <Widget>[
                for (final section in PortfolioSection.values)
                  TextButton(
                    style: portfolioButtonStyle(
                      padding: const EdgeInsets.symmetric(
                        horizontal: NemrasSpacing.m,
                      ),
                    ),
                    onPressed: () => onSelect(section),
                    child: Text(section.navLabel),
                  ),
              ];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: portfolioContentWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: Row(
                      children: <Widget>[
                        TextButton(
                          style: portfolioButtonStyle(
                            foreground: NemrasColors.tealDeep,
                            textStyle: NemrasTextStyles.screenTitle,
                          ),
                          onPressed: () => onSelect(PortfolioSection.hero),
                          child: const Text(PortfolioCopy.productName),
                        ),
                        const Spacer(),
                        if (useMenu)
                          IconButton(
                            tooltip: 'Open section index',
                            onPressed: onOpenMenu,
                            icon: const Icon(Icons.menu),
                            style: portfolioIconButtonStyle(),
                          )
                        else
                          Flexible(
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              children: links,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
