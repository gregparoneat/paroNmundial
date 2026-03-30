import 'package:fantacy11/api/repositories/league_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
  final _budgetController = TextEditingController(text: '100');
  final _rosterSizeController = TextEditingController(text: '18');
  
  LeagueType _leagueType = LeagueType.public;
  LeagueMode _leagueMode = LeagueMode.classic;
  bool _isCreating = false;
  
  // Draft settings
  DraftOrderType _draftOrderType = DraftOrderType.snake;
  int _pickTimerSeconds = 90;
  DateTime? _draftDateTime;
  
  // Trade settings
  TradeApproval _tradeApproval = TradeApproval.none;
  DateTime? _tradeDeadline;

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
    if (!_formKey.currentState!.validate()) return;
    
    // Validate draft settings if draft mode
    if (_leagueMode == LeagueMode.draft && _draftDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a draft date and time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isCreating = true);
    
    try {
      await _repository.init();
      
      // Create draft settings if draft mode
      DraftSettings? draftSettings;
      TradeSettings? tradeSettings;
      
      if (_leagueMode == LeagueMode.draft) {
        draftSettings = DraftSettings(
          orderType: _draftOrderType,
          pickTimerSeconds: _pickTimerSeconds,
          draftDateTime: _draftDateTime,
          autoPick: true,
          rosterSize: int.tryParse(_rosterSizeController.text) ?? 18,
        );
        
        tradeSettings = TradeSettings(
          approvalType: _tradeApproval,
          tradeDeadline: _tradeDeadline,
          allowMultiPlayerTrades: true,
        );
      }
      
      final league = await _repository.createLeague(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        type: _leagueType,
        maxMembers: int.tryParse(_maxMembersController.text) ?? 10,
        budget: double.tryParse(_budgetController.text) ?? 100.0,
        matchName: 'Liga MX Season',
        matchDateTime: _leagueMode == LeagueMode.draft 
            ? _draftDateTime 
            : DateTime.now().add(const Duration(days: 3)),
        mode: _leagueMode,
        draftSettings: draftSettings,
        tradeSettings: tradeSettings,
        rosterSize: int.tryParse(_rosterSizeController.text) ?? 18,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('League "${league.name}" created!'),
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
            content: Text('Failed to create league: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _selectDraftDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(hours: 24)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date == null || !mounted) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    
    if (time == null || !mounted) return;
    
    setState(() {
      _draftDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }
  
  Future<void> _selectTradeDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now().add(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null && mounted) {
      setState(() => _tradeDeadline = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create League'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // League Mode Selection (Classic vs Draft)
            _buildSectionTitle(theme, 'League Mode'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildModeCard(
                    theme,
                    LeagueMode.classic,
                    Icons.account_balance_wallet,
                    'Classic',
                    'Budget-based',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeCard(
                    theme,
                    LeagueMode.draft,
                    Icons.format_list_numbered,
                    'Draft',
                    'Unique ownership',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // League Type Selection (Public vs Private)
            _buildSectionTitle(theme, 'League Visibility'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    theme,
                    LeagueType.public,
                    Icons.public,
                    'Public',
                    'Anyone can join',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeCard(
                    theme,
                    LeagueType.private,
                    Icons.lock,
                    'Private',
                    'Invite only',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // League Name
            _buildSectionTitle(theme, 'League Details'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: _buildInputDecoration(
                label: 'League Name',
                hint: 'Enter a name for your league',
                icon: Icons.emoji_events,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a league name';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
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
                label: 'Description (Optional)',
                hint: 'Describe your league',
                icon: Icons.description,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            
            const SizedBox(height: 24),
            
            // Settings
            _buildSectionTitle(theme, 'Settings'),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxMembersController,
                    decoration: _buildInputDecoration(
                      label: 'Max Members',
                      hint: '10',
                      icon: Icons.people,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final num = int.tryParse(value ?? '');
                      if (num == null || num < 2 || num > 20) {
                        return '2-20';
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
                      label: 'Roster Size',
                      hint: '18',
                      icon: Icons.group,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final num = int.tryParse(value ?? '');
                      if (num == null || num < 11 || num > 25) {
                        return '11-25';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            // Budget field - only for classic mode
            if (_leagueMode == LeagueMode.classic) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                decoration: _buildInputDecoration(
                  label: 'Team Budget',
                  hint: '100',
                  icon: Icons.account_balance_wallet,
                  suffix: 'Million USD',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                validator: (value) {
                  final num = double.tryParse(value ?? '');
                  if (num == null || num < 50 || num > 1000) {
                    return '50-1000';
                  }
                  return null;
                },
              ),
            ],
            
            // Draft Settings - only for draft mode
            if (_leagueMode == LeagueMode.draft) ...[
              const SizedBox(height: 24),
              _buildDraftSettingsSection(theme),
              const SizedBox(height: 24),
              _buildTradeSettingsSection(theme),
            ],
            
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
                    : const Text(
                        'Create League',
                        style: TextStyle(
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
  
  Widget _buildModeCard(
    ThemeData theme,
    LeagueMode mode,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = _leagueMode == mode;
    
    return InkWell(
      onTap: () => setState(() => _leagueMode = mode),
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
  
  Widget _buildDraftSettingsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, 'Draft Settings'),
        const SizedBox(height: 8),
        
        // Draft Date/Time
        InkWell(
          onTap: _selectDraftDateTime,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _draftDateTime != null 
                    ? theme.primaryColor 
                    : bgTextColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: _draftDateTime != null ? theme.primaryColor : bgTextColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Draft Date & Time',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: bgTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _draftDateTime != null
                            ? DateFormat('EEEE, MMM d, yyyy • h:mm a').format(_draftDateTime!)
                            : 'Tap to select',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _draftDateTime != null ? null : bgTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: bgTextColor),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Draft Order Type
        Row(
          children: [
            Expanded(
              child: _buildDraftOptionCard(
                theme,
                DraftOrderType.snake,
                'Snake',
                '1→10, 10→1...',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDraftOptionCard(
                theme,
                DraftOrderType.linear,
                'Linear',
                'Same order',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Pick Timer
        _buildSectionTitle(theme, 'Pick Timer'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final seconds in [60, 90, 120, 180]) ...[
              Expanded(
                child: _buildTimerChip(theme, seconds),
              ),
              if (seconds != 180) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
  
  Widget _buildDraftOptionCard(
    ThemeData theme,
    DraftOrderType type,
    String title,
    String subtitle,
  ) {
    final isSelected = _draftOrderType == type;
    
    return InkWell(
      onTap: () => setState(() => _draftOrderType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
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
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? theme.primaryColor : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: bgTextColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimerChip(ThemeData theme, int seconds) {
    final isSelected = _pickTimerSeconds == seconds;
    final label = seconds >= 60 
        ? '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'
        : '${seconds}s';
    
    return InkWell(
      onTap: () => setState(() => _pickTimerSeconds = seconds),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.primaryColor 
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTradeSettingsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, 'Trade Settings'),
        const SizedBox(height: 8),
        
        // Trade Approval Type
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trade Approval',
                style: theme.textTheme.bodySmall?.copyWith(color: bgTextColor),
              ),
              const SizedBox(height: 8),
              ...TradeApproval.values.map((approval) => RadioListTile<TradeApproval>(
                title: Text(approval.displayName),
                subtitle: Text(
                  approval.description,
                  style: theme.textTheme.bodySmall?.copyWith(color: bgTextColor),
                ),
                value: approval,
                groupValue: _tradeApproval,
                onChanged: (value) => setState(() => _tradeApproval = value!),
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.primaryColor,
              )),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Trade Deadline
        InkWell(
          onTap: _selectTradeDeadline,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.event_busy, color: bgTextColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trade Deadline (Optional)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: bgTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tradeDeadline != null
                            ? DateFormat('MMM d, yyyy').format(_tradeDeadline!)
                            : 'No deadline',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_tradeDeadline != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _tradeDeadline = null),
                    color: bgTextColor,
                  )
                else
                  Icon(Icons.chevron_right, color: bgTextColor),
              ],
            ),
          ),
        ),
      ],
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
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: bgTextColor),
      prefixText: prefix,
      suffixText: suffix,
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
    final isClassic = _leagueMode == LeagueMode.classic;
    
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
                isClassic ? 'How Classic Mode Works' : 'How Draft Mode Works',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isClassic) ...[
            _buildInfoItem('Create your league and invite friends'),
            _buildInfoItem('Each member builds a team within the budget'),
            _buildInfoItem('Multiple managers can have the same players'),
            _buildInfoItem('Earn points based on real player performance'),
          ] else ...[
            _buildInfoItem('Set up your league and schedule the draft'),
            _buildInfoItem('On draft day, take turns picking players'),
            _buildInfoItem('Each player can only be owned by one team'),
            _buildInfoItem('Trade players and pick up free agents during the season'),
            _buildInfoItem('Compete for the championship!'),
          ],
          if (_leagueType == LeagueType.private)
            _buildInfoItem('Share the invite code with friends to join'),
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

