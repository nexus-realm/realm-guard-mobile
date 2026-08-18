import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../service/devices_service.dart';
import '../viewmodels/devices_view_model.dart';

/// Écran **Réglages › Appareils** : liste des appareils inscrits au compte, avec
/// renommage et révocation. « Cet appareil » est identifié et sa révocation demande
/// une confirmation explicite (elle coupe l'accès de l'appareil en cours d'usage).
class DevicesPage extends StatefulWidget {
  const DevicesPage({required this.devicesService, super.key});

  final DevicesApi devicesService;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  late final DevicesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DevicesViewModel(service: widget.devicesService);
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _rename(PairedDevice device) async {
    final controller = TextEditingController(text: device.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Renommer l'appareil"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    await _viewModel.rename(device.id, name);
  }

  Future<void> _revoke(PairedDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Révoquer l'appareil ?"),
        content: Text(
          device.isCurrent
              ? "« ${device.name} » est l'appareil que vous utilisez. Le révoquer "
                    'coupera sa synchronisation : votre coffre reste accessible '
                    'localement, mais cet appareil ne pourra plus se reconnecter au '
                    'compte.'
              : '« ${device.name} » ne pourra plus se synchroniser avec ce compte. '
                    'Son coffre local, lui, reste déchiffrable sur cet appareil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _viewModel.revoke(device.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appareils')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            if (_viewModel.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: _viewModel.load,
              child: _content(context),
            );
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final error = _viewModel.error;
    final devices = _viewModel.devices;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (devices.isEmpty && error == null)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Text(
              'Aucun appareil inscrit. Liez un appareil depuis « Ajouter un '
              'appareil ».',
              textAlign: TextAlign.center,
            ),
          ),
        for (final device in devices) _deviceTile(context, device),
      ],
    );
  }

  Widget _deviceTile(BuildContext context, PairedDevice device) {
    final added = device.createdAt.toLocal();
    final date =
        '${added.day.toString().padLeft(2, '0')}/'
        '${added.month.toString().padLeft(2, '0')}/${added.year}';
    return ListTile(
      leading: Icon(device.revoked ? Icons.phonelink_erase : Icons.devices),
      title: Row(
        children: [
          Flexible(child: Text(device.name, overflow: TextOverflow.ellipsis)),
          if (device.isCurrent) ...[
            const SizedBox(width: 8),
            const _Badge(label: 'Cet appareil'),
          ],
          if (device.revoked) ...[
            const SizedBox(width: 8),
            const _Badge(label: 'Révoqué', destructive: true),
          ],
        ],
      ),
      subtitle: Text('Ajouté le $date'),
      trailing: device.revoked
          ? null
          : PopupMenuButton<String>(
              enabled: !_viewModel.busy,
              onSelected: (value) =>
                  value == 'rename' ? _rename(device) : _revoke(device),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'rename', child: Text('Renommer')),
                PopupMenuItem(value: 'revoke', child: Text('Révoquer')),
              ],
            ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.destructive = false});

  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? AppColors.destructive
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}
