import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for current page index using NotifierProvider
class CurrentPageNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setPage(int page){
    state = page;
  }
}

//Makes CurrentPageNotifier available throughout the app.
//Widgets can watch or read it to get or change the current page.

final currentPageProvider = NotifierProvider<CurrentPageNotifier, int>(
      () => CurrentPageNotifier(),
);