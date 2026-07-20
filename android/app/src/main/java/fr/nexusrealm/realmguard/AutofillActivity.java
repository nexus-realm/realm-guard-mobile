package fr.nexusrealm.realmguard;

import android.os.Bundle;
import android.view.WindowManager;

import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterFragmentActivity;

/**
 * Flutter activity launched by the OS autofill service (via the
 * flutter_autofill_service plugin) to serve a fill request. It runs the
 * dedicated Dart entrypoint {@code autofillEntryPoint} instead of {@code main}.
 *
 * <p>{@code FlutterFragmentActivity} (not {@code FlutterActivity}) so that
 * biometric unlock (local_auth) works inside the autofill flow. {@code
 * FLAG_SECURE} is applied because this screen presents vault credentials.
 */
public class AutofillActivity extends FlutterFragmentActivity {
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        getWindow().setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE);
        super.onCreate(savedInstanceState);
    }

    @Override
    public String getDartEntrypointFunctionName() {
        return "autofillEntryPoint";
    }
}
