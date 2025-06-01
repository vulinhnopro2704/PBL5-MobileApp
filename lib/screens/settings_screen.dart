import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/env_config.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/log_service.dart';
import '../services/websocket_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _apiHostController = TextEditingController();
  final _apiPortController = TextEditingController();
  final _wsHostController = TextEditingController();
  final _wsPortController = TextEditingController();
  // New controllers for AI server settings
  final _aiServerHostController = TextEditingController();
  final _aiServerPortController = TextEditingController();

  // Speed settings
  double _robotSpeed = 0.5; // Default speed 50%

  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();

  String _apiTestResult = '';
  String _wsTestResult = '';
  String _aiServerTestResult = '';
  bool _isTesting = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiHostController.dispose();
    _apiPortController.dispose();
    _wsHostController.dispose();
    _wsPortController.dispose();
    _aiServerHostController.dispose();
    _aiServerPortController.dispose();
    _wsService.dispose();
    super.dispose();
  }

  void _loadSettings() {
    setState(() {
      _isLoading = true;
    });

    try {
      _apiHostController.text = EnvConfig.apiHost;
      _apiPortController.text = EnvConfig.apiPort;
      _wsHostController.text = EnvConfig.wsHost;
      _wsPortController.text = EnvConfig.wsPort;

      // Load AI server settings - remove unnecessary null-aware operators
      _aiServerHostController.text = EnvConfig.aiServerHost;
      _aiServerPortController.text = EnvConfig.aiServerPort;

      // Load robot speed
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
      dotenv.env['API_HOST'] = _apiHostController.text.trim();
      dotenv.env['API_PORT'] = _apiPortController.text.trim();
      dotenv.env['WS_HOST'] = _wsHostController.text.trim();
      dotenv.env['WS_PORT'] = _wsPortController.text.trim();

      // Save AI server settings
      dotenv.env['AI_SERVER_HOST'] = _aiServerHostController.text.trim();
      dotenv.env['AI_SERVER_PORT'] = _aiServerPortController.text.trim();

      // Save robot speed
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
        'Settings updated: API=${EnvConfig.apiBaseUrl}, WS=${EnvConfig.wsUrl}, AI=${_aiServerHostController.text}:${_aiServerPortController.text}, Speed=$_robotSpeed',
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

  Future<void> _testApiConnection() async {
    setState(() {
      _isTesting = true;
      _apiTestResult = 'Testing...';
    });

    try {
      final success = await _apiService.testConnection();
      setState(() {
        _apiTestResult =
            success ? 'Connection successful' : 'Connection failed';
      });
    } catch (e) {
      setState(() {
        _apiTestResult = 'Error: ${e.toString()}';
      });
      LogService.error('API test error', e);
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

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
      // Use the API service to test connection to AI server
      final success = await _apiService.testAiServerConnection(
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

                            // Robot Speed Card
                            Container(
                              decoration: AppTheme.cardDecoration,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.speed,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Robot Speed',
                                        style: AppTheme.subheadingStyle,
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.white24),
                                  const SizedBox(height: 8),

                                  // Speed information
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Speed:', style: AppTheme.bodyStyle),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getSpeedColor(),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '${(_robotSpeed * 100).toInt()}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Speed slider
                                  Slider(
                                    value: _robotSpeed,
                                    onChanged: (value) {
                                      setState(() {
                                        _robotSpeed = value;
                                      });
                                    },
                                    min: 0.1,
                                    max: 1.0,
                                    divisions: 9,
                                    label: '${(_robotSpeed * 100).toInt()}%',
                                    activeColor: _getSpeedColor(),
                                  ),

                                  // Speed description
                                  Text(
                                    _getSpeedDescription(),
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // API Settings Card
                            Container(
                              decoration: AppTheme.cardDecoration,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.api,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'API Settings',
                                        style: AppTheme.subheadingStyle,
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.white24),
                                  const SizedBox(height: 16),

                                  // API Host
                                  TextFormField(
                                    controller: _apiHostController,
                                    decoration: InputDecoration(
                                      labelText: 'API Host',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.surfaceDark
                                          .withOpacity(0.7),
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.computer,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter API host';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // API Port
                                  TextFormField(
                                    controller: _apiPortController,
                                    decoration: InputDecoration(
                                      labelText: 'API Port',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.surfaceDark
                                          .withOpacity(0.7),
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.pin,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter API port';
                                      }
                                      final port = int.tryParse(value);
                                      if (port == null ||
                                          port <= 0 ||
                                          port > 65535) {
                                        return 'Please enter a valid port number (1-65535)';
                                      }
                                      return null;
                                    },
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 16),

                                  // Test API button and result
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _isTesting
                                                  ? null
                                                  : _testApiConnection,
                                          icon: const Icon(Icons.speed),
                                          label: Text(
                                            _isTesting
                                                ? 'Testing...'
                                                : 'Test API Connection',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                _apiTestResult.contains(
                                                      'successful',
                                                    )
                                                    ? AppTheme.connectedColor
                                                        .withOpacity(0.2)
                                                    : _apiTestResult.contains(
                                                          'failed',
                                                        ) ||
                                                        _apiTestResult.contains(
                                                          'Error',
                                                        )
                                                    ? AppTheme.disconnectedColor
                                                        .withOpacity(0.2)
                                                    : Colors.grey.shade800
                                                        .withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  _apiTestResult.contains(
                                                        'successful',
                                                      )
                                                      ? AppTheme.connectedColor
                                                      : _apiTestResult.contains(
                                                            'failed',
                                                          ) ||
                                                          _apiTestResult
                                                              .contains('Error')
                                                      ? AppTheme
                                                          .disconnectedColor
                                                      : Colors.grey.shade600,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            _apiTestResult.isEmpty
                                                ? 'Not tested'
                                                : _apiTestResult,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // WebSocket Settings Card
                            Container(
                              decoration: AppTheme.cardDecoration,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.wifi,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'WebSocket Settings',
                                        style: AppTheme.subheadingStyle,
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.white24),
                                  const SizedBox(height: 16),

                                  // WebSocket Host
                                  TextFormField(
                                    controller: _wsHostController,
                                    decoration: InputDecoration(
                                      labelText: 'WebSocket Host',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.surfaceDark
                                          .withOpacity(0.7),
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.computer,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter WebSocket host';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // WebSocket Port
                                  TextFormField(
                                    controller: _wsPortController,
                                    decoration: InputDecoration(
                                      labelText: 'WebSocket Port',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.surfaceDark
                                          .withOpacity(0.7),
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.pin,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter WebSocket port';
                                      }
                                      final port = int.tryParse(value);
                                      if (port == null ||
                                          port <= 0 ||
                                          port > 65535) {
                                        return 'Please enter a valid port number (1-65535)';
                                      }
                                      return null;
                                    },
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 16),

                                  // Test WebSocket button and result
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _isTesting
                                                  ? null
                                                  : _testWsConnection,
                                          icon: const Icon(Icons.speed),
                                          label: Text(
                                            _isTesting
                                                ? 'Testing...'
                                                : 'Test WebSocket Connection',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                _wsTestResult.contains(
                                                      'successful',
                                                    )
                                                    ? AppTheme.connectedColor
                                                        .withOpacity(0.2)
                                                    : _wsTestResult.contains(
                                                          'failed',
                                                        ) ||
                                                        _wsTestResult.contains(
                                                          'Error',
                                                        )
                                                    ? AppTheme.disconnectedColor
                                                        .withOpacity(0.2)
                                                    : Colors.grey.shade800
                                                        .withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  _wsTestResult.contains(
                                                        'successful',
                                                      )
                                                      ? AppTheme.connectedColor
                                                      : _wsTestResult.contains(
                                                            'failed',
                                                          ) ||
                                                          _wsTestResult
                                                              .contains('Error')
                                                      ? AppTheme
                                                          .disconnectedColor
                                                      : Colors.grey.shade600,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            _wsTestResult.isEmpty
                                                ? 'Not tested'
                                                : _wsTestResult,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // AI Server Settings Card
                            Container(
                              decoration: AppTheme.cardDecoration,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.memory,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'AI Server Settings',
                                        style: AppTheme.subheadingStyle,
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.white24),
                                  const SizedBox(height: 16),

                                  // AI Server Host
                                  TextFormField(
                                    controller: _aiServerHostController,
                                    decoration: InputDecoration(
                                      labelText: 'AI Server Host',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.surfaceDark
                                          .withOpacity(0.7),
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.computer,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter AI Server host';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // AI Server Port
                                  TextFormField(
                                    controller: _aiServerPortController,
                                    decoration: InputDecoration(
                                      labelText: 'AI Server Port',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.surfaceDark
                                          .withOpacity(0.7),
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.pin,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter AI Server port';
                                      }
                                      final port = int.tryParse(value);
                                      if (port == null ||
                                          port <= 0 ||
                                          port > 65535) {
                                        return 'Please enter a valid port number (1-65535)';
                                      }
                                      return null;
                                    },
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 16),

                                  // Test AI Server button and result
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _isTesting
                                                  ? null
                                                  : _testAiServerConnection,
                                          icon: const Icon(Icons.biotech),
                                          label: Text(
                                            _isTesting
                                                ? 'Testing...'
                                                : 'Test AI Server',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                _aiServerTestResult.contains(
                                                      'successful',
                                                    )
                                                    ? AppTheme.connectedColor
                                                        .withOpacity(0.2)
                                                    : _aiServerTestResult
                                                            .contains(
                                                              'failed',
                                                            ) ||
                                                        _aiServerTestResult
                                                            .contains('Error')
                                                    ? AppTheme.disconnectedColor
                                                        .withOpacity(0.2)
                                                    : Colors.grey.shade800
                                                        .withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  _aiServerTestResult.contains(
                                                        'successful',
                                                      )
                                                      ? AppTheme.connectedColor
                                                      : _aiServerTestResult
                                                              .contains(
                                                                'failed',
                                                              ) ||
                                                          _aiServerTestResult
                                                              .contains('Error')
                                                      ? AppTheme
                                                          .disconnectedColor
                                                      : Colors.grey.shade600,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            _aiServerTestResult.isEmpty
                                                ? 'Not tested'
                                                : _aiServerTestResult,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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

  // Helper methods for speed settings
  Color _getSpeedColor() {
    if (_robotSpeed < 0.3) {
      return Colors.green;
    } else if (_robotSpeed < 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getSpeedDescription() {
    if (_robotSpeed < 0.3) {
      return 'Safe speed for precision movement';
    } else if (_robotSpeed < 0.7) {
      return 'Balanced speed for normal operation';
    } else {
      return 'High speed - use with caution!';
    }
  }
}
