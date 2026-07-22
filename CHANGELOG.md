# [1.1.0](https://github.com/nexus-realm/realm-guard-mobile/compare/v1.0.0...v1.1.0) (2026-07-22)


### Bug Fixes

* autofill json provider ([2b7db9e](https://github.com/nexus-realm/realm-guard-mobile/commit/2b7db9e8a4de6fb28af733ac3e433163d08fa663))
* **onboarding:** re-enter via the startup gate after pairing/recovery ([a0e5873](https://github.com/nexus-realm/realm-guard-mobile/commit/a0e587365bcbb6bd986df3c27ba2fc97a4cde8b1))
* **pairing:** green check on the device-added success screen ([707d841](https://github.com/nexus-realm/realm-guard-mobile/commit/707d8415b3cabd2eddd33e41474b9f376411b3d3))
* **sync:** serialize doc read-modify-write with a shared mutex ([e65cec0](https://github.com/nexus-realm/realm-guard-mobile/commit/e65cec0f77fdbf3f1997f3dcd91a163afb7486f1))


### Features

* **auth:** add OPAQUE auth service (FFI + HTTP + session storage) ([1093810](https://github.com/nexus-realm/realm-guard-mobile/commit/10938103ccdeb7bc7534b6b462ed6a0dd4e4cfb2))
* **auth:** add sync (register/login) screen under Settings ([776e68a](https://github.com/nexus-realm/realm-guard-mobile/commit/776e68af7bbffec70f23d067600dcedb230e5f26))
* **auth:** enforce sync account username & password rules ([3049118](https://github.com/nexus-realm/realm-guard-mobile/commit/3049118168a4c79586cd8f2f6ab17053cae567a0))
* **auth:** expose OPAQUE client functions over the FFI ([cd3425d](https://github.com/nexus-realm/realm-guard-mobile/commit/cd3425d4d7a57adeda2094ebe5426e42fa51052a))
* **auth:** upload and fetch the wrapped vault key over OPAQUE ([2150260](https://github.com/nexus-realm/realm-guard-mobile/commit/21502605c72aeaca131d6ac28b686396aae262da))
* **devices:** device management screen with rename and revoke ([10b0159](https://github.com/nexus-realm/realm-guard-mobile/commit/10b0159c6dd8afd10e4631de7600913a696ee722))
* integrate Rust core via flutter_rust_bridge ([9a05dfa](https://github.com/nexus-realm/realm-guard-mobile/commit/9a05dfa89979fe041ff6828258aa0cf544b8c668))
* **onboarding:** move sync step before master password, add device-link option ([4f93d4c](https://github.com/nexus-realm/realm-guard-mobile/commit/4f93d4ce14ee28b9f28e6bdfe8febdcf2c4e4506))
* **pairing:** device identity, registry enrolment and device sessions ([6960c67](https://github.com/nexus-realm/realm-guard-mobile/commit/6960c673f25e38fe7c79a353c75edb52982c9d13))
* **pairing:** device pairing FFI + service (relay transport) ([05962c5](https://github.com/nexus-realm/realm-guard-mobile/commit/05962c5a801f079e835ef2d5bd00c7f9c451f97f))
* **pairing:** install a paired VaultKey during onboarding ([d3c55a4](https://github.com/nexus-realm/realm-guard-mobile/commit/d3c55a455a5eadcff31c3fa5a48fd397eaa058c5))
* **pairing:** pairing UX (QR display/scan, SAS, biometric gate) ([1730c0d](https://github.com/nexus-realm/realm-guard-mobile/commit/1730c0d3f15598981444965f6d39d583460c8a8b))
* **pairing:** two-round handshake, the SAS now prevents instead of detecting ([1004993](https://github.com/nexus-realm/realm-guard-mobile/commit/1004993035ad31235b3cdc24286c078c8217b3a9))
* **recovery:** restore the vault from the server backup ([4af8c8a](https://github.com/nexus-realm/realm-guard-mobile/commit/4af8c8a78c3033d5840a12b6d75af6ecec24b2b4))
* **security:** migrate the vault to the VaultKey model ([f0d10cd](https://github.com/nexus-realm/realm-guard-mobile/commit/f0d10cd7ce4fb83cfcf7db53972fc34f912c82b4))
* **sync:** atomic delta enqueue + periodic snapshot compaction ([569e364](https://github.com/nexus-realm/realm-guard-mobile/commit/569e364061158ca80e501da9fa1ba4709325116c))
* **sync:** back up the wrapped vault key on login ([606da4e](https://github.com/nexus-realm/realm-guard-mobile/commit/606da4e46c9d39c7640bc41bf3558504c8773065))
* **sync:** crdt FFI value primitives — entry id, field crypto, hlc tick ([d30345d](https://github.com/nexus-realm/realm-guard-mobile/commit/d30345d0eb7e78677f9e6f4a2f43f4f51e0333ed))
* **sync:** crdt vault-doc FFI (structural) ([c267d8f](https://github.com/nexus-realm/realm-guard-mobile/commit/c267d8f1d26323bafc8175857a2863b85bb0f319))
* **sync:** crdt write-through engine + doc store (schema v5->v6) ([3eb6ab8](https://github.com/nexus-realm/realm-guard-mobile/commit/3eb6ab881f17f3100370c48682eab2f998cbfcdc))
* **sync:** manual sync via pull-to-refresh ([7d97665](https://github.com/nexus-realm/realm-guard-mobile/commit/7d97665ad75bd671876c285829c443254fdbcda3))
* **sync:** mobile sync log client (SyncApi) ([a940931](https://github.com/nexus-realm/realm-guard-mobile/commit/a940931dc8374fc48d4f9e03c5afc03e362f47cf))
* **sync:** onboarding sync step, merged settings, account-password copy ([e741fa0](https://github.com/nexus-realm/realm-guard-mobile/commit/e741fa0cfd2ba4e62d9a795a74dc79b36b59e920))
* **sync:** passive notification when a pull changes the vault ([e1ae573](https://github.com/nexus-realm/realm-guard-mobile/commit/e1ae573e5368c7078335788aeac4c7d6780fc3c9))
* **sync:** passive notification when a pull changes the vault ([7bfb43e](https://github.com/nexus-realm/realm-guard-mobile/commit/7bfb43ef5c2a9769eb8e5b7edbc6f787f1f69762))
* **sync:** pending-delta queue + pull cursor (schema v6->v7) ([04cb696](https://github.com/nexus-realm/realm-guard-mobile/commit/04cb69661256d04751725c193bae743849fa4756))
* **sync:** realtime wake socket + sync controller ([c2a31f2](https://github.com/nexus-realm/realm-guard-mobile/commit/c2a31f2380d6854b7b0a9bb8b8e2b311bb3bec50))
* **sync:** reproject the CRDT doc back into drift ([4798e0c](https://github.com/nexus-realm/realm-guard-mobile/commit/4798e0c360d18e496f60e8e5a446ce502163374a))
* **sync:** sync engine — push, pull, merge, reproject ([48cf234](https://github.com/nexus-realm/realm-guard-mobile/commit/48cf234fd5606fe7174778ede293765d1a5a6f9b))
* **sync:** vaultDoc↔drift projection + syncId schema (v4→v5) ([dae025c](https://github.com/nexus-realm/realm-guard-mobile/commit/dae025ccb51baf9dfb0898946580e2430ba97587))
* **sync:** wire CRDT write-through into the live vault ([2e829ab](https://github.com/nexus-realm/realm-guard-mobile/commit/2e829ab6aa08e375047070589faba3627ee2bbbd))
* **sync:** wire sync into the app lifecycle ([fb55444](https://github.com/nexus-realm/realm-guard-mobile/commit/fb554446487595fbc110ff6aa124d83d93fd5ea0))



# [1.0.0](https://github.com/nexus-realm/realm-guard-mobile/compare/v0.2.0...v1.0.0) (2026-07-08)


* feat!: first stable release ([eeab6e4](https://github.com/nexus-realm/realm-guard-mobile/commit/eeab6e46959dcde66d5379bbc069927c5f5a3a85))


### BREAKING CHANGES

* first public stable release (1.0.0).



# [0.2.0](https://github.com/nexus-realm/realm-guard-mobile/compare/3e8531a849f4154f50ac985a3521680355eb1c1c...v0.2.0) (2026-07-04)


### Bug Fixes

* add path provider to dependencies ([089e23a](https://github.com/nexus-realm/realm-guard-mobile/commit/089e23add5f767308911d4c5630b212a5a2d6fb9))
* correct copilot reviews ([6565ba3](https://github.com/nexus-realm/realm-guard-mobile/commit/6565ba3d2ebaad4cf09ea3d52389a03e2a85b97a))
* delete unused test ([afa1516](https://github.com/nexus-realm/realm-guard-mobile/commit/afa1516ba84aa1fe7bb77d33f85eb2847b989a0c))
* fix copilot review ([0c99ac8](https://github.com/nexus-realm/realm-guard-mobile/commit/0c99ac8867e316015ed057b31f045492a84ba9a1))
* fix copilot reviews ([76f0166](https://github.com/nexus-realm/realm-guard-mobile/commit/76f0166dc7400260a09edd67f8062a34c19f7355))
* fix test startup gate ([e23a9f9](https://github.com/nexus-realm/realm-guard-mobile/commit/e23a9f9be1d5338d30c83a0f6265a5bd329c57e2))
* **home:** prevent RangeError when selecting the Partage tab ([ef7c67f](https://github.com/nexus-realm/realm-guard-mobile/commit/ef7c67f281bb4e67fd3900fef92691358af5d1a1))
* **i18n:** correct French copy (accents, typos, terminology) ([ded6460](https://github.com/nexus-realm/realm-guard-mobile/commit/ded6460a931042c573b4de709703045a53ff0575))
* linter issues ([906c0d8](https://github.com/nexus-realm/realm-guard-mobile/commit/906c0d88c72546ef007bd3fafeae277620555c58))
* load cooldown timer on launch, fix biometric attempt on unlock ([c6239bf](https://github.com/nexus-realm/realm-guard-mobile/commit/c6239bfdc42859c6339b76a3bf4bd61e98df1cd6))
* **onboarding:** remove app bar causing a top offset ([684ed79](https://github.com/nexus-realm/realm-guard-mobile/commit/684ed7957f18b1b8b93fbc8c833b7e158692bf35))
* remove unsuned dependencies, lower iterations argon, convert classes to utility class ([496ce57](https://github.com/nexus-realm/realm-guard-mobile/commit/496ce57c4e1699c3e7bb2e85a09b50c9dfbe9d71))
* **security:** guard protected routes behind an unlocked vault ([d118581](https://github.com/nexus-realm/realm-guard-mobile/commit/d11858180a72ba50cdb1114b092969c167bed430))
* **security:** reset failed-attempt tracking after an inactivity window ([6a46fec](https://github.com/nexus-realm/realm-guard-mobile/commit/6a46fec909743d3bce0cb85ea82e7e5df4969fb5))
* **security:** set FLAG_SECURE to block screenshots ([ab3583e](https://github.com/nexus-realm/realm-guard-mobile/commit/ab3583e017e9de286d9c52ec42746060e56d911d))
* **security:** stop biometric failures from triggering the password lockout ([aab8583](https://github.com/nexus-realm/realm-guard-mobile/commit/aab8583e9725e3c311314c6df5080f671299a0c8))
* **security:** stop leaking error details on unlock failure, unify biometric fallback threshold ([fde72d2](https://github.com/nexus-realm/realm-guard-mobile/commit/fde72d27f88d6f0386db9b29957095d65a49c287))
* **security:** verify current password by key comparison, not a 2nd DB connection ([587d9fc](https://github.com/nexus-realm/realm-guard-mobile/commit/587d9fcfa5d2ca49c560c8475240c404a3c9aacb))
* **settings:** make 'delete all data' complete and race-free ([82fa0de](https://github.com/nexus-realm/realm-guard-mobile/commit/82fa0de8881b4cc8e505f17c0863a4737e4a1cfd))
* **ui:** let PasswordForm not dispose parent-owned controllers ([9dd14f0](https://github.com/nexus-realm/realm-guard-mobile/commit/9dd14f0f310ce0260e6f2d0de2798043b98ead68))


### Features

* add biometrics method to get derived key and unlock databse ([d07fdbb](https://github.com/nexus-realm/realm-guard-mobile/commit/d07fdbb301f584aac84c9bbfac70515bd0201774))
* add dark theme to the app, lock screen orientation to portraitUp ([b3b26a7](https://github.com/nexus-realm/realm-guard-mobile/commit/b3b26a74c14c10b524d902b30d7f086a8de3be89))
* add database and encryption for it with debug page ([630ce74](https://github.com/nexus-realm/realm-guard-mobile/commit/630ce74639c0954c0254bd0e687eb2c367dc6704))
* add dependencies and key prodiver / generation for database encryption from master password ([e812f0a](https://github.com/nexus-realm/realm-guard-mobile/commit/e812f0ade4af25b03e477ad99b1167cad2532071))
* add go_router package, add router config and default main page ([6695c92](https://github.com/nexus-realm/realm-guard-mobile/commit/6695c922b158d9a31841c1b594d1b4ab016d0a3a))
* add gradient button and animation widget; use bottom sheet to add profiles credentials ([0252a9b](https://github.com/nexus-realm/realm-guard-mobile/commit/0252a9b444e0ec6cee1105a3e865a88b6df82d89))
* add onboarding page and startup gate, using mvvm and feature first architecture ([0b222d0](https://github.com/nexus-realm/realm-guard-mobile/commit/0b222d0a7c336b6d606a730e39dfeace1a5fc2ff))
* add otp qr code scan ([de91d22](https://github.com/nexus-realm/realm-guard-mobile/commit/de91d22ca057f4828332169c209a3dcad557f96f))
* add unlock page with password and biometric, move form password to be reusable ([41ce60e](https://github.com/nexus-realm/realm-guard-mobile/commit/41ce60e1be3e059de9bb2afe8298b1f760cf18c5))
* ajout de husky pour les messages de commit ([3e8531a](https://github.com/nexus-realm/realm-guard-mobile/commit/3e8531a849f4154f50ac985a3521680355eb1c1c))
* ajout markdown agent pour fiabilisé et définir le context du projet lors de leur utilisation ([9c7cc98](https://github.com/nexus-realm/realm-guard-mobile/commit/9c7cc982c8ec4b1a8ce5b3476f081d6aa362432c))
* **autofill:** app→domain matching + branded dropdown icon ([66784b5](https://github.com/nexus-realm/realm-guard-mobile/commit/66784b589d7d5115e17792ffba34bf485dae9512))
* **autofill:** interactive fill flow ([764b324](https://github.com/nexus-realm/realm-guard-mobile/commit/764b324a7eae56dbd6e5bfa321ac61c84857c273))
* **autofill:** register Realm Guard as an Android autofill service ([eb5a46a](https://github.com/nexus-realm/realm-guard-mobile/commit/eb5a46a660ea398dbf2525c51bd85f1aff4118b6))
* **autofill:** save new credentials from third-party apps ([f8055b2](https://github.com/nexus-realm/realm-guard-mobile/commit/f8055b2b74f5a94fd0db7e1e64735a8b9771140d))
* **home:** add profile and credential creation pages ([34d5259](https://github.com/nexus-realm/realm-guard-mobile/commit/34d525992941ec7968e4e748fa080c1fb0ef0483))
* **home:** distinguish loading, empty and result states ([a558561](https://github.com/nexus-realm/realm-guard-mobile/commit/a5585610a9030c403a7295c8296c066f0156f887))
* **onboarding:** add TOTP enable/disable step with safe migration ([74f6d0b](https://github.com/nexus-realm/realm-guard-mobile/commit/74f6d0b44cc00c55864e68e761b74526414ed74c))
* **profiles:** show linked credentials and TOTP on the profile page ([1b4e763](https://github.com/nexus-realm/realm-guard-mobile/commit/1b4e7634fa649949836ec6599f4504fec03ee086))
* **security:** auto-lock vault on background and inactivity ([a6b386f](https://github.com/nexus-realm/realm-guard-mobile/commit/a6b386f74c2ac7ea7a88390c5a9af466167d5c14))
* **security:** change master password via SQLCipher rekey ([653a11d](https://github.com/nexus-realm/realm-guard-mobile/commit/653a11d7effdd672ce9bb771c2afc29b6b12e7b0))
* **security:** protect vault key with auth-bound Android Keystore wrapping ([26c2e15](https://github.com/nexus-realm/realm-guard-mobile/commit/26c2e1573b1d5c0583d4cbd653aa75d204395e73))
* **settings:** add registry-driven feature-flag foundation ([9c96b7a](https://github.com/nexus-realm/realm-guard-mobile/commit/9c96b7a3aaf6f31ea7916361bc248ba10e80d0a5))
* **settings:** add settings page with about, biometrics and data wipe ([3ad7eb4](https://github.com/nexus-realm/realm-guard-mobile/commit/3ad7eb45b046605939b8853468e295de2661bdb2))
* **settings:** toggle TOTP management with live home gating ([e373f12](https://github.com/nexus-realm/realm-guard-mobile/commit/e373f122581b4d0878b2fe1d3fc7753ac854b90f))
* **totp:** add/view/edit/delete TOTP entries ([8737c2c](https://github.com/nexus-realm/realm-guard-mobile/commit/8737c2cbda83c4228ebc7a95a1884089da9d0efb))
* **totp:** data foundation, Totps table, RFC 6238 generator, repository ([2a94faa](https://github.com/nexus-realm/realm-guard-mobile/commit/2a94faa9d9e741b6daa51b5414a4cbf353c01bd8))
* **totp:** vault TabBar (Identifiants | TOTP) and live code list ([d8401a9](https://github.com/nexus-realm/realm-guard-mobile/commit/d8401a9cfc6363650f9af19de7bbd8f8f2d6b49a))
* **unlock:** display lockout countdown as mm:ss ([24c19d8](https://github.com/nexus-realm/realm-guard-mobile/commit/24c19d875f21e88892d2d4e32a5175c8d1d53166))
* update app theme, adjust on_boarding, add password validation and rules ([210e8d5](https://github.com/nexus-realm/realm-guard-mobile/commit/210e8d50b1eb6a4f7e1ff0cfdb33abea7716959b))
* update ci to only authorize merge PR with rules ([5b886e6](https://github.com/nexus-realm/realm-guard-mobile/commit/5b886e620e6eb0760ecf9c8c9c13b32163f75a2a))
* update encryption system to implement salt and argon encryption ([8a30b90](https://github.com/nexus-realm/realm-guard-mobile/commit/8a30b90741de40216aaa3b13a2b9822f9b84c829))
* use generic password form unlock app, fix too much try snackbar loop ([518c47b](https://github.com/nexus-realm/realm-guard-mobile/commit/518c47ba88b7245c138d94fc68e426f35de0bffc))
* **vault:** add password strength indicator show password strength in read view, restyle cancel ([9bbadde](https://github.com/nexus-realm/realm-guard-mobile/commit/9bbaddebffa00843bc4073516087622b1458d6dc))
* **vault:** enrich credential & profile data model (schema v3) ([0b784c7](https://github.com/nexus-realm/realm-guard-mobile/commit/0b784c7712011c3c813dc8135860063d173d8419))
* **vault:** full credential UI (username, password, uri, notes, custom fields) ([821d12d](https://github.com/nexus-realm/realm-guard-mobile/commit/821d12dd09b57de0759ccd1f21e4ad06ea97356a))
* **vault:** full profile UI (emails, usernames, phones, color, note) + richer search ([b8706fb](https://github.com/nexus-realm/realm-guard-mobile/commit/b8706fb3e637f7ca44e9aace49ff4d852950d560))
* **vault:** generate credential avatars from the URL domain (offline) ([919c946](https://github.com/nexus-realm/realm-guard-mobile/commit/919c946ec53f93fd395e98f7399dc6bf2fcb2df9))
* **vault:** view, edit and delete profiles and credentials ([248459c](https://github.com/nexus-realm/realm-guard-mobile/commit/248459cba9eb31ef2c52eddb605714bf25b03ea3))
* wip add home page, add table and migration for profiles and credentials ([2a8c284](https://github.com/nexus-realm/realm-guard-mobile/commit/2a8c2846f4ba8d30f93098a1da2ed0ef01b5ce53))


### Performance Improvements

* **fonts:** bundle fonts natively and drop google_fonts (offline-first) ([0a55af6](https://github.com/nexus-realm/realm-guard-mobile/commit/0a55af65071250d62303b901253c486d1b8c3484))
* **home:** make the vault list reactive and debounce search ([5faf2d6](https://github.com/nexus-realm/realm-guard-mobile/commit/5faf2d6fe6ffa4449e47696f3cf50d748f357b8b))
* **security:** make the unlock cooldown a real throttle ([d70453d](https://github.com/nexus-realm/realm-guard-mobile/commit/d70453d09ea1dd6e449499343ce55c658e5a9f59))
* **security:** run Argon2id key derivation on a background isolate ([5673c4f](https://github.com/nexus-realm/realm-guard-mobile/commit/5673c4f43aa93f6cb2a544409faf0a77502a2d89))
* **unlock:** count down lockout in memory instead of polling secure storage ([739ab2f](https://github.com/nexus-realm/realm-guard-mobile/commit/739ab2f57a4abc307ae0c9b1e3aa612087f7b449))



