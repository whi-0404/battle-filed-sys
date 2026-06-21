import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../proto/battlefield.pbenum.dart';
import '../../models/radar_object.dart';
import '../../providers/radar_provider.dart';
import '../../theme/app_theme.dart';
import '../object_detail/object_detail_page.dart';

class ObjectListPanel extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(RadarObjectModel) onObjectTap;

  const ObjectListPanel({
    super.key,
    required this.onClose,
    required this.onObjectTap,
  });

  @override
  State<ObjectListPanel> createState() => _ObjectListPanelState();
}

class _ObjectListPanelState extends State<ObjectListPanel> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  final List<_FilterOption> _filters = [
    _FilterOption('ALL', Icons.apps, AppTheme.accentBlue),
    _FilterOption('CIVIL', Icons.flight, AppTheme.accentBlue),
    _FilterOption('UAV', Icons.airplanemode_active, AppTheme.accentGreen),
    _FilterOption('MISSILE', Icons.rocket_launch, AppTheme.accentRed),
    _FilterOption('THREAT', Icons.warning_amber_rounded, AppTheme.accentOrange),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgPanel,
          border: const Border(
            left: BorderSide(color: AppTheme.borderGlow, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentBlue.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // ─── Panel Header ─────────────────────────────────
            _buildHeader(),
            // ─── Search ───────────────────────────────────────
            _buildSearch(),
            // ─── Filter tabs ──────────────────────────────────
            _buildFilterRow(),
            const Divider(color: AppTheme.border, height: 1),
            // ─── Object list ──────────────────────────────────
            Expanded(child: _buildList()),
            // ─── Footer stats ─────────────────────────────────
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16, right: 8, bottom: 12,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.list_alt, color: AppTheme.accentBlue, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('OBJECT REGISTRY',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
            onPressed: widget.onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        onChanged: (v) => setState(() => _search = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search ID or callsign...',
          hintStyle: const TextStyle(color: AppTheme.textDim, fontSize: 12),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textDim, size: 16),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textDim, size: 14),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.accentBlue),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Consumer<RadarProvider>(
      builder: (_, provider, __) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((f) {
              final active = provider.activeFilter == f.key;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => provider.setFilter(f.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: active ? f.color.withOpacity(0.2) : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? f.color : AppTheme.border,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(f.icon, size: 12, color: active ? f.color : AppTheme.textDim),
                        const SizedBox(width: 4),
                        Text(f.key,
                          style: TextStyle(
                            color: active ? f.color : AppTheme.textDim,
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Consumer<RadarProvider>(
      builder: (_, provider, __) {
        final all = provider.objects;
        final filtered = _search.isEmpty
            ? all
            : all.where((o) =>
                o.id.toLowerCase().contains(_search) ||
                o.callsign.toLowerCase().contains(_search)).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radar, color: AppTheme.textDim, size: 40),
                const SizedBox(height: 12),
                Text(
                  provider.connected ? 'No objects found' : 'Connecting...',
                  style: const TextStyle(color: AppTheme.textDim, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _ObjectCard(
            object: filtered[i],
            onTap: () {
              widget.onObjectTap(filtered[i]);
            },
          ).animate().fadeIn(duration: 200.ms, delay: (i * 20).ms),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Consumer<RadarProvider>(
      builder: (_, provider, __) {
        final ts = provider.lastUpdate;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.border)),
            color: AppTheme.bgDeep,
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 11, color: AppTheme.textDim),
              const SizedBox(width: 4),
              Text(
                ts != null
                    ? 'Updated ${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}:${ts.second.toString().padLeft(2,'0')}'
                    : 'Waiting for data...',
                style: const TextStyle(color: AppTheme.textDim, fontSize: 10),
              ),
              const Spacer(),
              Text('${provider.objects.length} shown',
                style: const TextStyle(color: AppTheme.textDim, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Object Card ──────────────────────────────────────────────────

class _ObjectCard extends StatelessWidget {
  final RadarObjectModel object;
  final VoidCallback onTap;

  const _ObjectCard({required this.object, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.objectColor(object);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withOpacity(0.08),
        highlightColor: color.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
          ),
          child: Row(
            children: [
              // Type icon
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color.withOpacity(0.4), width: 1),
                ),
                child: Icon(AppTheme.objectIcon(object), color: color, size: 16),
              ),
              const SizedBox(width: 10),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(object.displayName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (object.isMilitary && object.threatLevel != ThreatLevel.THREAT_LEVEL_UNSPECIFIED)
                          _ThreatChip(level: object.threatLevel),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(object.typeLabel,
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        const Text(' · ', style: TextStyle(color: AppTheme.textDim, fontSize: 10)),
                        Text(
                          '${object.lat.toStringAsFixed(2)}°N ${object.lon.toStringAsFixed(2)}°E',
                          style: const TextStyle(color: AppTheme.textDim, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _InfoChip(Icons.speed, '${object.speed.toStringAsFixed(0)} kts'),
                        const SizedBox(width: 6),
                        _InfoChip(Icons.height, '${(object.alt / 1000).toStringAsFixed(1)} km'),
                        const SizedBox(width: 6),
                        _InfoChip(Icons.navigation, '${object.heading.toStringAsFixed(0)}°'),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textDim, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreatChip extends StatelessWidget {
  final ThreatLevel level;
  const _ThreatChip({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.threatColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(level.name,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: AppTheme.textDim),
        const SizedBox(width: 2),
        Text(text, style: const TextStyle(color: AppTheme.textDim, fontSize: 9)),
      ],
    );
  }
}

class _FilterOption {
  final String key;
  final IconData icon;
  final Color color;
  const _FilterOption(this.key, this.icon, this.color);
}
