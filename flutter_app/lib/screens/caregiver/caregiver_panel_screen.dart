import 'package:flutter/material.dart';
import 'package:nebula/screens/settings/learning_content_personalization_screen.dart';

import '../../controllers/app_controller.dart';
import '../../core/data/skill_catalog.dart';
import '../../models/admin_dashboard_models.dart';
import '../../models/app_admin_config.dart';
import '../../models/nebula_user.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/nebula_button.dart';
import '../../widgets/nebula_snack.dart';
import 'admin_game_content_screen.dart';
import 'caregiver_settings_screen.dart';
import '../child_profile_setup_screen.dart';
import '../portal_entry_screen.dart';
import '../welcome_screen.dart';
import 'report_pdf_preview_screen.dart';

String _roleLabel(String role) {
  switch (role.trim().toLowerCase()) {
    case UserRole.admin:
      return 'Admin';
    case UserRole.caregiver:
      return 'Cuidador';
    default:
      return role.trim().isEmpty ? 'Sin rol' : role.trim();
  }
}

String _shortMonthEs(int month) {
  const names = <String>[
    '',
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  if (month < 1 || month > 12) return 'mes';
  return names[month];
}

String _dayLabel(DateTime day) {
  final dayNumber = day.day.toString().padLeft(2, '0');
  return '$dayNumber-${_shortMonthEs(day.month)}';
}

int _effectiveDurationSeconds(GameSessionRecord session) {
  final stored = session.durationSeconds.clamp(0, 24 * 3600);
  if (stored > 0) return stored;
  if (session.endedAtMillis <= session.startedAtMillis) return 0;
  return ((session.endedAtMillis - session.startedAtMillis) ~/ 1000)
      .clamp(0, 24 * 3600);
}

String _durationLabel(GameSessionRecord session) {
  final seconds = _effectiveDurationSeconds(session);
  if (seconds <= 0) return '0 min';
  final minutes = (seconds / 60).ceil();
  return '$minutes min';
}

int _hourlyChartScaleMax(Map<int, int> hourly) {
  final rawMax = hourly.values.fold<int>(
    0,
    (max, value) => value > max ? value : max,
  );
  if (rawMax <= 0) return 30;
  final rounded = ((rawMax + 14) ~/ 15) * 15;
  return rounded < 30 ? 30 : rounded;
}

int _dailyChartScaleMax(Map<String, int> dailyMinutes) {
  final rawMax = dailyMinutes.values.fold<int>(
    0,
    (max, value) => value > max ? value : max,
  );
  if (rawMax <= 0) return 30;
  final rounded = ((rawMax + 14) ~/ 15) * 15;
  return rounded < 30 ? 30 : rounded;
}

class CaregiverPanelScreen extends StatefulWidget {
  const CaregiverPanelScreen({
    super.key,
    required this.controller,
    this.flashMessage = '',
    this.flashOk = true,
  });

  final AppController controller;
  final String flashMessage;
  final bool flashOk;

  @override
  State<CaregiverPanelScreen> createState() => _CaregiverPanelScreenState();
}

class _CaregiverPanelScreenState extends State<CaregiverPanelScreen> {
  final _dailyLimitController = TextEditingController();
  final _maintenanceMessageController = TextEditingController();
  final _minimumVersionController = TextEditingController();
  int _startHour = -1;
  int _endHour = -1;
  final Set<String> _blockedGameKeys = <String>{};
  final Set<String> _adminBlockedGameKeys = <String>{};
  final Map<String, TextEditingController> _gameLabelControllers =
      <String, TextEditingController>{};
  bool _maintenanceMode = false;
  bool _savingControl = false;
  bool _savingAdmin = false;
  bool _loadingAdminDashboard = false;
  AdminDashboardStats? _adminStats;
  List<DeletedAccountRecord> _deletedAccounts = const [];

  @override
  void initState() {
    super.initState();
    _applyParentalControl(widget.controller.parentalControl);
    _applyAdminConfig(widget.controller.appAdminConfig);
    if (widget.controller.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAdminDashboard();
      });
    }
    final flash = widget.flashMessage.trim();
    if (flash.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        NebulaSnack.show(context, message: flash, ok: widget.flashOk);
      });
    }
  }

  @override
  void dispose() {
    _dailyLimitController.dispose();
    _maintenanceMessageController.dispose();
    _minimumVersionController.dispose();
    for (final controller in _gameLabelControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _applyAdminConfig(AppAdminConfig config) {
    _maintenanceMode = config.maintenanceMode;
    _maintenanceMessageController.text = config.maintenanceMessage;
    _minimumVersionController.text = config.minimumVersion;
    _adminBlockedGameKeys
      ..clear()
      ..addAll(config.blockedGameKeys);
    for (final entry in gameLabelByKey.entries) {
      final value = widget.controller.gameLabelForKey(entry.key);
      final field = _gameLabelControllers.putIfAbsent(
        entry.key,
        () => TextEditingController(),
      );
      field.text = value;
    }
  }

  Future<void> _openChildProfileEditor({String childId = ''}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChildProfileSetupScreen(
          controller: widget.controller,
          childId: childId,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _changeChildContext(String childId) async {
    final result = await widget.controller.setCaregiverChildContext(childId);
    if (!mounted) return;
    if (!result.ok) {
      await NebulaSnack.show(context, message: result.message, ok: false);
      return;
    }
    setState(() {
      _applyParentalControl(widget.controller.parentalControl);
    });
  }

  Future<void> _confirmDeleteChildProfile(ChildProfile child) async {
    final childName = child.name.trim().isEmpty ? 'este perfil' : child.name;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar perfil de niño'),
            content: Text(
              'Vas a eliminar $childName. Esta acción es irreversible y también borrará su progreso, sesiones y logros asociados.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB3261E),
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final result = await widget.controller.deleteChildProfile(child.id);
    if (!mounted) return;
    setState(() {});
    await NebulaSnack.show(context, message: result.message, ok: result.ok);
  }

  Future<void> _saveParentalControl() async {
    if (_savingControl) return;
    setState(() => _savingControl = true);
    final limit = int.tryParse(_dailyLimitController.text.trim()) ?? 0;
    final next = ParentalControl(
      dailyLimitMinutes: limit,
      allowedStartHour: _startHour,
      allowedEndHour: _endHour,
      blockedGameKeys: _blockedGameKeys.toList(),
    );
    final result = await widget.controller.updateParentalControl(next);
    if (!mounted) return;
    setState(() => _savingControl = false);
    await NebulaSnack.show(context, message: result.message, ok: result.ok);
  }

  void _applyParentalControl(ParentalControl control) {
    _dailyLimitController.text = control.dailyLimitMinutes > 0
        ? control.dailyLimitMinutes.toString()
        : '';
    _startHour = control.allowedStartHour;
    _endHour = control.allowedEndHour;
    _blockedGameKeys
      ..clear()
      ..addAll(control.blockedGameKeys);
  }

  Future<void> _saveAdminConfig() async {
    if (_savingAdmin) return;
    setState(() => _savingAdmin = true);
    final labels = <String, String>{};
    for (final entry in _gameLabelControllers.entries) {
      final value = entry.value.text.trim();
      if (value.isEmpty) continue;
      labels[entry.key] = value;
    }
    final next = AppAdminConfig(
      maintenanceMode: _maintenanceMode,
      maintenanceMessage: _maintenanceMessageController.text,
      minimumVersion: _minimumVersionController.text,
      blockedGameKeys: _adminBlockedGameKeys.toList(),
      gameLabels: labels,
      updatedAtMillis: widget.controller.appAdminConfig.updatedAtMillis,
    );
    final result = await widget.controller.saveAppAdminConfig(next);
    if (!mounted) return;
    setState(() => _savingAdmin = false);
    await NebulaSnack.show(context, message: result.message, ok: result.ok);
  }

  Future<void> _reloadAdminConfig() async {
    final result = await widget.controller.reloadAppAdminConfig(notify: false);
    if (!mounted) return;
    if (result.ok) {
      setState(() {
        _applyAdminConfig(widget.controller.appAdminConfig);
      });
      await _loadAdminDashboard(showSnack: false);
      if (!mounted) return;
    }
    await NebulaSnack.show(context, message: result.message, ok: result.ok);
  }

  Future<void> _loadAdminDashboard({bool showSnack = false}) async {
    if (_loadingAdminDashboard || !widget.controller.isAdmin) return;
    setState(() => _loadingAdminDashboard = true);
    final result = await widget.controller.reloadAdminDashboard(notify: false);
    if (!mounted) return;
    setState(() {
      _adminStats = widget.controller.adminDashboardStats;
      _deletedAccounts = widget.controller.deletedAccounts;
      _loadingAdminDashboard = false;
    });
    if (showSnack) {
      await NebulaSnack.show(context, message: result.message, ok: result.ok);
    }
  }

  Future<void> _logout() async {
    await widget.controller.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => WelcomeScreen(
          controller: widget.controller,
          flashMessage: 'Sesión cerrada correctamente.',
          flashOk: true,
        ),
      ),
      (_) => false,
    );
  }

  void _backToPortalSelector() {
    if (widget.controller.isAdmin) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    widget.controller.markPortalSelectionPending();
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => PortalEntryScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.controller.isAdmin;
    final tabs = isAdmin
        ? const <Tab>[
            Tab(text: 'Admin'),
            Tab(text: 'Cuenta'),
          ]
        : const <Tab>[
            Tab(text: 'Resumen'),
            Tab(text: 'Reportes'),
            Tab(text: 'Habilidades'),
            Tab(text: 'Control'),
            Tab(text: 'Cuenta'),
          ];
    final views = isAdmin
        ? <Widget>[
            _AdminTab(
              controller: widget.controller,
              dashboardStats: _adminStats,
              deletedAccounts: _deletedAccounts,
              loadingDashboard: _loadingAdminDashboard,
              maintenanceMode: _maintenanceMode,
              maintenanceMessageController: _maintenanceMessageController,
              minimumVersionController: _minimumVersionController,
              blockedGameKeys: _adminBlockedGameKeys,
              gameLabelControllers: _gameLabelControllers,
              saving: _savingAdmin,
              onMaintenanceChanged: (value) =>
                  setState(() => _maintenanceMode = value),
              onBlockedChanged: (gameKey, blocked) {
                setState(() {
                  if (blocked) {
                    _adminBlockedGameKeys.add(gameKey);
                  } else {
                    _adminBlockedGameKeys.remove(gameKey);
                  }
                });
              },
              onSave: _saveAdminConfig,
              onReload: _reloadAdminConfig,
              onRefreshDashboard: () => _loadAdminDashboard(showSnack: true),
              onOpenGameContentEditor: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        AdminGameContentScreen(controller: widget.controller),
                  ),
                );
              },
            ),
            _AdminAccountTab(
              controller: widget.controller,
              onLogout: _logout,
            ),
          ]
        : <Widget>[
            _SummaryTab(
              controller: widget.controller,
              onCreateChildProfile: () => _openChildProfileEditor(),
              onEditChildProfile: (childId) =>
                  _openChildProfileEditor(childId: childId),
              onDeleteChildProfile: (child) => _confirmDeleteChildProfile(child),
              onChildContextChanged: _changeChildContext,
            ),
            _ReportsTab(
              controller: widget.controller,
              onChildContextChanged: _changeChildContext,
            ),
            _SkillsTab(
              controller: widget.controller,
              onChildContextChanged: _changeChildContext,
            ),
            _ControlTab(
              controller: widget.controller,
              dailyLimitController: _dailyLimitController,
              startHour: _startHour,
              endHour: _endHour,
              blockedGameKeys: _blockedGameKeys,
              savingControl: _savingControl,
              onChildContextChanged: _changeChildContext,
              onStartHourChanged: (value) => setState(() => _startHour = value),
              onEndHourChanged: (value) => setState(() => _endHour = value),
              onBlockedChanged: (gameKey, blocked) {
                setState(() {
                  if (blocked) {
                    _blockedGameKeys.add(gameKey);
                  } else {
                    _blockedGameKeys.remove(gameKey);
                  }
                });
              },
              onSave: _saveParentalControl,
            ),
            _AccountTab(
              controller: widget.controller,
              onLogout: _logout,
            ),
          ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          leading: isAdmin
              ? (Navigator.of(context).canPop()
                  ? BackButton(onPressed: () => Navigator.of(context).pop())
                  : null)
              : BackButton(onPressed: _backToPortalSelector),
          title: Text(isAdmin ? 'Zona administrador' : 'Zona cuidador'),
          bottom: TabBar(
            isScrollable: true,
            tabs: tabs,
          ),
        ),
        body: CosmicBackground(
          child: TabBarView(children: views),
        ),
      ),
    );
  }
}

class _ChildContextCard extends StatelessWidget {
  const _ChildContextCard({
    required this.controller,
    required this.onChildChanged,
    this.note = '',
  });

  final AppController controller;
  final Future<void> Function(String childId) onChildChanged;
  final String note;

  @override
  Widget build(BuildContext context) {
    final children = controller.childProfiles;
    if (children.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'No hay perfiles de niño para seleccionar.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    var selectedId = controller.childProfile?.id.trim() ?? '';
    if (selectedId.isEmpty || !children.any((item) => item.id == selectedId)) {
      selectedId = children.first.id;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perfil en vista',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            if (children.length == 1)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.child_care_rounded),
                title: Text(
                  children.first.name.trim().isEmpty
                      ? 'Niño sin nombre'
                      : children.first.name,
                ),
                subtitle: const Text('Perfil unico disponible'),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: selectedId,
                decoration: const InputDecoration(
                  labelText: 'Selecciona un niño',
                ),
                items: children
                    .map(
                      (child) => DropdownMenuItem<String>(
                        value: child.id,
                        child: Text(
                          child.name.trim().isEmpty
                              ? 'Niño sin nombre'
                              : child.name,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  onChildChanged(value);
                },
              ),
            if (note.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                note,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4F628A),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.controller,
    required this.onCreateChildProfile,
    required this.onEditChildProfile,
    required this.onDeleteChildProfile,
    required this.onChildContextChanged,
  });

  final AppController controller;
  final Future<void> Function() onCreateChildProfile;
  final Future<void> Function(String childId) onEditChildProfile;
  final Future<void> Function(ChildProfile child) onDeleteChildProfile;
  final Future<void> Function(String childId) onChildContextChanged;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    if (user == null) return const SizedBox.shrink();
    final childProfiles = controller.childProfiles;
    final todayMinutes = controller.usedMinutesOn(DateTime.now());
    final thisWeekSessions = controller.sessionsForLastDays(7).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ChildContextCard(
          controller: controller,
          onChildChanged: onChildContextChanged,
          note:
              'Este perfil se usa como contexto activo para personalización y seguimiento.',
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuenta cuidador',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text('Nombre: ${user.name}'),
                Text('Correo: ${user.email}'),
                Text('Rol: ${_roleLabel(user.role)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfiles de niños',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                if (childProfiles.isEmpty)
                  const Text('Aún no hay perfiles de niño.')
                else
                  ...childProfiles.map((child) {
                    final isActive = controller.childProfile?.id == child.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.child_care_rounded),
                      title: Text(
                        child.name.trim().isEmpty
                            ? 'Niño sin nombre'
                            : child.name,
                      ),
                      subtitle: Text(
                        child.birthDateMillis > 0
                            ? 'Nacimiento: ${_formatDate(child.birthDateMillis)}'
                            : 'Nacimiento no definido',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isActive)
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF1B8B3B)),
                          IconButton(
                            onPressed: () => onEditChildProfile(child.id),
                            icon: const Icon(Icons.edit_rounded),
                            tooltip: 'Editar',
                          ),
                          IconButton(
                            onPressed: () => onDeleteChildProfile(child),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFB3261E),
                            ),
                            tooltip: 'Eliminar',
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 10),
                NebulaSecondaryButton(
                  text: 'Agregar otro perfil de niño',
                  onPressed: onCreateChildProfile,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen rápido',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text('Uso de hoy: $todayMinutes minutos'),
                Text('Sesiones últimos 7 días: $thisWeekSessions'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        NebulaPrimaryButton(
          text: 'Personalizacion de contenido',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PersonalizationScreen(controller: controller),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab({
    required this.controller,
    required this.onChildContextChanged,
  });

  final AppController controller;
  final Future<void> Function(String childId) onChildContextChanged;

  @override
  Widget build(BuildContext context) {
    final activeChildId = controller.childProfile?.id.trim() ?? '';
    final sessions = controller.sessionsForLastDays(30, childId: activeChildId);
    final dayData = _dailyMinutes(controller, childId: activeChildId);
    final dailyScaleMax = _dailyChartScaleMax(dayData);
    final hourly =
        controller.usageMinutesByHour(days: 14, childId: activeChildId);
    final hourlyScaleMax = _hourlyChartScaleMax(hourly);
    final skillData = _skillScores(sessions);
    final pdfData = _buildPdfData(
      controller: controller,
      sessions: sessions,
      dayData: dayData,
      hourly: hourly,
      skillData: skillData,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ChildContextCard(
          controller: controller,
          onChildChanged: onChildContextChanged,
          note:
              'Las métricas de esta vista se calculan para el niño seleccionado.',
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datos de ejemplo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.isAdmin
                      ? 'Carga/actualiza un perfil demo con sesiones simuladas para todas las cuentas de cuidador.'
                      : 'Crea un perfil demo con sesiones simuladas para previsualizar reportes.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = controller.isAdmin
                          ? await controller.seedDemoChildForReportsForAllUsers()
                          : await controller.seedDemoChildForReports();
                      if (result.ok && !controller.isAdmin) {
                        final demoChildId = controller.activeChildProfileId;
                        if (demoChildId.trim().isNotEmpty) {
                          await onChildContextChanged(demoChildId);
                        }
                      }
                      if (!context.mounted) return;
                      await NebulaSnack.show(
                        context,
                        message: result.message,
                        ok: result.ok,
                      );
                    },
                    icon: const Icon(Icons.science_outlined),
                    label: Text(
                      controller.isAdmin
                          ? 'Cargar demo en todos los usuarios'
                          : 'Cargar perfil demo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exportar reporte',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportPdfPreviewScreen(data: pdfData),
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Vista previa y exportación PDF'),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Desde la vista previa puedes guardar o compartir el PDF.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uso por día (últimos 7 días)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ...dayData.entries.map((entry) {
                  final value = entry.value;
                  final ratio = (value / dailyScaleMax).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 84, child: Text(entry.key)),
                        Expanded(
                          child: LinearProgressIndicator(value: ratio),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(width: 42, child: Text('${value}m')),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Text(
                  'Escala máxima: $dailyScaleMax min.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uso por hora (últimos 14 días)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 190,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 38,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${hourlyScaleMax}m'),
                            Text('${(hourlyScaleMax / 2).round()}m'),
                            const Text('0m'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  3,
                                  (_) => Container(
                                    height: 1,
                                    color:
                                        Colors.blueGrey.withValues(alpha: 0.18),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(24, (hour) {
                                final minutes = hourly[hour] ?? 0;
                                final ratio =
                                    (minutes / hourlyScaleMax).clamp(0.0, 1.0);
                                final height =
                                    ratio <= 0 ? 0.0 : 8 + (ratio * 148);
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        height: height,
                                        color: Colors.blue.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                    '0h                                12h                                23h'),
                const SizedBox(height: 4),
                Text(
                  'Cada barra representa minutos acumulados en sesiones iniciadas en esa hora durante los últimos 14 días. Escala máxima: $hourlyScaleMax min.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desempeño por habilidad (vista terapeuta)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Puntaje estimado con base en precisión, ritmo de respuesta y dificultad jugada. La evidencia indica cuántas sesiones respaldan el cálculo.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (skillData.isEmpty)
                  const Text('Aún no hay suficientes datos de sesiones.')
                else
                  ...skillData.entries.map((entry) {
                    final score = entry.value.$1;
                    final evidence = entry.value.$2;
                    final skill = skillById(entry.key);
                    final title = skill?.title ?? entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$title  (${score.toStringAsFixed(0)}/100)'),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                              value: (score / 100).clamp(0, 1)),
                          const SizedBox(height: 2),
                          Text('Evidencia: $evidence sesiones'),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesiones recientes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                if (sessions.isEmpty)
                  const Text('Sin sesiones registradas.')
                else
                  ...sessions.reversed.take(12).map((session) {
                    final started = DateTime.fromMillisecondsSinceEpoch(
                      session.startedAtMillis,
                    );
                    final label = controller.gameLabelForKey(session.gameKey);
                    final dateLabel = _dayLabel(started);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '$dateLabel ${started.hour.toString().padLeft(2, '0')}:${started.minute.toString().padLeft(2, '0')}  |  $label  |  ${_durationLabel(session)}',
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, int> _dailyMinutes(
    AppController controller, {
    String childId = '',
  }) {
    final now = DateTime.now();
    final result = <String, int>{};
    for (var i = 6; i >= 0; i--) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final key = _dayLabel(day);
      result[key] = controller.usedMinutesOn(day, childId: childId);
    }
    return result;
  }

  ChildReportPdfData _buildPdfData({
    required AppController controller,
    required List<GameSessionRecord> sessions,
    required Map<String, int> dayData,
    required Map<int, int> hourly,
    required Map<String, (double, int)> skillData,
  }) {
    final childName = controller.childProfile?.name.trim() ?? '';
    final caregiverName = controller.currentUser?.name.trim() ?? '';
    final activeChildId = controller.childProfile?.id.trim() ?? '';
    const periodDays = 30;
    const dailyWindowDays = 7;
    const hourlyWindowDays = 14;

    final currentFrom =
        DateTime.now().subtract(const Duration(days: periodDays));
    final previousFrom =
        DateTime.now().subtract(const Duration(days: periodDays * 2));
    final trailingSessions =
        controller.sessionsForLastDays(periodDays * 2, childId: activeChildId);
    final previousSessions = trailingSessions.where((session) {
      final started =
          DateTime.fromMillisecondsSinceEpoch(session.startedAtMillis);
      final inPreviousWindow = (started.isAfter(previousFrom) ||
              started.isAtSameMomentAs(previousFrom)) &&
          started.isBefore(currentFrom);
      return inPreviousWindow;
    }).toList();

    final previousSkillData = _skillScores(previousSessions);
    final errorRateBySkill = _errorRateBySkill(sessions);
    final allSkillIds = <String>{...skillData.keys};

    final skillRows = allSkillIds.map((skillId) {
      final skill = skillById(skillId);
      final current = skillData[skillId];
      final previous = previousSkillData[skillId];
      return ReportSkillMetric(
        id: skillId,
        title: skill?.title ?? skillId,
        score: current?.$1 ?? 0.0,
        previousScore: previous?.$1 ?? -1.0,
        evidenceSessions: current?.$2 ?? 0,
        errorRatePercent: errorRateBySkill[skillId] ?? 0.0,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final sortedSessions = List<GameSessionRecord>.from(sessions)
      ..sort((a, b) => b.startedAtMillis.compareTo(a.startedAtMillis));
    final sessionRows = sortedSessions.map((session) {
      final durationSeconds = _effectiveDurationSeconds(session);
      return ReportSessionEntry(
        gameLabel: controller.gameLabelForKey(session.gameKey),
        startedAtMillis: session.startedAtMillis,
        durationMinutes:
            durationSeconds <= 0 ? 0 : (durationSeconds / 60).ceil(),
        correctAnswers: session.correctAnswers,
        totalAttempts: session.totalAttempts,
        mistakes: session.mistakes,
      );
    }).toList();

    return ChildReportPdfData(
      caregiverName: caregiverName.isEmpty ? 'Cuidador' : caregiverName,
      childName: childName.isEmpty ? 'Niño' : childName,
      generatedAtMillis: DateTime.now().millisecondsSinceEpoch,
      periodDays: periodDays,
      dailyWindowDays: dailyWindowDays,
      hourlyWindowDays: hourlyWindowDays,
      dailyMinutes: dayData,
      hourlyMinutes: hourly,
      skills: skillRows,
      sessions: sessionRows,
    );
  }

  Map<String, (double, int)> _skillScores(List<GameSessionRecord> sessions) {
    final bySkill = <String, List<GameSessionRecord>>{};
    for (final session in sessions) {
      final skillIds = gameToSkillIds[session.gameKey] ?? const <String>[];
      for (final skillId in skillIds) {
        bySkill.putIfAbsent(skillId, () => <GameSessionRecord>[]).add(session);
      }
    }

    final result = <String, (double, int)>{};
    bySkill.forEach((skillId, entries) {
      if (entries.isEmpty) return;
      var totalScore = 0.0;
      for (final item in entries) {
        final attempts = _sessionAttempts(item);
        final correctAnswers = _sessionCorrectAnswers(item, attempts);
        final accuracy =
            attempts <= 0 ? 0.0 : (correctAnswers / attempts).clamp(0.0, 1.0);
        final speedScore = _sessionSpeedScore(item, attempts);
        final difficultyBonus = switch (item.difficultyStars.clamp(1, 3)) {
          1 => 0.0,
          2 => 2.5,
          _ => 5.0,
        };
        final score =
            (accuracy * 85.0) + (speedScore * 10.0) + difficultyBonus;
        totalScore += score.clamp(0.0, 100.0);
      }
      result[skillId] = (totalScore / entries.length, entries.length);
    });
    return result;
  }

  int _sessionAttempts(GameSessionRecord session) {
    final recordedAttempts = session.totalAttempts.clamp(0, 10000);
    if (recordedAttempts > 0) return recordedAttempts;

    final inferredFromAnswers =
        (session.correctAnswers + session.mistakes).clamp(0, 10000);
    if (inferredFromAnswers > 0) return inferredFromAnswers;

    return session.rounds.clamp(0, 10000);
  }

  int _sessionCorrectAnswers(GameSessionRecord session, int attempts) {
    if (attempts <= 0) return 0;

    final recordedCorrect = session.correctAnswers.clamp(0, 10000);
    if (recordedCorrect > 0 || session.totalAttempts > 0) {
      return recordedCorrect.clamp(0, attempts);
    }

    final inferred = attempts - session.mistakes.clamp(0, attempts);
    return inferred.clamp(0, attempts);
  }

  double _sessionSpeedScore(GameSessionRecord session, int attempts) {
    if (attempts <= 0) return 0.5;

    final durationSeconds = _effectiveDurationSeconds(session);
    if (durationSeconds <= 0) return 0.5;

    final secondsPerAttempt = durationSeconds / attempts;
    return ((30.0 - secondsPerAttempt) / 24.0).clamp(0.0, 1.0);
  }

  Map<String, double> _errorRateBySkill(List<GameSessionRecord> sessions) {
    final attemptsBySkill = <String, int>{};
    final mistakesBySkill = <String, int>{};

    for (final session in sessions) {
      final skillIds = gameToSkillIds[session.gameKey] ?? const <String>[];
      if (skillIds.isEmpty) continue;

      final attempts =
          (session.totalAttempts > 0 ? session.totalAttempts : session.rounds)
              .clamp(0, 10000);
      final mistakes = session.mistakes.clamp(0, 10000);

      for (final skillId in skillIds) {
        attemptsBySkill[skillId] = (attemptsBySkill[skillId] ?? 0) + attempts;
        mistakesBySkill[skillId] = (mistakesBySkill[skillId] ?? 0) + mistakes;
      }
    }

    final result = <String, double>{};
    for (final entry in attemptsBySkill.entries) {
      final skillId = entry.key;
      final attempts = entry.value;
      final mistakes = mistakesBySkill[skillId] ?? 0;
      if (attempts <= 0) {
        result[skillId] = 0;
      } else {
        result[skillId] = ((mistakes * 100.0) / attempts).clamp(0.0, 100.0);
      }
    }
    return result;
  }
}

class _SkillsTab extends StatelessWidget {
  const _SkillsTab({
    required this.controller,
    required this.onChildContextChanged,
  });

  final AppController controller;
  final Future<void> Function(String childId) onChildContextChanged;

  @override
  Widget build(BuildContext context) {
    final adminBlocked = controller.appAdminConfig.blockedGameKeys
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ChildContextCard(
          controller: controller,
          onChildChanged: onChildContextChanged,
          note:
              'La descripción de habilidades es común; el contexto activo ayuda en la lectura de reportes.',
        ),
        const SizedBox(height: 10),
        Card(
          color: const Color(0xFFEAF3FF),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.psychology_alt_rounded,
                  color: Color(0xFF1F66D8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cada habilidad incluye: qué es, un ejemplo cotidiano, cómo se evalúa y qué juego la fortalece.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...skillCatalog.map(
          (skill) {
            final relatedGames = skill.relatedGames
                .where((link) =>
                    !adminBlocked.contains(link.gameKey.trim().toLowerCase()))
                .toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      color: const Color(0xFFEEF5FF),
                      child: Text(
                        skill.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF153A78),
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Que es: ${skill.description}'),
                          const SizedBox(height: 8),
                          Text('Ejemplo cotidiano: ${skill.everydayExamples}'),
                          const SizedBox(height: 8),
                          Text('Cómo evaluamos: ${skill.evaluationNotes}'),
                          const SizedBox(height: 10),
                          Text(
                            'Juegos que la fortalecen',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          if (relatedGames.isEmpty)
                            const Text(
                              'Sin juegos disponibles por bloqueo admin.',
                            )
                          else
                            ...relatedGames.map((link) {
                              final gameLabel = gameLabelByKey[link.gameKey] ??
                                  link.gameKey.replaceAll('_', ' ');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _SkillGameTile(
                                  gameLabel: gameLabel,
                                  howItHelps: link.howItHelps,
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SkillGameTile extends StatelessWidget {
  const _SkillGameTile({
    required this.gameLabel,
    required this.howItHelps,
  });

  final String gameLabel;
  final String howItHelps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4E2FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  gameLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                avatar: const Icon(
                  Icons.extension_rounded,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(howItHelps),
        ],
      ),
    );
  }
}

class _ControlTab extends StatelessWidget {
  const _ControlTab({
    required this.controller,
    required this.dailyLimitController,
    required this.startHour,
    required this.endHour,
    required this.blockedGameKeys,
    required this.savingControl,
    required this.onChildContextChanged,
    required this.onStartHourChanged,
    required this.onEndHourChanged,
    required this.onBlockedChanged,
    required this.onSave,
  });

  final AppController controller;
  final TextEditingController dailyLimitController;
  final int startHour;
  final int endHour;
  final Set<String> blockedGameKeys;
  final bool savingControl;
  final Future<void> Function(String childId) onChildContextChanged;
  final ValueChanged<int> onStartHourChanged;
  final ValueChanged<int> onEndHourChanged;
  final void Function(String gameKey, bool blocked) onBlockedChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final hours = <int>[-1, ...List.generate(24, (i) => i)];
    final adminBlocked = controller.appAdminConfig.blockedGameKeys
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ChildContextCard(
          controller: controller,
          onChildChanged: onChildContextChanged,
          note:
              'El control parental se guarda por cada niño seleccionado y se evalúa cuando ese perfil intenta abrir juegos.',
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiempo diario',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dailyLimitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Límite diario en minutos (0 = sin límite)',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Horario permitido',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: startHour,
                        decoration: const InputDecoration(labelText: 'Desde'),
                        items: hours
                            .map(
                              (hour) => DropdownMenuItem<int>(
                                value: hour,
                                child: Text(hour < 0
                                    ? 'Sin horario'
                                    : '${hour.toString().padLeft(2, '0')}:00'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          onStartHourChanged(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: endHour,
                        decoration: const InputDecoration(labelText: 'Hasta'),
                        items: hours
                            .map(
                              (hour) => DropdownMenuItem<int>(
                                value: hour,
                                child: Text(hour < 0
                                    ? 'Sin horario'
                                    : '${hour.toString().padLeft(2, '0')}:00'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          onEndHourChanged(value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bloqueo de juegos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ...controller.effectiveGameLabels.entries
                    .where(
                      (entry) =>
                          !adminBlocked.contains(entry.key.trim().toLowerCase()),
                    )
                    .map((entry) {
                  final blocked = blockedGameKeys.contains(entry.key);
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: blocked,
                    title: Text(
                      entry.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onChanged: (value) =>
                        onBlockedChanged(entry.key, value ?? false),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        NebulaPrimaryButton(
          text: savingControl ? 'Guardando...' : 'Guardar control parental',
          onPressed: savingControl ? null : onSave,
        ),
      ],
    );
  }
}

class _AdminTab extends StatelessWidget {
  const _AdminTab({
    required this.controller,
    required this.dashboardStats,
    required this.deletedAccounts,
    required this.loadingDashboard,
    required this.maintenanceMode,
    required this.maintenanceMessageController,
    required this.minimumVersionController,
    required this.blockedGameKeys,
    required this.gameLabelControllers,
    required this.saving,
    required this.onMaintenanceChanged,
    required this.onBlockedChanged,
    required this.onSave,
    required this.onReload,
    required this.onRefreshDashboard,
    required this.onOpenGameContentEditor,
  });

  final AppController controller;
  final AdminDashboardStats? dashboardStats;
  final List<DeletedAccountRecord> deletedAccounts;
  final bool loadingDashboard;
  final bool maintenanceMode;
  final TextEditingController maintenanceMessageController;
  final TextEditingController minimumVersionController;
  final Set<String> blockedGameKeys;
  final Map<String, TextEditingController> gameLabelControllers;
  final bool saving;
  final ValueChanged<bool> onMaintenanceChanged;
  final void Function(String gameKey, bool blocked) onBlockedChanged;
  final Future<void> Function() onSave;
  final Future<void> Function() onReload;
  final Future<void> Function() onRefreshDashboard;
  final VoidCallback onOpenGameContentEditor;

  String _formatDateTime(int millis) {
    if (millis <= 0) return 'Sin fecha';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  String _formatMinutes(int minutes) {
    if (minutes <= 0) return '0 min';
    if (minutes < 60) return '$minutes min';
    final hours = minutes / 60.0;
    return '${hours.toStringAsFixed(1)} h';
  }

  String _formatSource(String source) {
    switch (source) {
      case 'cloud':
        return 'Nube';
      case 'mixed':
        return 'Mixto';
      default:
        return 'Local';
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = gameLabelByKey.keys.toList()..sort();
    final stats = dashboardStats;
    final topGames = stats == null
        ? <MapEntry<String, int>>[]
        : stats.sessionsByGame.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dashboard admin',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    TextButton(
                      onPressed: loadingDashboard ? null : onRefreshDashboard,
                      child: Text(
                        loadingDashboard ? 'Cargando...' : 'Actualizar',
                      ),
                    ),
                  ],
                ),
                if (loadingDashboard) const LinearProgressIndicator(),
                const SizedBox(height: 8),
                if (stats == null)
                  const Text('Sin datos aún. Pulsa "Actualizar".')
                else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetricChip(
                        label: 'Usuarios',
                        value: '${stats.totalUsers}',
                      ),
                      _MetricChip(
                        label: 'Cuidadores',
                        value: '${stats.caregiverUsers}',
                      ),
                      _MetricChip(
                        label: 'Admins',
                        value: '${stats.adminUsers}',
                      ),
                      _MetricChip(
                        label: 'Con perfil ni\u00f1o',
                        value: '${stats.usersWithChildProfile}',
                      ),
                      _MetricChip(
                        label: 'Ni\u00f1os activos',
                        value: '${stats.activeChildProfiles}',
                      ),
                      _MetricChip(
                        label: 'Sesiones totales',
                        value: '${stats.totalGameSessions}',
                      ),
                      _MetricChip(
                        label: 'Sesiones 7 días',
                        value: '${stats.sessionsLast7Days}',
                      ),
                      _MetricChip(
                        label: 'Uso total',
                        value: _formatMinutes(stats.totalUsageMinutes),
                      ),
                      _MetricChip(
                        label: 'Uso 7 días',
                        value: _formatMinutes(stats.usageMinutesLast7Days),
                      ),
                      _MetricChip(
                        label: 'Precisión',
                        value:
                            '${stats.averageAccuracyPercent.toStringAsFixed(1)}%',
                      ),
                      _MetricChip(
                        label: 'Eliminadas',
                        value: '${stats.deletedAccounts}',
                      ),
                      _MetricChip(
                        label: 'Eliminadas 30 días',
                        value: '${stats.deletedAccountsLast30Days}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fuente: ${_formatSource(stats.source)}  |  Actualizado: ${_formatDateTime(stats.refreshedAtMillis)}',
                  ),
                  if (topGames.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Juegos con más sesiones',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    ...topGames.take(5).map(
                          (entry) => Text(
                            '${controller.gameLabelForKey(entry.key)}: ${entry.value}',
                          ),
                        ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contenido editable de juegos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Admin puede gestionar recursos y respuestas de juegos desde un editor dedicado.',
                ),
                const SizedBox(height: 10),
                NebulaSecondaryButton(
                  text: 'Abrir editor de contenido',
                  onPressed: onOpenGameContentEditor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuentas eliminadas recientes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                if (deletedAccounts.isEmpty)
                  const Text('Sin cuentas eliminadas registradas.')
                else
                  ...deletedAccounts.take(15).map((item) {
                    final role = _roleLabel(
                        item.role.trim().isEmpty ? 'caregiver' : item.role);
                    final primary = item.email.trim().isNotEmpty
                        ? item.email
                        : item.username;
                    final title =
                        primary.trim().isNotEmpty ? primary : item.userId;
                    final reason =
                        item.reason.trim().isEmpty ? 'sin motivo' : item.reason;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_remove_alt_1_outlined),
                      title: Text(title),
                      subtitle: Text(
                        'Rol: $role | Motivo: $reason | ${_formatDateTime(item.deletedAtMillis)}',
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de la app',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: maintenanceMode,
                  onChanged: onMaintenanceChanged,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Modo mantenimiento'),
                  subtitle: const Text(
                      'Bloquea juegos para ni\u00f1os y cuidadores.'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: maintenanceMessageController,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje de mantenimiento',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minimumVersionController,
                  decoration: const InputDecoration(
                    labelText: 'Versión mínima sugerida (ej: 1.2.0)',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Habilitar o deshabilitar juegos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ...keys.map((key) {
                  final blocked = blockedGameKeys.contains(key);
                  final labelController = gameLabelControllers[key];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: blocked,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                              labelController?.text.trim().isNotEmpty == true
                                  ? labelController!.text
                                  : (gameLabelByKey[key] ?? key),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          subtitle: Text(key),
                          onChanged: (value) =>
                              onBlockedChanged(key, value ?? false),
                        ),
                        TextField(
                          controller: labelController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre visible del juego',
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: NebulaSecondaryButton(
                text: 'Recargar config',
                onPressed: saving ? null : onReload,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NebulaPrimaryButton(
                text: saving ? 'Guardando...' : 'Guardar cambios admin',
                onPressed: saving ? null : onSave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white, accent, 0.14),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AccountTab extends StatelessWidget {
  const _AccountTab({
    required this.controller,
    required this.onLogout,
  });

  final AppController controller;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    if (user == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user.name),
            subtitle: Text(user.email),
          ),
        ),
        const SizedBox(height: 10),
        NebulaSecondaryButton(
          text: 'Configuración del cuidador',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CaregiverSettingsScreen(controller: controller),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onLogout,
          child: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}

class _AdminAccountTab extends StatelessWidget {
  const _AdminAccountTab({
    required this.controller,
    required this.onLogout,
  });

  final AppController controller;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    if (user == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: Text(user.name),
            subtitle: Text(
              '${user.email}\nRol: ${_roleLabel(user.role)}',
            ),
            isThreeLine: true,
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onLogout,
          child: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
