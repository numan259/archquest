import 'package:flutter/foundation.dart';

import '../models/subject.dart';
import '../models/unit_content.dart';
import '../services/content_loader.dart';

enum LoadStatus { loading, ready, error }

/// Owns the loaded [AppContent] and exposes loading state to the UI.
class AppStateProvider extends ChangeNotifier {
  AppStateProvider(this._loader) {
    load();
  }

  final ContentLoader _loader;

  LoadStatus _status = LoadStatus.loading;
  AppContent? _content;
  Object? _error;

  LoadStatus get status => _status;
  Object? get error => _error;

  List<Subject> get subjects => _content?.subjects ?? const [];

  List<UnitContent> unitsFor(String subjectId) =>
      _content?.unitsFor(subjectId) ?? const [];

  Subject? subjectById(String id) => _content?.subjectById(id);

  UnitContent? unit(String subjectId, int unitNumber) =>
      _content?.unit(subjectId, unitNumber);

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _content = await _loader.load();
      _status = LoadStatus.ready;
    } catch (e) {
      _error = e;
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
