import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/age.dart';

/// First launch starts with 7 sample entries (made-up names) so the list, search and filters are not empty.
/// Set to false to ship with an empty history.
const bool kSeedDemoHistory = true;

const List<String> kCategories = ['Family', 'Friends', 'Work', 'Personal'];

class HistoryEntry {
  const HistoryEntry({required this.id, required this.name, required this.category, required this.birth, required this.savedAt, this.demo = false});
  final String id, name, category;
  final YMD birth;
  final int savedAt;
  final bool demo;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'category': category, 'birth': birth.toJson(), 'savedAt': savedAt, 'demo': demo};
  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'] as String, name: j['name'] as String, category: _migrateCategory(j['category'] as String),
        birth: YMD.fromJson(Map<String, dynamic>.from(j['birth'] as Map)), savedAt: (j['savedAt'] ?? 0) as int, demo: (j['demo'] ?? false) as bool,
      );
}

/// Entries saved before the English release stored Indonesian category names; map them so old data keeps working.
String _migrateCategory(String c) => switch (c) { 'Keluarga' => 'Family', 'Teman' => 'Friends', 'Kerja' => 'Work', 'Pribadi' => 'Personal', _ => c };

List<HistoryEntry> demoHistory() => [
      for (final (i, e) in const [
        ('Anita', 'Friends', YMD(1998, 8, 14)), ('Mom', 'Family', YMD(1970, 3, 3)), ('Dimas', 'Friends', YMD(2001, 1, 26)), ('Nara', 'Family', YMD(2019, 5, 11)),
        ('Dad', 'Family', YMD(1967, 12, 22)), ('Sinta', 'Work', YMD(1996, 9, 9)), ('Beny', 'Work', YMD(2004, 4, 30)),
      ].indexed)
        HistoryEntry(id: 'demo-$i', name: e.$1, category: e.$2, birth: e.$3, savedAt: 0, demo: true),
    ];

/// Theme, reminders, onboarding flag and history — everything persisted on the device.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _themeMode = switch (_prefs.getString(_kTheme)) { 'light' => ThemeMode.light, 'dark' => ThemeMode.dark, _ => ThemeMode.system };
    _reminders = _prefs.getBool(_kReminders) ?? true;
    _onboarded = _prefs.getBool(_kOnboarded) ?? false;
    final raw = _prefs.getString(_kHistory);
    if (raw == null) {
      _history = kSeedDemoHistory ? demoHistory() : [];
      _save();
    } else {
      try {
        _history = [for (final e in jsonDecode(raw) as List) HistoryEntry.fromJson(Map<String, dynamic>.from(e as Map))];
      } catch (_) {
        _history = [];
      }
    }
  }

  static const _kTheme = 'ac.theme', _kReminders = 'ac.reminders', _kOnboarded = 'ac.onboarded', _kHistory = 'ac.history.v1';
  final SharedPreferences _prefs;
  late ThemeMode _themeMode;
  late bool _reminders, _onboarded;
  late List<HistoryEntry> _history;
  int _idSeq = 0; // two saves in the same microsecond must still get different ids

  ThemeMode get themeMode => _themeMode;
  bool get reminders => _reminders;
  bool get onboarded => _onboarded;
  List<HistoryEntry> get history => List.unmodifiable(_history);

  void setThemeMode(ThemeMode m) {
    _themeMode = m;
    _prefs.setString(_kTheme, switch (m) { ThemeMode.light => 'light', ThemeMode.dark => 'dark', ThemeMode.system => 'system' });
    notifyListeners();
  }

  void setReminders(bool v) {
    _reminders = v;
    _prefs.setBool(_kReminders, v);
    notifyListeners();
  }

  void completeOnboarding() {
    _onboarded = true;
    _prefs.setBool(_kOnboarded, true);
    notifyListeners();
  }

  void _save() => _prefs.setString(_kHistory, jsonEncode([for (final e in _history) e.toJson()]));

  HistoryEntry add({required String name, required String category, required YMD birth}) {
    final e = HistoryEntry(id: 'h-${DateTime.now().microsecondsSinceEpoch}-${_idSeq++}', name: name, category: category, birth: birth, savedAt: DateTime.now().millisecondsSinceEpoch);
    _history = [e, ..._history];
    _save();
    notifyListeners();
    return e;
  }

  /// Returns the removed entry and its position so the caller can offer "Undo".
  (HistoryEntry, int)? remove(String id) {
    final i = _history.indexWhere((e) => e.id == id);
    if (i < 0) return null;
    final e = _history[i];
    _history = [..._history]..removeAt(i);
    _save();
    notifyListeners();
    return (e, i);
  }

  void insertAt(HistoryEntry e, int index) {
    _history = [..._history]..insert(index.clamp(0, _history.length).toInt(), e);
    _save();
    notifyListeners();
  }

  void clearHistory() {
    _history = [];
    _save();
    notifyListeners();
  }

  void restoreDemo() {
    _history = demoHistory();
    _save();
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------------------------------------------- calculator

class CalcError {
  const CalcError(this.message, this.field, this.nonce);
  final String message;
  final AgeErrorField field;
  final int nonce;
}

enum CalcStatus { idle, loading }

/// The "Calculate" form. Dates come from the wheel sheet so they are always real calendar dates;
/// the only way to fail is a birth date after the reference date.
class CalcState extends ChangeNotifier {
  YMD _birth = const YMD(1998, 8, 14);
  YMD _ref = YMD.today();
  bool _useToday = true;
  CalcStatus _status = CalcStatus.idle;
  CalcError? _error;
  bool _busy = false;

  YMD get birth => _birth;
  YMD get ref => _useToday ? YMD.today() : _ref;
  bool get useToday => _useToday;
  CalcStatus get status => _status;
  bool get loading => _status == CalcStatus.loading;
  CalcError? get error => _error;

  void setBirth(YMD d) {
    _birth = d;
    _error = null;
    notifyListeners();
  }

  void setRef(YMD d) {
    _ref = d;
    _error = null;
    notifyListeners();
  }

  void setUseToday(bool v) {
    _useToday = v;
    if (v) _ref = YMD.today();
    _error = null;
    notifyListeners();
  }

  void reset() {
    _birth = const YMD(1998, 8, 14);
    _useToday = true;
    _ref = YMD.today();
    _error = null;
    notifyListeners();
  }

  /// Validates, shows the loading state for a deliberate 620 ms, then returns the result (null on error).
  Future<AgeResult?> calculate() async {
    if (_busy) return null;
    final AgeResult next;
    try {
      next = computeAge(_birth, ref);
    } on AgeError catch (e) {
      _error = CalcError(e.message, e.field, DateTime.now().microsecondsSinceEpoch);
      notifyListeners();
      return null;
    }
    _error = null;
    _busy = true;
    _status = CalcStatus.loading;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 620)); // a calculation that lands instantly reads as unreliable
    _status = CalcStatus.idle;
    _busy = false;
    notifyListeners();
    return next;
  }
}

// ---------------------------------------------------------------------------------------------------------------- toasts

enum ToastKind { ok, err }

class ToastItem {
  ToastItem({required this.id, required this.title, this.description, this.kind = ToastKind.ok, this.actionLabel, this.onAction, this.ms = 2400});
  final int id;
  final String title;
  final String? description, actionLabel;
  final ToastKind kind;
  final VoidCallback? onAction;
  final int ms;
  bool open = false;
}

class ToastController extends ChangeNotifier {
  final List<ToastItem> _items = [];
  final Map<int, Timer> _timers = {};
  int _seq = 0;
  List<ToastItem> get items => List.unmodifiable(_items);

  int show(String title, {String? description, ToastKind kind = ToastKind.ok, String? actionLabel, VoidCallback? onAction, int? ms}) {
    final item = ToastItem(
      id: ++_seq, title: title, description: description, kind: kind, actionLabel: actionLabel, onAction: onAction,
      ms: ms ?? (actionLabel != null ? 4000 : 2400),
    );
    _items.add(item);
    if (_items.length > 3) _dismiss(_items.first.id, immediately: true);
    notifyListeners();
    // next frame: flip to "open" so the entrance animates
    Future<void>.delayed(const Duration(milliseconds: 16), () {
      if (_disposed) return;
      item.open = true;
      notifyListeners();
    });
    _timers[item.id] = Timer(Duration(milliseconds: item.ms), () => _dismiss(item.id));
    return item.id;
  }

  void dismiss(int id) => _dismiss(id);

  void _dismiss(int id, {bool immediately = false}) {
    _timers.remove(id)?.cancel();
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    if (immediately) {
      _items.removeAt(i);
      notifyListeners();
      return;
    }
    _items[i].open = false;
    notifyListeners();
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (_disposed) return;
      _items.removeWhere((e) => e.id == id);
      notifyListeners();
    });
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }
}

// ---------------------------------------------------------------------------------------------------------------- navigation / boot

/// Which tab is showing; lets any screen jump to another tab ("See all", "Calculate your first age").
class TabNav extends ChangeNotifier {
  int _index = 0;
  int get index => _index;
  void go(int i) {
    if (i == _index) return;
    _index = i;
    notifyListeners();
  }
}

/// True for ~0.7 s after the splash while the first screen shows page-shaped placeholders.
class BootState extends ChangeNotifier {
  bool _skeleton = false;
  bool _disposed = false;
  bool get skeleton => _skeleton;
  void set(bool v) {
    if (_disposed || v == _skeleton) return;
    _skeleton = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
