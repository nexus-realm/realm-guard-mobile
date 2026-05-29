package io.github.sachabarbet.realm_guard_mobile;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterFragmentActivity {
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        KeystoreKeyGuard.register(flutterEngine, getApplicationContext());
    }
}
