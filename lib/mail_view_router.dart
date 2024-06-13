import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart'; // Tambahkan ini
import 'package:reply/custom_transition_page.dart';

import 'home.dart';
import 'inbox.dart';
import 'model/email_store.dart';

class MailViewRouterDelegate extends RouterDelegate<void>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  MailViewRouterDelegate({required this.drawerController});

  final AnimationController drawerController;

  @override
  Widget build(BuildContext context) {
    bool handlePopPage(Route<dynamic> route, dynamic result) {
      return false;
    }

    return Selector<EmailStore, String>(
      selector: (context, emailStore) => emailStore.currentlySelectedInbox,
      builder: (context, currentlySelectedInbox, child) {
        return Navigator(
          key: navigatorKey,
          onPopPage: handlePopPage,
          pages: [
            // Menggunakan FadeThroughTransitionPageWrapper untuk halaman dengan transisi Fade Through
            FadeThroughTransitionPageWrapper(
              mailbox: InboxPage(destination: currentlySelectedInbox),
              transitionKey: ValueKey(currentlySelectedInbox),
            ),
          ],
        );
      },
    );
  }

  @override
  GlobalKey<NavigatorState> get navigatorKey => mobileMailNavKey;

  @override
  Future<bool> popRoute() {
    var emailStore =
        Provider.of<EmailStore>(navigatorKey.currentContext!, listen: false);
    bool onCompose = emailStore.onCompose;

    bool onMailView = emailStore.onMailView;

    if (!(onMailView || onCompose)) {
      if (emailStore.bottomDrawerVisible) {
        drawerController.reverse();
        return SynchronousFuture<bool>(true);
      }

      if (emailStore.currentlySelectedInbox != 'Inbox') {
        emailStore.currentlySelectedInbox = 'Inbox';
        return SynchronousFuture<bool>(true);
      }
      return SynchronousFuture<bool>(false);
    }

    if (onCompose) {
      // Menambahkan Container Transform dari FAB ke halaman compose email
      emailStore.onCompose = false;
      return SynchronousFuture<bool>(true);
    }

    if (emailStore.bottomDrawerVisible && onMailView) {
      drawerController.reverse();
      return SynchronousFuture<bool>(true);
    }

    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop();
      Provider.of<EmailStore>(navigatorKey.currentContext!, listen: false)
          .currentlySelectedEmailId = -1;
      return SynchronousFuture<bool>(true);
    }

    return SynchronousFuture<bool>(false);
  }

  @override
  Future<void> setNewRoutePath(void configuration) {
    throw UnimplementedError();
  }
}

class FadeThroughTransitionPageWrapper extends Page {
  const FadeThroughTransitionPageWrapper({
    required this.mailbox,
    required this.transitionKey,
  }) : super(key: transitionKey);

  final Widget mailbox;
  final ValueKey transitionKey;

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return mailbox;
      },
    );
  }
}
