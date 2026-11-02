// 主界面外壳：内容区（嵌套 Navigator，二级页右侧推入 + 左缘右滑返回）+ 迷你播放条 + 底栏。
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/state.dart';
import '../core/tokens.dart';
import '../pages/daily.dart';
import '../pages/discover.dart';
import '../pages/library.dart';
import '../pages/me.dart';
import '../pages/search.dart';
import '../ui/kit.dart';
import 'mini.dart';
import 'nav.dart';

final contentNav = GlobalKey<NavigatorState>();
final tabScroll = List.generate(5, (_) => ScrollController());

/// 二级页：在内容区内推入（保留迷你播放条与底栏）。
Future<T?> push<T>(BuildContext context, Widget page) {
  final nav = contentNav.currentState;
  if (nav == null) return Future.value();
  return nav.push<T>(CupertinoPageRoute(builder: (_) => page));
}

/// 全屏页：盖住迷你播放条与底栏（扫一扫、识曲、登录流程）。
Future<T?> pushFull<T>(BuildContext context, Widget page) =>
    rootNav.currentState!.push<T>(CupertinoPageRoute(fullscreenDialog: false, builder: (_) => page));

void popToRoot() => contentNav.currentState?.popUntil((r) => r.isFirst);

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  void _onTab(int i) {
    final app = context.appRead;
    final canPop = contentNav.currentState?.canPop() ?? false;
    if (i == app.tab && !canPop) {
      final c = tabScroll[i];
      if (c.positions.length == 1) c.animateTo(0, duration: const Duration(milliseconds: 520), curve: Tk.out);
      app.update(() => app.navMin = false);
      return;
    }
    popToRoot();
    app.update(() {
      app.tab = i;
      app.navMin = false;
      app.searchFocus = false;
    });
  }

  bool _onScroll(ScrollNotification n) {
    final app = context.appRead;
    if (n.metrics.axis != Axis.vertical || n is! ScrollUpdateNotification) return false;
    if (!app.set.navAutoMin || app.tab == 1 || !const ['liquid', 'island', 'classic', 'frosted', 'text'].contains(app.bar)) return false;
    final y = n.metrics.pixels, dy = n.scrollDelta ?? 0;
    final want = y > 140 && dy > 4 ? true : (dy < -6 || y < 60) ? false : app.navMin;
    if (want != app.navMin) app.update(() => app.navMin = want);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final pal = context.pal;
    final hideChrome = app.searchFocus;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = contentNav.currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (app.tab != 0) {
          _onTab(0);
        }
      },
      child: Scaffold(
        backgroundColor: pal.bg,
        resizeToAvoidBottomInset: false,
        body: Stack(children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: HeroControllerScope.none(
                child: Navigator(
                  key: contentNav,
                  onGenerateRoute: (_) => PageRouteBuilder(pageBuilder: (_, __, ___) => const TabsHost(), transitionDuration: Duration.zero),
                ),
              ),
            ),
          ),
          if (app.tab != 1) const MiniPlayer(),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 380),
            curve: Tk.out,
            left: 0,
            right: 0,
            bottom: hideChrome ? -140 : 0,
            height: 220,
            child: AnimatedOpacity(
              duration: Tk.base,
              opacity: hideChrome ? 0 : 1,
              child: BottomNav(tab: app.tab, onTab: _onTab),
            ),
          ),
        ]),
      ),
    );
  }
}

class TabsHost extends StatefulWidget {
  const TabsHost({super.key});
  @override
  State<TabsHost> createState() => _TabsHostState();
}

class _TabsHostState extends State<TabsHost> {
  int last = 0;
  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final dir = (app.tab - last).sign;
    last = app.tab;
    final page = switch (app.tab) {
      1 => const SearchPage(),
      2 => const DailyPage(),
      3 => const LibraryPage(),
      4 => const MePage(),
      _ => const DiscoverPage(),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Tk.out,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (ch, a) {
        final incoming = ch.key == ValueKey(app.tab);
        final off = Tween(begin: Offset(incoming ? .06 * dir : -.04 * dir, 0), end: Offset.zero).animate(a);
        return FadeTransition(opacity: a, child: SlideTransition(position: off, child: ch));
      },
      layoutBuilder: (cur, prev) => Stack(children: [...prev, if (cur != null) cur]),
      child: KeyedSubtree(key: ValueKey(app.tab), child: page),
    );
  }
}
