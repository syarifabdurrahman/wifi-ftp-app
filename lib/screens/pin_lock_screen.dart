import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quick_wifi_share/providers/settings_provider.dart';
import 'package:quick_wifi_share/theme/app_theme.dart';

class PinLockScreen extends StatefulWidget {
  final bool isSetup;
  final VoidCallback? onUnlocked;

  const PinLockScreen({super.key, this.isSetup = false, this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isConfirming = false;
  bool _showError = false;
  String _errorText = '';

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isSetup
          ? AppBar(
              title: Text(_isConfirming ? 'Confirm PIN' : 'Set PIN'),
              backgroundColor: Colors.transparent,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.isSetup
                      ? (_isConfirming ? 'Confirm your PIN' : 'Create a PIN code')
                      : 'Enter PIN',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isSetup
                      ? 'PIN will be required to open the app'
                      : 'Enter your PIN to unlock',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                if (_showError)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 20, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Text(_errorText, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                TextField(
                  controller: _isConfirming ? _confirmController : _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    letterSpacing: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: '· · · · · ·',
                    hintStyle: TextStyle(
                      fontSize: 32, letterSpacing: 12,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.getCardColor(context),
                  ),
                  onChanged: (value) {
                    if (_showError) setState(() { _showError = false; _errorText = ''; });
                    if (!widget.isSetup && value.length == 6) {
                      _verifyPin(value);
                    }
                  },
                ),
                if (widget.isSetup && _isConfirming) ...[
                  const SizedBox(height: 16),
                  Text('Re-enter your PIN to confirm',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
                ],
                if (widget.isSetup) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isConfirming ? _confirmPin : _nextStep,
                    icon: Icon(_isConfirming ? Icons.check : Icons.arrow_forward),
                    label: Text(_isConfirming ? 'Confirm' : 'Next'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  if (!_isConfirming) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _nextStep() {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() { _showError = true; _errorText = 'PIN must be at least 4 digits'; });
      return;
    }
    setState(() { _isConfirming = true; _showError = false; });
  }

  void _confirmPin() {
    final pin1 = _pinController.text.trim();
    final pin2 = _confirmController.text.trim();
    if (pin1 != pin2) {
      setState(() { _showError = true; _errorText = 'PINs do not match'; _confirmController.clear(); });
      return;
    }
    context.read<SettingsProvider>().setPin(pin1);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN lock enabled'), behavior: SnackBarBehavior.floating),
    );
  }

  void _verifyPin(String pin) {
    final settings = context.read<SettingsProvider>();
    if (settings.verifyPin(pin)) {
      widget.onUnlocked?.call();
    } else {
      setState(() { _showError = true; _errorText = 'Wrong PIN'; _pinController.clear(); });
    }
  }
}