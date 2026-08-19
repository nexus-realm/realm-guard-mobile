import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Clipboard writes for **secret** values (passwords, TOTP codes, secret custom
/// fields), hardened two ways the default [Clipboard] cannot be:
///
/// 1. **Marked sensitive** — on Android the copy goes through a native channel
///    that tags the clip with `IS_SENSITIVE`, so Android 13+ keeps the value out
///    of the clipboard preview, history and cross-device clipboard.
/// 2. **Auto-cleared** — the value is wiped from the clipboard after
///    [clearDelay]. The native side only wipes if the clipboard *still holds the
///    value we put there*, so a copy made in the meantime is never clobbered.
///
/// Non-secret copies (username, URL…) keep using [Clipboard] directly: they are
/// meant to persist and aren't worth hiding.
///
/// Thin platform wrapper (same shape as `KeystoreKeyGuard`): instantiate inline.
/// The pending-clear timer is class-level state on purpose — there is a single
/// system clipboard, hence a single pending wipe. On non-Android / tests (no
/// channel) it degrades gracefully to a plain [Clipboard] copy with no flag and
/// no auto-clear.
class SecureClipboard {
  const SecureClipboard();

  static const MethodChannel _channel = MethodChannel(
    'fr.nexusrealm.realmguard/secure_clipboard',
  );

  /// Delay before a copied secret is wiped from the clipboard.
  static const Duration clearDelay = Duration(seconds: 30);

  static Timer? _pendingClear;

  /// Copies [value], marks it sensitive, and schedules an auto-clear after
  /// [clearDelay]. A new sensitive copy resets the window.
  Future<void> copySensitive(String value) async {
    _pendingClear?.cancel();
    await _setClipboard(value, sensitive: true);
    _pendingClear = Timer(clearDelay, () {
      unawaited(_clear(value));
    });
  }

  Future<void> _setClipboard(String value, {required bool sensitive}) async {
    try {
      await _channel.invokeMethod<void>('copy', <String, Object?>{
        'text': value,
        'sensitive': sensitive,
      });
    } on MissingPluginException {
      // Non-Android / tests: no native sensitive flag, fall back to a plain copy.
      await Clipboard.setData(ClipboardData(text: value));
    } on PlatformException {
      await Clipboard.setData(ClipboardData(text: value));
    }
  }

  /// Wipes the clipboard iff it still holds [expected] (best-effort). Driven by
  /// the auto-clear timer; safe to fail — a backgrounded app may lack clipboard
  /// access on Android 10+.
  Future<void> _clear(String expected) async {
    try {
      await _channel.invokeMethod<void>('clear', <String, Object?>{
        'expected': expected,
      });
    } on MissingPluginException {
      await Clipboard.setData(const ClipboardData(text: ''));
    } on PlatformException {
      // Best-effort — nothing more to do.
    }
  }

  /// Cancels any pending auto-clear. For tests and teardown only.
  @visibleForTesting
  static void debugReset() {
    _pendingClear?.cancel();
    _pendingClear = null;
  }
}
