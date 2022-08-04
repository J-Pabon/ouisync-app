import 'dart:io' as io;

import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart' as oui;
import 'dart:async';

import '../../utils/loggers/ouisync_app_logger.dart';
import '../../utils/utils.dart';
import '../cubits.dart';

import '../../models/folder_state.dart';

part 'state.dart';

class ReposCubit extends WatchSelf<ReposCubit> with OuiSyncAppLogger {
  final Map<String, RepoCubit> _repos = Map();

  bool isLoading = false;

  String? _currentRepoName;

  final _currentRepoChange = Value<RepoCubit?>(null);

  ReposCubit({
    required session,
    required appDir,
    required repositoriesDir
  }) :
    _session = session,
    _appDir = appDir,
    _repositoriesDir = repositoriesDir
  {}

  final oui.Session _session;
  final String _appDir;
  final String _repositoriesDir;

  oui.Session get session => _session;
  String get appDir => _appDir;

  Value<RepoCubit?> get currentRepoChange => _currentRepoChange;

  String? get currentRepoName => _currentRepoName;

  Iterable<String> repositoryNames() => _repos.keys;

  RepoCubit? get currentRepo {
    if (_currentRepoName == null) {
      return null;
    } else {
      return _repos[_currentRepoName!];
    }
  }

  FolderState? get currentFolder {
    return currentRepo?.state.currentFolder;
  }

  Iterable<RepoCubit> get repos => _repos.entries.map((entry) => entry.value);

  Future<void> setCurrent(RepoCubit? repo) async {
    if (repo == null) {
      _updateCurrentRepository(null);
    } else {
      await put(repo, setCurrent: true);
    }
  }

  Future<void> setCurrentByName(String? repoName) async {
    if (repoName == currentRepoName) {
      return;
    }

    RepoCubit? repo;

    if (repoName != null) {
      repo = this.get(repoName);
    }

    setCurrent(repo);
    await Settings.setDefaultRepo(repo?.name);

    changed();
  }

  void _updateCurrentRepository(RepoCubit? repo) {
    oui.NativeChannels.setRepository(repo?.state.handle);

    if (repo == null) {
      loggy.app("Can't set current repository to null");
      _currentRepoName = null;
      _currentRepoChange.emit(null);
      return;
    }

    if (_subscriptionCallback == null) {
      throw Exception('There is not callback for synchronization');
    }

    _subscription?.cancel();
    _subscription = null;

    _currentRepoName = repo.state.name;
    _currentRepoChange.emit(repo);

    _subscription = repo.state.handle.subscribe(() => _subscriptionCallback!.call(repo.state));

    loggy.app('Subscribed to notifications: ${repo.state.name} (${repo.state.accessMode.name})');
  }

  RepoCubit? get(String name) {
    return _repos[name];
  }

  Future<void> put(RepoCubit newRepo, { bool setCurrent = false }) async {
    RepoCubit? oldRepo = _repos.remove(newRepo.state.name);

    if (oldRepo != null && oldRepo != newRepo) {
      await oldRepo.state.close();
    }

    _repos[newRepo.state.name] = newRepo;

    if (setCurrent && newRepo.state.name != _currentRepoName) {
      _updateCurrentRepository(newRepo);
    }
  }

  Future<void> remove(String name) async {
    if (_currentRepoName == name) {
      loggy.app('Canceling subscription to $name');
      _subscription?.cancel();
      _subscription = null;

      loggy.app('Cleaning current selection for repository $name');
      _currentRepoName = null;
    }

    final repo = _repos[name];

    if (repo != null) {
      loggy.app('Closing repository $name');
      Settings.setDhtEnableStatus(repo.id, null);
      await repo.state.close();
      _repos.remove(name);
    }
  }

  Future<void> close() async {
    // Make sure this function is idempotent, i.e. that calling it more than once
    // one after another won't change it's meaning nor it will crash.
    _currentRepoName = null;
    _currentRepoChange.emit(null);

    _subscription?.cancel();
    _subscription = null;

    for (var repo in _repos.values) {
      await repo.state.close();
    }

    _repos.clear();
  }

  oui.Subscription? _subscription;
  oui.Subscription? get subscription => _subscription;

  void Function(RepoState)? _subscriptionCallback;

  setSubscriptionCallback(void Function(RepoState) callback) => {
    _subscriptionCallback = callback
  };

  Future<void> openRepository(String name, {String? password, oui.ShareToken? token, bool setCurrent = false }) async {
    print("ReposCubit openRepository start $name");
    _update(() { isLoading = true; });

    final repo = await _open(name, password: password, token: token);

    if (repo != null) {
      await this.put(repo, setCurrent: setCurrent);
    } else {
      loggy.app('Failed to open repository $name');
    }

    print("ReposCubit openRepository end $name");
    _update(() { isLoading = false; });
  }

  void unlockRepository({required String name, required String password}) async {
    _update(() { isLoading = true; });

    final wasCurrent = _currentRepoName == name;

    await remove(name);

    final store = _buildStoreString(name);
    final storeExist = await io.File(store).exists();

    if (!storeExist) {
      loggy.app('The repository store doesn\'t exist: $store');
      _update(() { isLoading = false; });
      return;
    }

    try {
      final repo = await _getRepository(
        store: store,
        password: password,
        shareToken: null,
        exist: storeExist
      );

      await this.put(RepoCubit(RepoState(name, repo)), setCurrent: wasCurrent);
    } catch (e, st) {
      loggy.app('Unlocking of the repository $name failed', e, st);
    }

    _update(() { isLoading = false; });
  }

  void renameRepository(String oldName, String newName) async {
    final wasCurrent = _currentRepoName == oldName;

    await remove(oldName);

    final renamed = await RepositoryHelper.renameRepositoryFiles(_repositoriesDir,
      oldName: oldName,
      newName: newName
    );

    if (!renamed) {
      loggy.app('The repository $oldName renaming failed');

      loggy.app('Initializing $oldName again...');
      final repo = await _open(oldName);

      if (repo == null) {
        await setCurrent(null);
      } else {
        await this.put(repo, setCurrent: wasCurrent);
      }

      changed();

      return;
    }

    await Settings.setDefaultRepo(null);

    final repo = await _open(newName);

    if (repo == null) {
      await setCurrent(null);
    } else {
      await this.put(repo, setCurrent: wasCurrent);
    }

    changed();
  }

  void deleteRepository(String repositoryName) async {
    final wasCurrent = _currentRepoName == repositoryName;

    await remove(repositoryName);

    final deleted = await RepositoryHelper.deleteRepositoryFiles(
      _repositoriesDir,
      repositoryName: repositoryName
    );

    if (!deleted) {
      loggy.app('The repository $repositoryName deletion failed');

      loggy.app('Initializing $repositoryName again...');
      final repo = await _open(repositoryName);

      if (repo == null) {
        await setCurrent(null);
      } else {
        await put(repo, setCurrent: wasCurrent);
      }

      changed();

      return;
    }

    await Settings.setDefaultRepo(null);

    final nextRepo = _repos.isNotEmpty ? _repos.values.first : null;

    setCurrent(nextRepo);
    await Settings.setDefaultRepo(nextRepo?.name);

    changed();
  }

  _buildStoreString(repositoryName) => '${_repositoriesDir}/$repositoryName.db';

  Future<RepoCubit?> _open(String name, { String? password, oui.ShareToken? token }) async {
    final store = _buildStoreString(name);
    final storeExist = await io.File(store).exists();

    try {
      final repo = await _getRepository(
        store: store,
        password: password,
        shareToken: token,
        exist: storeExist
      );

      return RepoCubit(RepoState(name, repo));
    } catch (e, st) {
      loggy.app('Initialization of the repository $name failed', e, st);
    }

    return null;
  }

  Future<oui.Repository> _getRepository({required String store, String? password, oui.ShareToken?  shareToken, required bool exist}) async {
    final repo;
   
    if (exist) {
      repo = await oui.Repository.open(_session, store: store, password: password);
    } else {
      repo = await oui.Repository.create(_session, store: store, password: password!, shareToken: shareToken);
    }

    if (await Settings.getDhtEnableStatus(repo.lowHexId(), defaultValue: true)) {
      repo.enableDht();
    } else {
      repo.disableDht();
    }

    return repo;
  }

  void _update(void Function() changeState) {
    changeState();
    changed();
  }
}
