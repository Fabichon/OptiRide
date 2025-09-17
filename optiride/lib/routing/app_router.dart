import 'package:go_router/go_router.dart';
import 'package:optiride/features/search/presentation/search_page.dart';
import 'package:optiride/features/offers/presentation/offers_page.dart';
import 'package:optiride/layout/main_layout.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(
          currentRoute: state.uri.toString(),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SearchView(),
        ),
        GoRoute(
          path: '/offers',
          builder: (context, state) => const ResultsView(),
        ),
      ],
    ),
  ],
);
