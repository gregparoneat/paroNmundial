import 'package:fantacy11/api/repositories/league_repository.dart';
import 'package:fantacy11/api/sportmonks_config.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Page for creating a new fantasy league
class CreateLeaguePage extends StatefulWidget {
  const CreateLeaguePage({super.key});

  @override
  State<CreateLeaguePage> createState() => _CreateLeaguePageState();
}

class _CreateLeaguePageState extends State<CreateLeaguePage> {
  final LeagueRepository _repository = LeagueRepository();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxMembersController = TextEditingController(text: '10');
  final _budgetController = TextEditingController(text: '150');
  final _rosterSizeController = TextEditingController(text: '18');
  
  LeagueType _leagueType = LeagueType.public;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxMembersController.dispose();
    _budgetController.dispose();
    _rosterSizeController.dispose();
    super.dispose();
  }

  Future<void> _createLeague() async {
    final s = S.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);
    
    try {
      await _repository.init();

      final league = await _repository.createLeague(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        type: _leagueType,
        maxMembers: int.tryParse(_maxMembersController.text) ?? 10,
        budget: double.tryParse(_budgetController.text) ?? 150.0,
        matchName: '${SportMonksConfig.competitionName} 2026',
        matchDateTime: DateTime.now().add(const Duration(days: 3)),
        mode: LeagueMode.classic,
        draftSettings: null,
        tradeSettings: null,
        rosterSize: int.tryParse(_rosterSizeController.text) ?? 18,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.leagueCreated(league.name)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, league);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.failedToCreateLeague(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(s.createLeagueLabel),
        centerTitle: false,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // League Type Selection (Public vs Private)
            _buildSectionTitle(theme, s.leagueVisibility),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    theme,
                    LeagueType.public,
                    Icons.public,
                    s.publicLeague,
                    s.anyoneCanJoin,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeCard(
                    theme,
                    LeagueType.private,
                    Icons.lock,
                    s.privateLeague,
                    s.inviteOnly,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // League Name
            _buildSectionTitle(theme, s.leagueDetails),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: _buildInputDecoration(
                label: s.leagueName,
                hint: s.enterLeagueName,
                icon: Icons.emoji_events,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return s.pleaseEnterLeagueName;
                }
                if (value.trim().length < 3) {
                  return s.nameMustBeAtLeast3Characters;
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: _buildInputDecoration(
                label: s.descriptionOptional,
                hint: s.describeYourLeague,
                icon: Icons.description,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            
            const SizedBox(height: 24),
            
            // Settings
            _buildSectionTitle(theme, s.settings),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxMembersController,
                    decoration: _buildInputDecoration(
                      label: s.maxMembers,
                      hint: '10',
                      icon: Icons.people,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final num = int.tryParse(value ?? '');
                      if (num == null || num < 2 || num > 20) {
                        return s.range2to20;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _rosterSizeController,
                    decoration: _buildInputDecoration(
                      label: s.rosterSize,
                      hint: '18',
                      icon: Icons.group,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final num = int.tryParse(value ?? '');
                      if (num == null || num < 11 || num > 25) {
                        return s.range11to25;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            TextFormField(
              controller: _budgetController,
              decoration: _buildInputDecoration(
                label: s.teamBudget,
                hint: '150',
                icon: Icons.account_balance_wallet,
                suffix: s.millionUsd,
                helper: s.classicBudgetRecommendation,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              validator: (value) {
                final num = double.tryParse(value ?? '');
                if (num == null || num < 50 || num > 1000) {
                  return s.range50to1000;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Info Card
            _buildInfoCard(theme),
            
            const SizedBox(height: 32),
            
            // Create Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createLeague,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        s.createLeagueLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: bgTextColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTypeCard(
    ThemeData theme,
    LeagueType type,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = _leagueType == type;
    
    return InkWell(
      onTap: () => setState(() => _leagueType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.primaryColor.withValues(alpha: 0.2)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.primaryColor : bgTextColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? theme.primaryColor : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: bgTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? prefix,
    String? suffix,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: bgTextColor),
      prefixText: prefix,
      suffixText: suffix,
      helperText: helper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: bgTextColor.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: bgTextColor.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    final s = S.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                s.howClassicModeWorks,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(s.classicInfoCreateInvite),
          _buildInfoItem(s.classicInfoBudgetTeam),
          _buildInfoItem(s.classicInfoSamePlayersAllowed),
          _buildInfoItem(s.classicInfoEarnPoints),
          if (_leagueType == LeagueType.private)
            _buildInfoItem(s.shareInviteCodeWithFriends),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: bgTextColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
