import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/main_shell.dart';
import '../features/audit/presentation/audit_logs_screen.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/organization/presentation/members_screen.dart';
import '../features/organization/presentation/org_settings_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/tasks',
    redirect: (context, state) {
      final isLoading = authStateAsync.isLoading;
      final hasUser = authStateAsync.value != null;
      final isAuthRoute = state.uri.toString() == '/login' || state.uri.toString() == '/register';

      if (isLoading) return null;

      if (!hasUser && !isAuthRoute) {
        return '/login';
      }

      if (hasUser && isAuthRoute) {
        return '/tasks';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/team',
            builder: (context, state) => const MembersScreen(),
          ),
          GoRoute(
            path: '/audit',
            builder: (context, state) => const AuditLogsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const OrgSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
