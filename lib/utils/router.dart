import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/profile_setup_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/chat/chats_list_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/community/communities_screen.dart';
import '../screens/community/community_detail_screen.dart';
import '../screens/community/channel_screen.dart';
import '../screens/community/create_community_screen.dart';
import '../screens/status/status_screen.dart';
import '../screens/status/create_status_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(BuildContext context) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final status = authProvider.status;
      final location = state.uri.toString();

      if (location == '/splash') return null;

      if (status == AuthStatus.initial) return '/splash';
      if (status == AuthStatus.unauthenticated) {
        if (location.startsWith('/auth')) return null;
        return '/auth/login';
      }
      if (status == AuthStatus.emailUnverified) {
        return '/auth/verify-email';
      }
      if (status == AuthStatus.profileSetup) {
        return '/auth/profile-setup';
      }
      if (status == AuthStatus.authenticated) {
        if (location.startsWith('/auth') || location == '/splash') {
          return '/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/auth/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/chats',
            builder: (context, state) => const ChatsListScreen(),
          ),
          GoRoute(
            path: '/communities',
            builder: (context, state) => const CommunitiesScreen(),
          ),
          GoRoute(
            path: '/status',
            builder: (context, state) => const StatusScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:chatId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            chatId: chatId,
            participantName: extra?['name'] ?? '',
            participantAvatar: extra?['avatar'],
            participantId: extra?['participantId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/community/:communityId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final communityId = state.pathParameters['communityId']!;
          return CommunityDetailScreen(communityId: communityId);
        },
        routes: [
          GoRoute(
            path: 'channel/:channelId',
            builder: (context, state) {
              final channelId = state.pathParameters['channelId']!;
              final communityId = state.pathParameters['communityId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ChannelScreen(
                channelId: channelId,
                communityId: communityId,
                channelName: extra?['name'] ?? 'general',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/create-community',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateCommunityScreen(),
      ),
      GoRoute(
        path: '/create-status',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateStatusScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}
