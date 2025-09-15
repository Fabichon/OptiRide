import 'package:go_router/go_router.dart';
import 'package:optiride/features/search/presentation/search_page.dart';
import 'package:optiride/features/offers/presentation/offers_page.dart';

final GoRouter appRouter = GoRouter(
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
);
