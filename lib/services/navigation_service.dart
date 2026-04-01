import 'package:flutter/material.dart';

enum AppTab { home, discovery, messages, profile }

class NavigationService extends ChangeNotifier {
  AppTab _currentTab = AppTab.home;
  int _discoverySubTabIndex = 0; // 0: My History, 1: Ready to Qabool
  int _readyToQaboolSubTabIndex = 0; // 0: Mutual, 1: Received

  AppTab get currentTab => _currentTab;
  int get discoverySubTabIndex => _discoverySubTabIndex;
  int get readyToQaboolSubTabIndex => _readyToQaboolSubTabIndex;

  void setTab(AppTab tab, {int? discoverySubTab, int? readyToQaboolSubTab}) {
    _currentTab = tab;
    if (discoverySubTab != null) _discoverySubTabIndex = discoverySubTab;
    if (readyToQaboolSubTab != null) _readyToQaboolSubTabIndex = readyToQaboolSubTab;
    notifyListeners();
  }

  void goToDiscovery({int subTab = 0, int readyToQaboolSubTab = 0}) {
    setTab(AppTab.discovery, discoverySubTab: subTab, readyToQaboolSubTab: readyToQaboolSubTab);
  }

  void goToMessages() {
    setTab(AppTab.messages);
  }
  
  void goToHome() {
    setTab(AppTab.home);
  }
}
