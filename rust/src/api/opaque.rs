//! Pont FFI vers l'authentification **OPAQUE côté client** du cœur.
//!
//! Le serveur n'apprend jamais le mot de passe : ces fonctions produisent les
//! messages OPAQUE à envoyer au serveur et consomment ses réponses. Les fonctions
//! lourdes (Argon2 au `finish`) sont **asynchrones** côté Dart (frb les exécute
//! hors de l'isolate principal), d'où l'absence de `#[frb(sync)]`.

use realm_guard_core::auth;

/// Résultat d'un `*_start` client : état à conserver + message pour le serveur.
pub struct OpaqueClientStart {
    /// État opaque à conserver côté client jusqu'au `finish`.
    pub state: Vec<u8>,
    /// Message à envoyer au serveur.
    pub message: Vec<u8>,
}

/// Résultat de la finalisation d'enregistrement.
pub struct OpaqueRegisterFinish {
    /// `RegistrationUpload` à envoyer au serveur.
    pub upload: Vec<u8>,
    /// Clé exportée (côté client, stable).
    pub export_key: Vec<u8>,
}

/// Résultat de la finalisation de connexion.
pub struct OpaqueLoginFinish {
    /// `CredentialFinalization` à envoyer au serveur.
    pub finalization: Vec<u8>,
    /// Clé de session mutuelle.
    pub session_key: Vec<u8>,
    /// Clé exportée (côté client, stable).
    pub export_key: Vec<u8>,
}

/// Démarre l'enregistrement OPAQUE à partir du mot de passe maître.
pub fn opaque_register_start(password: String) -> Result<OpaqueClientStart, String> {
    let result = auth::client_register_start(password.as_bytes()).map_err(|e| e.to_string())?;
    Ok(OpaqueClientStart {
        state: result.state,
        message: result.request,
    })
}

/// Finalise l'enregistrement à partir de la réponse du serveur.
pub fn opaque_register_finish(
    state: Vec<u8>,
    password: String,
    response: Vec<u8>,
) -> Result<OpaqueRegisterFinish, String> {
    let result = auth::client_register_finish(&state, password.as_bytes(), &response)
        .map_err(|e| e.to_string())?;
    Ok(OpaqueRegisterFinish {
        upload: result.upload,
        export_key: result.export_key.as_bytes().to_vec(),
    })
}

/// Démarre la connexion OPAQUE à partir du mot de passe maître.
pub fn opaque_login_start(password: String) -> Result<OpaqueClientStart, String> {
    let result = auth::client_login_start(password.as_bytes()).map_err(|e| e.to_string())?;
    Ok(OpaqueClientStart {
        state: result.state,
        message: result.request,
    })
}

/// Finalise la connexion. **Échoue si le mot de passe est faux.**
pub fn opaque_login_finish(
    state: Vec<u8>,
    password: String,
    response: Vec<u8>,
) -> Result<OpaqueLoginFinish, String> {
    let result = auth::client_login_finish(&state, password.as_bytes(), &response)
        .map_err(|e| e.to_string())?;
    Ok(OpaqueLoginFinish {
        finalization: result.finalization,
        session_key: result.session_key.as_bytes().to_vec(),
        export_key: result.export_key.as_bytes().to_vec(),
    })
}
