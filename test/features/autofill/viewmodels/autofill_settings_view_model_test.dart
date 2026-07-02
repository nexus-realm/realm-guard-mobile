import 'package:flutter_autofill_service/flutter_autofill_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/features/autofill/service/autofill_gateway.dart';
import 'package:realm_guard_mobile/features/autofill/viewmodels/autofill_settings_view_model.dart';

class FakeAutofillGateway implements AutofillGateway {
  FakeAutofillGateway(this.statusValue);

  AutofillServiceStatus statusValue;
  int enableCount = 0;
  int disableCount = 0;

  @override
  Future<AutofillServiceStatus> status() async => statusValue;

  @override
  Future<void> requestEnable() async {
    enableCount++;
    statusValue = AutofillServiceStatus.enabled;
  }

  @override
  Future<void> disable() async {
    disableCount++;
    statusValue = AutofillServiceStatus.disabled;
  }

  // Opérations de remplissage / sauvegarde non utilisées par le réglage : stubs.
  int configureCount = 0;

  @override
  Future<bool> isInteractiveFillRequest() async => false;

  @override
  Future<AutofillMetadata?> fillMetadata() async => null;

  @override
  Future<void> submit(PwDataset dataset) async {}

  @override
  Future<void> onSaveComplete() async {}

  @override
  Future<void> configureAutofill() async {
    configureCount++;
  }
}

void main() {
  group('AutofillSettingsViewModel', () {
    test('refresh charge le statut', () async {
      final vm = AutofillSettingsViewModel(
        gateway: FakeAutofillGateway(AutofillServiceStatus.disabled),
      );

      await vm.refresh();

      expect(vm.status, AutofillServiceStatus.disabled);
      expect(vm.isSupported, isTrue);
      expect(vm.isEnabled, isFalse);
    });

    test('unsupported => non supporté, non activé', () async {
      final vm = AutofillSettingsViewModel(
        gateway: FakeAutofillGateway(AutofillServiceStatus.unsupported),
      );

      await vm.refresh();

      expect(vm.isSupported, isFalse);
      expect(vm.isEnabled, isFalse);
    });

    test('enable délègue puis rafraîchit le statut', () async {
      final gateway = FakeAutofillGateway(AutofillServiceStatus.disabled);
      final vm = AutofillSettingsViewModel(gateway: gateway);

      await vm.enable();

      expect(gateway.enableCount, 1);
      expect(vm.isEnabled, isTrue);
      expect(vm.isBusy, isFalse);
    });

    test('disable délègue puis rafraîchit le statut', () async {
      final gateway = FakeAutofillGateway(AutofillServiceStatus.enabled);
      final vm = AutofillSettingsViewModel(gateway: gateway);

      await vm.disable();

      expect(gateway.disableCount, 1);
      expect(vm.isEnabled, isFalse);
      expect(vm.isBusy, isFalse);
    });

    test('refresh active l\'autofill quand le service est supporté', () async {
      final gateway = FakeAutofillGateway(AutofillServiceStatus.disabled);
      final vm = AutofillSettingsViewModel(gateway: gateway);

      await vm.refresh();

      expect(gateway.configureCount, greaterThan(0));
    });

    test('refresh n\'active pas l\'autofill si non supporté', () async {
      final gateway = FakeAutofillGateway(AutofillServiceStatus.unsupported);
      final vm = AutofillSettingsViewModel(gateway: gateway);

      await vm.refresh();

      expect(gateway.configureCount, 0);
    });
  });
}
