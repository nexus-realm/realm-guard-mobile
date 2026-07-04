package fr.nexusrealm.realmguard;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.KeyguardManager;
import android.content.Context;
import android.os.Build;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;

import androidx.annotation.NonNull;

import java.security.Key;
import java.security.KeyFactory;
import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.spec.MGF1ParameterSpec;
import java.security.spec.X509EncodedKeySpec;

import javax.crypto.Cipher;
import javax.crypto.spec.OAEPParameterSpec;
import javax.crypto.spec.PSource;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Native bridge that protects the derived vault key with a hardware-backed,
 * authentication-bound Android Keystore key pair.
 *
 * <p>An RSA key pair is generated with {@code setUserAuthenticationRequired(true)}
 * and {@code setUserAuthenticationValidityDurationSeconds(...)}. The public key
 * encrypts (wraps) the vault key without authentication; the private key
 * decrypts (unwraps) it only when the user authenticated within the validity
 * window. The plaintext vault key is therefore never persisted.
 */
final class KeystoreKeyGuard implements MethodChannel.MethodCallHandler {

    private static final String CHANNEL =
        "fr.nexusrealm.realmguard/secure_keystore";
    private static final String ANDROID_KEYSTORE = "AndroidKeyStore";
    private static final String KEY_ALIAS = "realm_guard_vault_key_wrapper";
    private static final String TRANSFORMATION =
        "RSA/ECB/OAEPWithSHA-256AndMGF1Padding";

    /**
     * Seconds during which unwrap (private-key decrypt) is allowed after a
     * successful device / biometric authentication. Kept short: the app
     * authenticates with local_auth immediately before each unwrap.
     */
    private static final int AUTH_VALIDITY_SECONDS = 30;

    private final Context context;

    private KeystoreKeyGuard(@NonNull Context context) {
        this.context = context.getApplicationContext();
    }

    static void register(@NonNull FlutterEngine engine, @NonNull Context context) {
        final MethodChannel channel = new MethodChannel(
            engine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(new KeystoreKeyGuard(context));
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        try {
            switch (call.method) {
                case "isAvailable":
                    result.success(isAvailable());
                    break;
                case "wrap": {
                    final byte[] plaintext = call.argument("key");
                    if (plaintext == null) {
                        result.error("invalid_args", "Missing key bytes", null);
                        return;
                    }
                    result.success(wrap(plaintext));
                    break;
                }
                case "unwrap": {
                    final byte[] blob = call.argument("blob");
                    if (blob == null) {
                        result.error("invalid_args", "Missing blob", null);
                        return;
                    }
                    result.success(unwrap(blob));
                    break;
                }
                case "deleteKey":
                    deleteKey();
                    result.success(null);
                    break;
                default:
                    result.notImplemented();
            }
        } catch (Exception e) {
            // Match by simple name to avoid referencing API 23+ exception
            // classes on devices where they do not exist.
            final String name = e.getClass().getSimpleName();
            if ("UserNotAuthenticatedException".equals(name)) {
                result.error("user_not_authenticated", "Authentication required", null);
            } else if ("KeyPermanentlyInvalidatedException".equals(name)) {
                result.error("key_invalidated", "Key permanently invalidated", null);
            } else {
                result.error("keystore_error", name, null);
            }
        }
    }

    @SuppressLint("NewApi")
    private boolean isAvailable() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return false;
        }
        final KeyguardManager km =
            (KeyguardManager) context.getSystemService(Context.KEYGUARD_SERVICE);
        return km != null && km.isDeviceSecure();
    }

    private byte[] wrap(@NonNull byte[] plaintext) throws Exception {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            throw new IllegalStateException("Keystore user-auth keys require API 23+");
        }
        getOrCreateKeyPair();

        final KeyStore keyStore = KeyStore.getInstance(ANDROID_KEYSTORE);
        keyStore.load(null);
        final PublicKey publicKey = keyStore.getCertificate(KEY_ALIAS).getPublicKey();

        // Re-import the public key from its encoded form so the encryption is
        // performed by the default JCE provider and is NOT subject to the
        // private key's user-authentication constraint.
        final PublicKey unrestricted = KeyFactory.getInstance(publicKey.getAlgorithm())
            .generatePublic(new X509EncodedKeySpec(publicKey.getEncoded()));

        final Cipher cipher = Cipher.getInstance(TRANSFORMATION);
        cipher.init(Cipher.ENCRYPT_MODE, unrestricted, oaepSpec());
        return cipher.doFinal(plaintext);
    }

    private byte[] unwrap(@NonNull byte[] ciphertext) throws Exception {
        final KeyStore keyStore = KeyStore.getInstance(ANDROID_KEYSTORE);
        keyStore.load(null);
        final Key key = keyStore.getKey(KEY_ALIAS, null);
        if (!(key instanceof PrivateKey)) {
            throw new IllegalStateException("Missing private key");
        }
        final Cipher cipher = Cipher.getInstance(TRANSFORMATION);
        // Throws UserNotAuthenticatedException / KeyPermanentlyInvalidatedException
        // when the auth window has expired or the key was invalidated.
        cipher.init(Cipher.DECRYPT_MODE, (PrivateKey) key, oaepSpec());
        return cipher.doFinal(ciphertext);
    }

    private void deleteKey() throws Exception {
        final KeyStore keyStore = KeyStore.getInstance(ANDROID_KEYSTORE);
        keyStore.load(null);
        if (keyStore.containsAlias(KEY_ALIAS)) {
            keyStore.deleteEntry(KEY_ALIAS);
        }
    }

    private OAEPParameterSpec oaepSpec() {
        // Android Keystore uses MGF1 with SHA-1 internally even when the main
        // digest is SHA-256. Pin it explicitly so encrypt and decrypt agree.
        return new OAEPParameterSpec(
            "SHA-256", "MGF1", MGF1ParameterSpec.SHA1, PSource.PSpecified.DEFAULT);
    }

    @TargetApi(Build.VERSION_CODES.M)
    @SuppressLint("NewApi")
    @SuppressWarnings("deprecation")
    private void getOrCreateKeyPair() throws Exception {
        final KeyStore keyStore = KeyStore.getInstance(ANDROID_KEYSTORE);
        keyStore.load(null);
        if (keyStore.containsAlias(KEY_ALIAS)) {
            return;
        }

        final KeyGenParameterSpec.Builder builder = new KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_OAEP)
            .setKeySize(2048)
            .setUserAuthenticationRequired(true)
            // Bind usability to a post-authentication time window. Deprecated in
            // API 30 (maps to BIOMETRIC_STRONG | DEVICE_CREDENTIAL) but still the
            // requested mechanism and works across supported API levels.
            .setUserAuthenticationValidityDurationSeconds(AUTH_VALIDITY_SECONDS);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            // Invalidate the key if biometrics are re-enrolled: forces a fresh
            // password unlock, which re-wraps the vault key under a new key.
            builder.setInvalidatedByBiometricEnrollment(true);
        }

        final KeyPairGenerator generator = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_RSA, ANDROID_KEYSTORE);
        generator.initialize(builder.build());
        generator.generateKeyPair();
    }
}
