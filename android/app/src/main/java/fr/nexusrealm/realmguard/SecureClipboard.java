package fr.nexusrealm.realmguard;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.os.PersistableBundle;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Native bridge for copying <b>secret</b> values to the system clipboard with
 * two protections the Flutter {@code Clipboard} plugin does not offer:
 *
 * <ul>
 *   <li><b>Sensitive flag</b> — the clip is tagged {@code IS_SENSITIVE}, so
 *       Android 13+ (and 12L OEMs honouring the extra) keep the value out of the
 *       clipboard preview, history and cross-device clipboard.</li>
 *   <li><b>Compare-then-clear</b> — {@code clear} only wipes the clipboard when
 *       it still holds the exact value we put there, so a copy the user made in
 *       the meantime is never clobbered. When the clipboard can't be read (a
 *       backgrounded app lacks access on Android 10+) it wipes anyway, so a
 *       stale secret never lingers.</li>
 * </ul>
 */
final class SecureClipboard implements MethodChannel.MethodCallHandler {

    private static final String CHANNEL =
        "fr.nexusrealm.realmguard/secure_clipboard";
    private static final String LABEL = "Realm Guard";

    // Value of ClipDescription.EXTRA_IS_SENSITIVE (public only at API 33). Using
    // the literal key marks the clip on API 33+ and on 12L OEMs that read it,
    // without referencing an API-33 symbol.
    private static final String EXTRA_IS_SENSITIVE =
        "android.content.extra.IS_SENSITIVE";

    private final Context context;

    private SecureClipboard(@NonNull Context context) {
        this.context = context.getApplicationContext();
    }

    static void register(@NonNull FlutterEngine engine, @NonNull Context context) {
        final MethodChannel channel = new MethodChannel(
            engine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(new SecureClipboard(context));
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        try {
            switch (call.method) {
                case "copy": {
                    final String text = call.argument("text");
                    final Boolean sensitive = call.argument("sensitive");
                    copy(text == null ? "" : text, Boolean.TRUE.equals(sensitive));
                    result.success(null);
                    break;
                }
                case "clear": {
                    clear(call.argument("expected"));
                    result.success(null);
                    break;
                }
                default:
                    result.notImplemented();
            }
        } catch (Exception e) {
            result.error("clipboard_error", e.getClass().getSimpleName(), null);
        }
    }

    private ClipboardManager clipboard() {
        return (ClipboardManager) context.getSystemService(Context.CLIPBOARD_SERVICE);
    }

    private void copy(@NonNull String text, boolean sensitive) {
        final ClipboardManager cm = clipboard();
        if (cm == null) {
            return;
        }
        final ClipData clip = ClipData.newPlainText(LABEL, text);
        if (sensitive) {
            final PersistableBundle extras = new PersistableBundle();
            extras.putBoolean(EXTRA_IS_SENSITIVE, true);
            clip.getDescription().setExtras(extras);
        }
        cm.setPrimaryClip(clip);
    }

    private void clear(String expected) {
        final ClipboardManager cm = clipboard();
        if (cm == null) {
            return;
        }
        // Only wipe if the clipboard still holds the secret we put there. A null
        // read (no focus / background on Android 10+) is treated as "clear
        // anyway" so a stale secret never lingers.
        if (expected != null) {
            final ClipData current = cm.getPrimaryClip();
            if (current != null && current.getItemCount() > 0) {
                final CharSequence text = current.getItemAt(0).getText();
                if (text != null && !expected.contentEquals(text)) {
                    return; // The user copied something else — leave it.
                }
            }
        }
        // clearPrimaryClip() requires API 28; minSdk is 29.
        cm.clearPrimaryClip();
    }
}
