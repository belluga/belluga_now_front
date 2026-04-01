class TenantAdminLoadedAccountDisposeAction {
  const TenantAdminLoadedAccountDisposeAction(this._callback);

  final void Function() _callback;

  void call() => _callback();
}
