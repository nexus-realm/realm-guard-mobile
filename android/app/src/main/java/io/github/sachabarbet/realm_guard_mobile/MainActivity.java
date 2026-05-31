package io.github.sachabarbet.realm_guard_mobile;

import android.os.Bundle;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterFragmentActivity {
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        // Security-first: mark the whole window as secure. This blocks
        // screenshots and screen recording, hides app content in the
        // recent-apps switcher, and prevents rendering on non-secure displays.
        // Applies to every Flutter route (onboarding, unlock, home).
        getWindow().setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE);
        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        KeystoreKeyGuard.register(flutterEngine, getApplicationContext());
    }
}
