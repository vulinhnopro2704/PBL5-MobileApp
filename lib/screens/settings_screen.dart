import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

import '../config/env_config.dart';
import '../config/app_theme.dart';
import '../services/ai_service.dart';
import '../services/log_service.dart';
import '../services/websocket_service.dart';

// Import custom widgets
import '../widgets/setting/setting_card.dart';
import '../widgets/setting/connection_setting.dart';
import '../widgets/setting/robot_mode_setting.dart';
import '../widgets/setting/speed_setting.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers for connection settings
  final _wsHostController = TextEditingController();
  final _wsPortController = TextEditingController();
  final _aiServerHostController = TextEditingController();
  final _aiServerPortController = TextEditingController();

  // Speed settings
  double _robotSpeed = 0.5; // Default speed 50%

  // Services
  final AiService _aiService = AiService();
  final WebSocketService _wsService = WebSocketService();

  // State variables
  String _wsTestResult = '';
  String _aiServerTestResult = '';
  bool _isTesting = false;
  bool _isLoading = false;
  bool _isAutoMode = false;
  bool _isPoweredOn = true;

  // Stream subscriptions
  StreamSubscription? _connectionStatusSubscription;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    // Initialize robot state from WebSocket service
    _isAutoMode = _wsService.isAutoMode;
    _isPoweredOn = _wsService.isPoweredOn;

    // Listen for changes in robot state
    _connectionStatusSubscription = _wsService.connectionStatusStream.listen((
      isConnected,
    ) {
      if (mounted) {
        setState(() {
          _isAutoMode = _wsService.isAutoMode;
          _isPoweredOn = _wsService.isPoweredOn;
        });
      }
    });

    // Also listen for message stream to get robot state updates
    _messageSubscription = _wsService.messageStream.listen((message) {
      if (mounted && message is Map<String, dynamic>) {
        setState(() {
          if (message.containsKey('mode')) {
            _isAutoMode = message['mode'] == 'auto';
          }
          if (message.containsKey('isAutoMode')) {
            _isAutoMode = message['isAutoMode'];
          }
          if (message.containsKey('isPoweredOn')) {
            _isPoweredOn = message['isPoweredOn'];
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel stream subscriptions to prevent memory leaks
    _connectionStatusSubscription?.cancel();
    _messageSubscription?.cancel();

    _wsHostController.dispose();
    _wsPortController.dispose();
    _aiServerHostController.dispose();
    _aiServerPortController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    setState(() {
      _isLoading = true;
    });

    try {
      _wsHostController.text = EnvConfig.wsHost;
      _wsPortController.text = EnvConfig.wsPort;
      _aiServerHostController.text = EnvConfig.aiServerHost;
      _aiServerPortController.text = EnvConfig.aiServerPort;
      _robotSpeed = EnvConfig.robotSpeed ?? 0.5;
    } catch (e) {
      LogService.error('Error loading settings', e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update environment variables in memory
      dotenv.env['WS_HOST'] = _wsHostController.text.trim();
      dotenv.env['WS_PORT'] = _wsPortController.text.trim();
      dotenv.env['AI_SERVER_HOST'] = _aiServerHostController.text.trim();
      dotenv.env['AI_SERVER_PORT'] = _aiServerPortController.text.trim();
      dotenv.env['ROBOT_SPEED'] = _robotSpeed.toString();

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Settings saved successfully', style: AppTheme.bodyStyle),
            ],
          ),
          backgroundColor: AppTheme.connectedColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      LogService.info(
        'Settings updated: WS=${EnvConfig.wsUrl}, AI=${_aiServerHostController.text}:${_aiServerPortController.text}, Speed=$_robotSpeed',
      );
    } catch (e) {
      LogService.error('Error saving settings', e);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Connection test methods
  Future<void> _testWsConnection() async {
    setState(() {
      _isTesting = true;
      _wsTestResult = 'Testing...';
    });

    try {
      final success = await _wsService.testConnection();
      setState(() {
        _wsTestResult = success ? 'Connection successful' : 'Connection failed';
      });

      // Close connection after test
      if (success) {
        _wsService.disconnect();
      }
    } catch (e) {
      setState(() {
        _wsTestResult = 'Error: ${e.toString()}';
      });
      LogService.error('WebSocket test error', e);
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testAiServerConnection() async {
    setState(() {
      _isTesting = true;
      _aiServerTestResult = 'Testing...';
    });

    try {
      final success = await _aiService.testAiServerConnection(
        _aiServerHostController.text,
        int.parse(_aiServerPortController.text),
      );

      setState(() {
        _aiServerTestResult =
            success ? 'Connection successful' : 'Connection failed';
      });
    } catch (e) {
      setState(() {
        _aiServerTestResult = 'Error: ${e.toString()}';
      });
      LogService.error('AI server test error', e);
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title
                            Text(
                              'Robot Settings',
                              style: AppTheme.headingStyle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Robot Mode Card
                            SettingCard(
                              title: 'Robot Mode',
                              icon: Icons.settings_applications,
                              child: RobotModeSetting(
                                isPoweredOn: _isPoweredOn,
                                isAutoMode: _isAutoMode,
                                onPowerToggle: (value) {
                                  _wsService.togglePower();
                                  // State will be updated via messageStream
                                },
                                onModeToggle: (value) {
                                  _wsService.toggleAutoMode();
                                  // State will be updated via messageStream
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Robot Speed Card
                            SettingCard(
                              title: 'Robot Speed',
                              icon: Icons.speed,
                              child: SpeedSetting(
                                robotSpeed: _robotSpeed,
                                onSpeedChanged: (value) {
                                  setState(() {
                                    _robotSpeed = value;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            // WebSocket Settings Card
                            SettingCard(
                              title: 'WebSocket Settings',
                              icon: Icons.wifi,
                              child: ConnectionSetting(
                                hostController: _wsHostController,
                                portController: _wsPortController,
                                hostLabel: 'WebSocket Host',
                                portLabel: 'WebSocket Port',
                                isTesting: _isTesting,
                                testResult: _wsTestResult,
                                onTestPressed: _testWsConnection,
                                testButtonLabel: 'Test WebSocket Connection',
                              ),
                            ),

                            const SizedBox(height: 24),

                            // AI Server Settings Card
                            SettingCard(
                              title: 'AI Server Settings',
                              icon: Icons.memory,
                              child: ConnectionSetting(
                                hostController: _aiServerHostController,
                                portController: _aiServerPortController,
                                hostLabel: 'AI Server Host',
                                portLabel: 'AI Server Port',
                                isTesting: _isTesting,
                                testResult: _aiServerTestResult,
                                onTestPressed: _testAiServerConnection,
                                testButtonLabel: 'Test AI Server',
                                testIcon: Icons.biotech,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Save button
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveSettings,
                              icon: const Icon(Icons.save),
                              label: Text(
                                _isLoading ? 'Saving...' : 'Save Settings',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentColor,
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
