import 'package:fantacy11/api/repositories/league_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog for joining a private league with an invite code
class JoinLeagueDialog extends StatefulWidget {
  final Function(League)? onJoined;
  
  const JoinLeagueDialog({super.key, this.onJoined});

  @override
  State<JoinLeagueDialog> createState() => _JoinLeagueDialogState();
}

class _JoinLeagueDialogState extends State<JoinLeagueDialog> {
  final LeagueRepository _repository = LeagueRepository();
  final _codeController = TextEditingController();
  
  League? _foundLeague;
  bool _isSearching = false;
  bool _isJoining = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _searchLeague() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty || code.length < 4) {
      setState(() {
        _error = 'Enter a valid invite code';
        _foundLeague = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
      _foundLeague = null;
    });

    try {
      await _repository.init();
      final league = await _repository.getLeagueByInviteCode(code);
      
      if (mounted) {
        setState(() {
          _isSearching = false;
          _foundLeague = league;
          if (league == null) {
            _error = 'League not found. Check the invite code.';
          } else if (!league.canJoin) {
            _error = league.isFull 
                ? 'This league is full'
                : 'This league is no longer accepting members';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _error = 'Error searching for league';
        });
      }
    }
  }

  Future<void> _joinLeague() async {
    if (_foundLeague == null) return;

    setState(() => _isJoining = true);

    try {
      final member = await _repository.joinLeague(_foundLeague!.id);
      
      if (mounted) {
        if (member != null) {
          Navigator.pop(context);
          widget.onJoined?.call(_foundLeague!);
        } else {
          setState(() {
            _isJoining = false;
            _error = 'Failed to join league';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _error = 'Error joining league: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.link, color: theme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Join Private League',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Enter the invite code shared by your friend to join their private league.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: bgTextColor,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Code input
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Invite Code',
                hintText: 'ABC123',
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: bgColor,
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(8),
              ],
              onChanged: (_) {
                if (_foundLeague != null || _error != null) {
                  setState(() {
                    _foundLeague = null;
                    _error = null;
                  });
                }
              },
              onSubmitted: (_) => _searchLeague(),
            ),
            
            const SizedBox(height: 12),
            
            // Search button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSearching ? null : _searchLeague,
                icon: _isSearching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isSearching ? 'Searching...' : 'Find League'),
              ),
            ),
            
            // Error message
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Found league preview
            if (_foundLeague != null && _foundLeague!.canJoin) ...[
              const SizedBox(height: 16),
              _buildLeaguePreview(theme, _foundLeague!),
            ],
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_foundLeague != null && _foundLeague!.canJoin && !_isJoining)
                        ? _joinLeague
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isJoining
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Join League'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaguePreview(ThemeData theme, League league) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                'League Found!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            league.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (league.description != null && league.description!.isNotEmpty)
            Text(
              league.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: bgTextColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTag(Icons.people, '${league.memberCount}/${league.maxMembers}'),
              const SizedBox(width: 12),
              _buildTag(Icons.account_balance_wallet, '${league.budget.toInt()} credits'),
              if (league.entryFee != null && league.entryFee! > 0) ...[
                const SizedBox(width: 12),
                _buildTag(Icons.attach_money, '\$${league.entryFee!.toStringAsFixed(0)}'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: bgTextColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: bgTextColor, fontSize: 12),
        ),
      ],
    );
  }
}

