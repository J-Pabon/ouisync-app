import 'dart:io' as io;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart' as oui;

import '../../models/main_state.dart';
import '../../models/repo_state.dart';
import '../../utils/loggers/ouisync_app_logger.dart';
import '../../utils/utils.dart';

part 'repositories_state.dart';

class RepositoriesCubit extends Cubit<RepositoryPickerState> with OuiSyncAppLogger {
  RepositoriesCubit({
    required session,
    required appDir,
    required repositoriesDir
  }) :
    _session = session,
    _appDir = appDir,
    _repositoriesDir = repositoriesDir,
    _mainState = MainState(),
    super(RepositoryPickerInitial());

  final oui.Session _session;
  final String _appDir;
  final String _repositoriesDir;
  final MainState _mainState;

  oui.Session get session => _session;
  String get appDir => _appDir;
  MainState get mainState => _mainState;

  RepoState? current() {
    return _mainState.currentRepo;
  }

  Future<void> openRepository(String name, {String? password, oui.ShareToken? token, bool setCurrent = false }) async {
    emit(RepositoryPickerLoading());

    final repo = await _open(name, password: password, token: token);

    if (repo != null) {
      await _mainState.put(repo, setCurrent: setCurrent);
      emit(RepositoryPickerSelection(repo));
    } else {
      loggy.app('Failed to open repository $name');
      emit(RepositoriesFailure());
    }
  }

  void unlockRepository({required String name, required String password}) async {
    emit(RepositoryPickerLoading());

    final wasCurrent = _mainState.currentRepo?.name == name;

    await _mainState.remove(name);

    final store = _buildStoreString(name);
    final storeExist = await io.File(store).exists();

    if (!storeExist) {
      loggy.app('The repository store doesn\'t exist: $store');
      return;
    }

    try {
      final repository = await _getRepository(
        store: store,
        password: password,
        shareToken: null,
        exist: storeExist
      );

      await RepositoryHelper.setRepoBitTorrentDHTStatus(repository, name);

      await _mainState.put(RepoState(name, repository), setCurrent: wasCurrent);
      emit(RepositoryPickerUnlocked(RepoState(name, repository)));
    } catch (e, st) {
      loggy.app('Unlock repository $name exception', e, st);
      emit(RepositoriesFailure());
    }
  }

  Future<void> setCurrent(String repoName) async {
    final repo = _mainState.get(repoName);
    _mainState.setCurrent(repo);
    emitSelection(repo);
  }

  void emitSelection(RepoState? repo) async {
    if (repo == null) {
      emit(RepositoryPickerInitial());
    } else {
      emit(RepositoryPickerSelection(repo));
    }
  }

  /// Renames a repository
  ///
  /// 1. Remove the repiository from memory.
  /// 2. Reset the default repository setting.
  /// 3. Rename the *.db files in the local storage.
  /// 4. Get the new default repository from the remaining repositories, if any.
  /// 5. Get the default repository object from memory, if any.
  /// 6. Emits the event for selecting a new repository: this updates the
  ///    repository picker, and from there, the state in the main page.
  void renameRepository(String oldName, String newName) async {
    await _mainState.remove(oldName); // 1

    final renamed = await RepositoryHelper.renameRepositoryFiles(_repositoriesDir,
      oldName: oldName,
      newName: newName
    ); // 3
    if (!renamed) {
      loggy.app('The repository $oldName renaming failed');

      loggy.app('Initializing $oldName again...');
      final repo = await _open(oldName);

      loggy.app('Selecting $oldName...');
      emitSelection(repo);

      loggy.app('Repository renaming canceled');
      return;
    }

    await Settings.saveSetting(Constants.currentRepositoryKey, ''); // 2
    await RepositoryHelper.removeBitTorrentDHTStatusForRepo(oldName);

    final repository = await _open(newName);

    emit(RepositoryPickerSelection(repository!)); // 6
  }

  /// Deletes a repository
  ///
  /// 1. Remove the repiository from memory.
  /// 2. Reset the default repository setting.
  /// 3. Deletes the *.db files from the local storage
  /// 4. Get the new default repository from the remaining repositories, if any.
  /// 5. Get the default repository object from memory, if any.
  /// 6. Emits the event for selecting a new repository: this updates the
  ///    repository picker, and from there, the state in the main page.
  void deleteRepository(String repositoryName) async {
    await _mainState.remove(repositoryName); // 1

    final deleted = await RepositoryHelper.deleteRepositoryFiles(
      _repositoriesDir,
      repositoryName: repositoryName
    ); // 3

    if (!deleted) {
      loggy.app('The repository $repositoryName deletion failed');

      loggy.app('Initializing $repositoryName again...');
      final repo = await _open(repositoryName);

      loggy.app('Selecting $repositoryName...');
      emitSelection(repo!);

      loggy.app('Repository deletion canceled');
      return;
    }

    await Settings.saveSetting(Constants.currentRepositoryKey, ''); // 2
    await RepositoryHelper.removeBitTorrentDHTStatusForRepo(repositoryName);

    final latestRepositoryOrDefaultName = await RepositoryHelper
    .latestRepositoryOrDefault(null); // 4

    if (latestRepositoryOrDefaultName.isEmpty) { /// No more repositories available
      emit(RepositoryPickerInitial());
      return;
    }

    RepoState? newDefaultRepository = _mainState.get(latestRepositoryOrDefaultName); // 5

    if (newDefaultRepository == null) { /// The new deafult repository has not been initialized / it's not in memory
      newDefaultRepository = await _open(latestRepositoryOrDefaultName);
    }

    await _mainState.put(newDefaultRepository!);

    emit(RepositoryPickerSelection(newDefaultRepository)); // 6
  }

  _buildStoreString(repositoryName) => '${_repositoriesDir}/$repositoryName.db';

  Future<void> close() async {
    await _mainState.close();
  }

  Future<RepoState?> _open(String name, { String? password, oui.ShareToken? token }) async {
    final store = _buildStoreString(name);
    final storeExist = await io.File(store).exists();

    try {
      final repository = await _getRepository(
        store: store,
        password: password,
        shareToken: token,
        exist: storeExist
      );

      await RepositoryHelper.setRepoBitTorrentDHTStatus(repository, name);
      return RepoState(name, repository);
    } catch (e, st) {
      loggy.app('Init the repository $name exception', e, st);
    }

    return null;
  }

  Future<oui.Repository> _getRepository({required String store, String? password, oui.ShareToken?  shareToken, required bool exist}) =>
    exist 
    ? oui.Repository.open(_session, store: store, password: password)
    : oui.Repository.create(_session, store: store, password: password!, shareToken: shareToken);
}
