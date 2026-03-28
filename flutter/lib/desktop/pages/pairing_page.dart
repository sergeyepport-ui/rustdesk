import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_hbb/common.dart';

const String kPortalApiUrl = 'https://portal.pozitiv.tech/api/equipment/pair';
const String kHardcodedPassword = '11991199';
const String kPairedKey = 'portal_paired';

class PairingPage extends StatefulWidget {
  final String deviceId;
  final VoidCallback onPaired;

  const PairingPage({
    Key? key,
    required this.deviceId,
    required this.onPaired,
  }) : super(key: key);

  @override
  State<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends State<PairingPage> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _successName;

  Future<void> _pair() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Введите 6-значный код');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http.post(
        Uri.parse(kPortalApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pairing_code': code,
          'rustdesk_id': widget.deviceId,
          'rustdesk_password': kHardcodedPassword,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _successName = (data['equipment_name'] ?? 'Устройство') as String;
          _loading = false;
        });
        await bind.mainSetLocalOption(key: kPairedKey, value: 'true');
        Future.delayed(const Duration(seconds: 2), widget.onPaired);
      } else {
        String detail = 'Ошибка привязки';
        try {
          final data = jsonDecode(res.body);
          detail = (data['detail'] ?? detail) as String;
        } catch (_) {}
        setState(() {
          _error = detail;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка сети: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idText = widget.deviceId.isNotEmpty ? widget.deviceId : 'загрузка...';
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.support_agent, size: 36, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Позитив',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Удалённая поддержка',
                style: TextStyle(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 28),

              if (_successName != null) ...[
                const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 56),
                const SizedBox(height: 12),
                Text(
                  'Привязано к: $_successName',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                // Device ID display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.computer, size: 16, color: Colors.white38),
                      const SizedBox(width: 8),
                      Text(
                        'ID: $idText',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Введите код привязки из портала',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.15),
                      fontSize: 28,
                      letterSpacing: 10,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onSubmitted: (_) => _pair(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFef5350), fontSize: 13),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _pair,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF2196F3).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Привязать', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    await bind.mainSetLocalOption(key: kPairedKey, value: 'true');
                    widget.onPaired();
                  },
                  child: const Text(
                    'Пропустить',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 12),
              const Text(
                'ООО «Позитив» — ИТ поддержка',
                style: TextStyle(fontSize: 11, color: Colors.white30),
              ),
              const SizedBox(height: 2),
              const Text(
                'portal.pozitiv.tech',
                style: TextStyle(fontSize: 11, color: Colors.white30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
