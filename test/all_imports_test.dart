// GÉNÉRÉ par tool/gen_coverage_imports.dart — ne pas éditer.
//
// Importe tous les fichiers de `lib/` pour qu ils apparaissent dans le
// rapport de couverture (Dart n instrumente que ce qui est importé), et
// vérifie que cette liste reste synchronisée avec le disque.
//
// ignore_for_file: unused_import, directives_ordering
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/database/app_database.dart' as i0;
import 'package:realmguard/core/database/models/crdt_docs.dart' as i1;
import 'package:realmguard/core/database/models/credentials.dart' as i2;
import 'package:realmguard/core/database/models/pending_deltas.dart' as i3;
import 'package:realmguard/core/database/models/profiles.dart' as i4;
import 'package:realmguard/core/database/models/sync_id.dart' as i5;
import 'package:realmguard/core/database/models/totps.dart' as i6;
import 'package:realmguard/core/database/vault_repository.dart' as i7;
import 'package:realmguard/core/exceptions/security_exception.dart' as i8;
import 'package:realmguard/core/exceptions/vault_unlock_exception.dart' as i9;
import 'package:realmguard/core/feature_flags/feature_flag.dart' as i10;
import 'package:realmguard/core/feature_flags/feature_flags_controller.dart'
    as i11;
import 'package:realmguard/core/feature_flags/feature_flags_service.dart'
    as i12;
import 'package:realmguard/core/routes/app_router.dart' as i13;
import 'package:realmguard/core/routes/app_routes.dart' as i14;
import 'package:realmguard/core/routes/route_guard.dart' as i15;
import 'package:realmguard/core/security/app_lock_controller.dart' as i16;
import 'package:realmguard/core/security/biometric_storage_service.dart' as i17;
import 'package:realmguard/core/security/key_derivator.dart' as i18;
import 'package:realmguard/core/security/keystore_key_guard.dart' as i19;
import 'package:realmguard/core/security/password_validation_rule.dart' as i20;
import 'package:realmguard/core/security/password_validation_rules.dart' as i21;
import 'package:realmguard/core/security/salt_manager.dart' as i22;
import 'package:realmguard/core/security/unlock_service.dart' as i23;
import 'package:realmguard/core/security/vault_key_crypto.dart' as i24;
import 'package:realmguard/core/security/vault_migrator.dart' as i25;
import 'package:realmguard/core/security/vault_service.dart' as i26;
import 'package:realmguard/core/security/wrapped_vault_key_store.dart' as i27;
import 'package:realmguard/core/sync/crdt_device_id_store.dart' as i28;
import 'package:realmguard/core/sync/crdt_ffi.dart' as i29;
import 'package:realmguard/core/sync/drift_projector.dart' as i30;
import 'package:realmguard/core/sync/field_value.dart' as i31;
import 'package:realmguard/core/sync/mutex.dart' as i32;
import 'package:realmguard/core/sync/pending_delta_store.dart' as i33;
import 'package:realmguard/core/sync/vault_crdt.dart' as i34;
import 'package:realmguard/core/sync/vault_doc_store.dart' as i35;
import 'package:realmguard/core/sync/vault_fields.dart' as i36;
import 'package:realmguard/core/sync/vault_projection.dart' as i37;
import 'package:realmguard/core/sync/vault_row_map.dart' as i38;
import 'package:realmguard/core/sync/vault_seed.dart' as i39;
import 'package:realmguard/core/theme/app_colors.dart' as i40;
import 'package:realmguard/core/theme/app_decorations.dart' as i41;
import 'package:realmguard/core/theme/app_spacing.dart' as i42;
import 'package:realmguard/core/theme/app_theme.dart' as i43;
import 'package:realmguard/features/auth/data/account_credential_rules.dart'
    as i44;
import 'package:realmguard/features/auth/data/account_id.dart' as i45;
import 'package:realmguard/features/auth/data/auth_exception.dart' as i46;
import 'package:realmguard/features/auth/data/server_config.dart' as i47;
import 'package:realmguard/features/auth/data/stored_vault_key.dart' as i48;
import 'package:realmguard/features/auth/data/username_rules.dart' as i49;
import 'package:realmguard/features/auth/service/auth_service.dart' as i50;
import 'package:realmguard/features/auth/service/opaque_client.dart' as i51;
import 'package:realmguard/features/auth/service/session_store.dart' as i52;
import 'package:realmguard/features/auth/service/vault_key_cipher.dart' as i53;
import 'package:realmguard/features/auth/viewmodels/sync_view_model.dart'
    as i54;
import 'package:realmguard/features/auth/viewmodels/vault_recovery_view_model.dart'
    as i55;
import 'package:realmguard/features/auth/views/sync_page.dart' as i56;
import 'package:realmguard/features/auth/views/vault_recovery_page.dart' as i57;
import 'package:realmguard/features/autofill/data/autofill_matcher.dart' as i58;
import 'package:realmguard/features/autofill/service/autofill_gateway.dart'
    as i59;
import 'package:realmguard/features/autofill/viewmodels/autofill_fill_view_model.dart'
    as i60;
import 'package:realmguard/features/autofill/viewmodels/autofill_save_view_model.dart'
    as i61;
import 'package:realmguard/features/autofill/viewmodels/autofill_settings_view_model.dart'
    as i62;
import 'package:realmguard/features/autofill/views/autofill_app.dart' as i63;
import 'package:realmguard/features/autofill/views/autofill_dispatcher.dart'
    as i64;
import 'package:realmguard/features/autofill/views/autofill_fill_page.dart'
    as i65;
import 'package:realmguard/features/autofill/views/autofill_save_page.dart'
    as i66;
import 'package:realmguard/features/autofill/views/widgets/autofill_settings_tile.dart'
    as i67;
import 'package:realmguard/features/debug/views/security_debug_page.dart'
    as i68;
import 'package:realmguard/features/debug/views/vault_debug_page.dart' as i69;
import 'package:realmguard/features/home/data/base32.dart' as i70;
import 'package:realmguard/features/home/data/credential_draft.dart' as i71;
import 'package:realmguard/features/home/data/custom_field.dart' as i72;
import 'package:realmguard/features/home/data/domain_identity.dart' as i73;
import 'package:realmguard/features/home/data/otpauth_parser.dart' as i74;
import 'package:realmguard/features/home/data/password_strength.dart' as i75;
import 'package:realmguard/features/home/data/profile_colors.dart' as i76;
import 'package:realmguard/features/home/data/profile_deletion_strategy.dart'
    as i77;
import 'package:realmguard/features/home/data/profile_draft.dart' as i78;
import 'package:realmguard/features/home/data/totp_draft.dart' as i79;
import 'package:realmguard/features/home/data/totp_generator.dart' as i80;
import 'package:realmguard/features/home/viewmodels/add_credential_view_model.dart'
    as i81;
import 'package:realmguard/features/home/viewmodels/add_profile_view_model.dart'
    as i82;
import 'package:realmguard/features/home/viewmodels/add_totp_view_model.dart'
    as i83;
import 'package:realmguard/features/home/viewmodels/credential_detail_view_model.dart'
    as i84;
import 'package:realmguard/features/home/viewmodels/profile_detail_view_model.dart'
    as i85;
import 'package:realmguard/features/home/viewmodels/totp_detail_view_model.dart'
    as i86;
import 'package:realmguard/features/home/views/add_credential_page.dart' as i87;
import 'package:realmguard/features/home/views/add_profile_page.dart' as i88;
import 'package:realmguard/features/home/views/add_totp_page.dart' as i89;
import 'package:realmguard/features/home/views/credential_detail_page.dart'
    as i90;
import 'package:realmguard/features/home/views/home_tab.dart' as i91;
import 'package:realmguard/features/home/views/profile_detail_page.dart' as i92;
import 'package:realmguard/features/home/views/profiles_page.dart' as i93;
import 'package:realmguard/features/home/views/scan_totp_page.dart' as i94;
import 'package:realmguard/features/home/views/totp_detail_page.dart' as i95;
import 'package:realmguard/features/home/views/widgets/confirm_delete_dialog.dart'
    as i96;
import 'package:realmguard/features/home/views/widgets/credential_avatar.dart'
    as i97;
import 'package:realmguard/features/home/views/widgets/credential_form.dart'
    as i98;
import 'package:realmguard/features/home/views/widgets/delete_profile_dialog.dart'
    as i99;
import 'package:realmguard/features/home/views/widgets/detail_tile.dart'
    as i100;
import 'package:realmguard/features/home/views/widgets/discard_changes_dialog.dart'
    as i101;
import 'package:realmguard/features/home/views/widgets/password_strength_indicator.dart'
    as i102;
import 'package:realmguard/features/home/views/widgets/profile_avatar.dart'
    as i103;
import 'package:realmguard/features/home/views/widgets/profile_form.dart'
    as i104;
import 'package:realmguard/features/home/views/widgets/profile_picker.dart'
    as i105;
import 'package:realmguard/features/home/views/widgets/totp_form.dart' as i106;
import 'package:realmguard/features/home/views/widgets/totp_list_tile.dart'
    as i107;
import 'package:realmguard/features/home/views/widgets/vault_list_tile.dart'
    as i108;
import 'package:realmguard/features/onboarding/data/onboarding_step.dart'
    as i109;
import 'package:realmguard/features/onboarding/service/onboarding_flow_controller.dart'
    as i110;
import 'package:realmguard/features/onboarding/service/onboarding_progress.dart'
    as i111;
import 'package:realmguard/features/onboarding/service/onboarding_storage_service.dart'
    as i112;
import 'package:realmguard/features/onboarding/viewmodels/onboarding_view_model.dart'
    as i113;
import 'package:realmguard/features/onboarding/viewmodels/startup_gate_view_model.dart'
    as i114;
import 'package:realmguard/features/onboarding/views/onboarding_page.dart'
    as i115;
import 'package:realmguard/features/onboarding/views/startup_gate_page.dart'
    as i116;
import 'package:realmguard/features/pairing/data/pairing_exception.dart'
    as i117;
import 'package:realmguard/features/pairing/service/device_key_ffi.dart'
    as i118;
import 'package:realmguard/features/pairing/service/device_key_store.dart'
    as i119;
import 'package:realmguard/features/pairing/service/devices_service.dart'
    as i120;
import 'package:realmguard/features/pairing/service/pairing_ffi.dart' as i121;
import 'package:realmguard/features/pairing/service/pairing_service.dart'
    as i122;
import 'package:realmguard/features/pairing/viewmodels/devices_view_model.dart'
    as i123;
import 'package:realmguard/features/pairing/viewmodels/paired_setup_view_model.dart'
    as i124;
import 'package:realmguard/features/pairing/viewmodels/pairing_receive_view_model.dart'
    as i125;
import 'package:realmguard/features/pairing/viewmodels/pairing_source_view_model.dart'
    as i126;
import 'package:realmguard/features/pairing/views/add_device_page.dart' as i127;
import 'package:realmguard/features/pairing/views/devices_page.dart' as i128;
import 'package:realmguard/features/pairing/views/paired_setup_page.dart'
    as i129;
import 'package:realmguard/features/pairing/views/pairing_qr_view.dart' as i130;
import 'package:realmguard/features/pairing/views/pairing_result_views.dart'
    as i131;
import 'package:realmguard/features/pairing/views/receive_device_page.dart'
    as i132;
import 'package:realmguard/features/settings/data/legal_documents.dart' as i133;
import 'package:realmguard/features/settings/service/app_info_service.dart'
    as i134;
import 'package:realmguard/features/settings/service/app_reset_service.dart'
    as i135;
import 'package:realmguard/features/settings/viewmodels/change_password_view_model.dart'
    as i136;
import 'package:realmguard/features/settings/viewmodels/settings_view_model.dart'
    as i137;
import 'package:realmguard/features/settings/views/about_page.dart' as i138;
import 'package:realmguard/features/settings/views/change_password_page.dart'
    as i139;
import 'package:realmguard/features/settings/views/legal_page.dart' as i140;
import 'package:realmguard/features/settings/views/settings_page.dart' as i141;
import 'package:realmguard/features/settings/views/widgets/delete_data_dialog.dart'
    as i142;
import 'package:realmguard/features/settings/views/widgets/settings_section.dart'
    as i143;
import 'package:realmguard/features/sync/data/sync_exception.dart' as i144;
import 'package:realmguard/features/sync/data/sync_models.dart' as i145;
import 'package:realmguard/features/sync/data/sync_outcome.dart' as i146;
import 'package:realmguard/features/sync/service/sync_api.dart' as i147;
import 'package:realmguard/features/sync/service/sync_controller.dart' as i148;
import 'package:realmguard/features/sync/service/sync_engine.dart' as i149;
import 'package:realmguard/features/sync/service/sync_session_controller.dart'
    as i150;
import 'package:realmguard/features/sync/service/sync_socket.dart' as i151;
import 'package:realmguard/features/unlock/viewmodels/unlock_view_model.dart'
    as i152;
import 'package:realmguard/features/unlock/views/unlock_page.dart' as i153;
import 'package:realmguard/main.dart' as i154;
import 'package:realmguard/shared/notifiers/fab_notifier.dart' as i155;
import 'package:realmguard/shared/notifiers/fab_notifier_scope.dart' as i156;
import 'package:realmguard/shared/notifiers/search_notifier.dart' as i157;
import 'package:realmguard/shared/notifiers/search_notifier_scope.dart' as i158;
import 'package:realmguard/shared/viewmodels/home_view_model.dart' as i159;
import 'package:realmguard/shared/views/home/home_shell.dart' as i160;
import 'package:realmguard/shared/widgets/app_snackbar.dart' as i161;
import 'package:realmguard/shared/widgets/choice_card.dart' as i162;
import 'package:realmguard/shared/widgets/destructive_button.dart' as i163;
import 'package:realmguard/shared/widgets/gradient_elevated_button.dart'
    as i164;
import 'package:realmguard/shared/widgets/neon_box_decoration.dart' as i165;
import 'package:realmguard/shared/widgets/password_form.dart' as i166;
import 'package:realmguard/shared/widgets/secondary_button.dart' as i167;
import 'package:realmguard/shared/widgets/view_title.dart' as i168;

/// Liste figée au moment de la génération.
const _generated = <String>[
  'lib/core/database/app_database.dart',
  'lib/core/database/models/crdt_docs.dart',
  'lib/core/database/models/credentials.dart',
  'lib/core/database/models/pending_deltas.dart',
  'lib/core/database/models/profiles.dart',
  'lib/core/database/models/sync_id.dart',
  'lib/core/database/models/totps.dart',
  'lib/core/database/vault_repository.dart',
  'lib/core/exceptions/security_exception.dart',
  'lib/core/exceptions/vault_unlock_exception.dart',
  'lib/core/feature_flags/feature_flag.dart',
  'lib/core/feature_flags/feature_flags_controller.dart',
  'lib/core/feature_flags/feature_flags_service.dart',
  'lib/core/routes/app_router.dart',
  'lib/core/routes/app_routes.dart',
  'lib/core/routes/route_guard.dart',
  'lib/core/security/app_lock_controller.dart',
  'lib/core/security/biometric_storage_service.dart',
  'lib/core/security/key_derivator.dart',
  'lib/core/security/keystore_key_guard.dart',
  'lib/core/security/password_validation_rule.dart',
  'lib/core/security/password_validation_rules.dart',
  'lib/core/security/salt_manager.dart',
  'lib/core/security/unlock_service.dart',
  'lib/core/security/vault_key_crypto.dart',
  'lib/core/security/vault_migrator.dart',
  'lib/core/security/vault_service.dart',
  'lib/core/security/wrapped_vault_key_store.dart',
  'lib/core/sync/crdt_device_id_store.dart',
  'lib/core/sync/crdt_ffi.dart',
  'lib/core/sync/drift_projector.dart',
  'lib/core/sync/field_value.dart',
  'lib/core/sync/mutex.dart',
  'lib/core/sync/pending_delta_store.dart',
  'lib/core/sync/vault_crdt.dart',
  'lib/core/sync/vault_doc_store.dart',
  'lib/core/sync/vault_fields.dart',
  'lib/core/sync/vault_projection.dart',
  'lib/core/sync/vault_row_map.dart',
  'lib/core/sync/vault_seed.dart',
  'lib/core/theme/app_colors.dart',
  'lib/core/theme/app_decorations.dart',
  'lib/core/theme/app_spacing.dart',
  'lib/core/theme/app_theme.dart',
  'lib/features/auth/data/account_credential_rules.dart',
  'lib/features/auth/data/account_id.dart',
  'lib/features/auth/data/auth_exception.dart',
  'lib/features/auth/data/server_config.dart',
  'lib/features/auth/data/stored_vault_key.dart',
  'lib/features/auth/data/username_rules.dart',
  'lib/features/auth/service/auth_service.dart',
  'lib/features/auth/service/opaque_client.dart',
  'lib/features/auth/service/session_store.dart',
  'lib/features/auth/service/vault_key_cipher.dart',
  'lib/features/auth/viewmodels/sync_view_model.dart',
  'lib/features/auth/viewmodels/vault_recovery_view_model.dart',
  'lib/features/auth/views/sync_page.dart',
  'lib/features/auth/views/vault_recovery_page.dart',
  'lib/features/autofill/data/autofill_matcher.dart',
  'lib/features/autofill/service/autofill_gateway.dart',
  'lib/features/autofill/viewmodels/autofill_fill_view_model.dart',
  'lib/features/autofill/viewmodels/autofill_save_view_model.dart',
  'lib/features/autofill/viewmodels/autofill_settings_view_model.dart',
  'lib/features/autofill/views/autofill_app.dart',
  'lib/features/autofill/views/autofill_dispatcher.dart',
  'lib/features/autofill/views/autofill_fill_page.dart',
  'lib/features/autofill/views/autofill_save_page.dart',
  'lib/features/autofill/views/widgets/autofill_settings_tile.dart',
  'lib/features/debug/views/security_debug_page.dart',
  'lib/features/debug/views/vault_debug_page.dart',
  'lib/features/home/data/base32.dart',
  'lib/features/home/data/credential_draft.dart',
  'lib/features/home/data/custom_field.dart',
  'lib/features/home/data/domain_identity.dart',
  'lib/features/home/data/otpauth_parser.dart',
  'lib/features/home/data/password_strength.dart',
  'lib/features/home/data/profile_colors.dart',
  'lib/features/home/data/profile_deletion_strategy.dart',
  'lib/features/home/data/profile_draft.dart',
  'lib/features/home/data/totp_draft.dart',
  'lib/features/home/data/totp_generator.dart',
  'lib/features/home/viewmodels/add_credential_view_model.dart',
  'lib/features/home/viewmodels/add_profile_view_model.dart',
  'lib/features/home/viewmodels/add_totp_view_model.dart',
  'lib/features/home/viewmodels/credential_detail_view_model.dart',
  'lib/features/home/viewmodels/profile_detail_view_model.dart',
  'lib/features/home/viewmodels/totp_detail_view_model.dart',
  'lib/features/home/views/add_credential_page.dart',
  'lib/features/home/views/add_profile_page.dart',
  'lib/features/home/views/add_totp_page.dart',
  'lib/features/home/views/credential_detail_page.dart',
  'lib/features/home/views/home_tab.dart',
  'lib/features/home/views/profile_detail_page.dart',
  'lib/features/home/views/profiles_page.dart',
  'lib/features/home/views/scan_totp_page.dart',
  'lib/features/home/views/totp_detail_page.dart',
  'lib/features/home/views/widgets/confirm_delete_dialog.dart',
  'lib/features/home/views/widgets/credential_avatar.dart',
  'lib/features/home/views/widgets/credential_form.dart',
  'lib/features/home/views/widgets/delete_profile_dialog.dart',
  'lib/features/home/views/widgets/detail_tile.dart',
  'lib/features/home/views/widgets/discard_changes_dialog.dart',
  'lib/features/home/views/widgets/password_strength_indicator.dart',
  'lib/features/home/views/widgets/profile_avatar.dart',
  'lib/features/home/views/widgets/profile_form.dart',
  'lib/features/home/views/widgets/profile_picker.dart',
  'lib/features/home/views/widgets/totp_form.dart',
  'lib/features/home/views/widgets/totp_list_tile.dart',
  'lib/features/home/views/widgets/vault_list_tile.dart',
  'lib/features/onboarding/data/onboarding_step.dart',
  'lib/features/onboarding/service/onboarding_flow_controller.dart',
  'lib/features/onboarding/service/onboarding_progress.dart',
  'lib/features/onboarding/service/onboarding_storage_service.dart',
  'lib/features/onboarding/viewmodels/onboarding_view_model.dart',
  'lib/features/onboarding/viewmodels/startup_gate_view_model.dart',
  'lib/features/onboarding/views/onboarding_page.dart',
  'lib/features/onboarding/views/startup_gate_page.dart',
  'lib/features/pairing/data/pairing_exception.dart',
  'lib/features/pairing/service/device_key_ffi.dart',
  'lib/features/pairing/service/device_key_store.dart',
  'lib/features/pairing/service/devices_service.dart',
  'lib/features/pairing/service/pairing_ffi.dart',
  'lib/features/pairing/service/pairing_service.dart',
  'lib/features/pairing/viewmodels/devices_view_model.dart',
  'lib/features/pairing/viewmodels/paired_setup_view_model.dart',
  'lib/features/pairing/viewmodels/pairing_receive_view_model.dart',
  'lib/features/pairing/viewmodels/pairing_source_view_model.dart',
  'lib/features/pairing/views/add_device_page.dart',
  'lib/features/pairing/views/devices_page.dart',
  'lib/features/pairing/views/paired_setup_page.dart',
  'lib/features/pairing/views/pairing_qr_view.dart',
  'lib/features/pairing/views/pairing_result_views.dart',
  'lib/features/pairing/views/receive_device_page.dart',
  'lib/features/settings/data/legal_documents.dart',
  'lib/features/settings/service/app_info_service.dart',
  'lib/features/settings/service/app_reset_service.dart',
  'lib/features/settings/viewmodels/change_password_view_model.dart',
  'lib/features/settings/viewmodels/settings_view_model.dart',
  'lib/features/settings/views/about_page.dart',
  'lib/features/settings/views/change_password_page.dart',
  'lib/features/settings/views/legal_page.dart',
  'lib/features/settings/views/settings_page.dart',
  'lib/features/settings/views/widgets/delete_data_dialog.dart',
  'lib/features/settings/views/widgets/settings_section.dart',
  'lib/features/sync/data/sync_exception.dart',
  'lib/features/sync/data/sync_models.dart',
  'lib/features/sync/data/sync_outcome.dart',
  'lib/features/sync/service/sync_api.dart',
  'lib/features/sync/service/sync_controller.dart',
  'lib/features/sync/service/sync_engine.dart',
  'lib/features/sync/service/sync_session_controller.dart',
  'lib/features/sync/service/sync_socket.dart',
  'lib/features/unlock/viewmodels/unlock_view_model.dart',
  'lib/features/unlock/views/unlock_page.dart',
  'lib/main.dart',
  'lib/shared/notifiers/fab_notifier.dart',
  'lib/shared/notifiers/fab_notifier_scope.dart',
  'lib/shared/notifiers/search_notifier.dart',
  'lib/shared/notifiers/search_notifier_scope.dart',
  'lib/shared/viewmodels/home_view_model.dart',
  'lib/shared/views/home/home_shell.dart',
  'lib/shared/widgets/app_snackbar.dart',
  'lib/shared/widgets/choice_card.dart',
  'lib/shared/widgets/destructive_button.dart',
  'lib/shared/widgets/gradient_elevated_button.dart',
  'lib/shared/widgets/neon_box_decoration.dart',
  'lib/shared/widgets/password_form.dart',
  'lib/shared/widgets/secondary_button.dart',
  'lib/shared/widgets/view_title.dart',
];

bool _isMeasurable(String path) =>
    path.endsWith('.dart') &&
    !path.endsWith('.g.dart') &&
    !path.contains('/src/rust/');

void main() {
  test('garde-fou couverture : les imports générés couvrent tout lib/', () {
    final onDisk =
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .map((file) => file.path.replaceAll(Platform.pathSeparator, '/'))
            .where(_isMeasurable)
            .toList()
          ..sort();
    expect(
      onDisk,
      _generated,
      reason:
          'lib/ a changé : relance `dart run tool/gen_coverage_imports.dart`',
    );
  });
}
