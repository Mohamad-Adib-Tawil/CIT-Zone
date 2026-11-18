import 'package:flutter/material.dart';

import '../../../auth/domain/google_identity.dart';
import '../../../auth/domain/student_session_repository.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'hasobjy_device_screens.dart';

class StudentDeviceRequestPage extends StatefulWidget {
  const StudentDeviceRequestPage({
    super.key,
    required this.identity,
    required this.repository,
    required this.onSignOut,
  });

  final GoogleIdentity identity;
  final StudentSessionRepository repository;
  final VoidCallback onSignOut;

  @override
  State<StudentDeviceRequestPage> createState() =>
      _StudentDeviceRequestPageState();
}

class _StudentDeviceRequestPageState extends State<StudentDeviceRequestPage> {
  bool _open = false;
  bool _busy = false;
  bool _statusVerified = false;
  String? _status;
  String? _error;

  Future<void> _openForm() async {
    setState(() {
      _open = true;
      _busy = true;
      _error = null;
    });
    final result = await widget.repository.currentDeviceRequest(
      widget.identity,
    );
    if (!mounted) return;
    setState(() {
      _statusVerified = result.isRight();
      if (_statusVerified) _status = result.getRight().toNullable();
      _busy = false;
      if (result.isLeft()) _error = 'تعذّر جلب حالة الطلب.';
    });
  }

  Future<void> _submit(String reason) async {
    if (_busy ||
        !_statusVerified ||
        _status == 'pending' ||
        _status == 'approved') {
      return;
    }
    if (reason.isEmpty || reason.length > 500) {
      setState(() => _error = 'أدخل سبب التغيير بحد أقصى 500 حرف.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.repository.requestDeviceChange(
      widget.identity,
      reason,
    );
    final latest = result.isLeft()
        ? await widget.repository.currentDeviceRequest(widget.identity)
        : null;
    if (!mounted) return;
    setState(() {
      _busy = false;
      _statusVerified = result.isRight() || latest?.isRight() == true;
      if (_statusVerified) {
        _status =
            result.getRight().toNullable() ?? latest?.getRight().toNullable();
      }
      if (result.isLeft() && _status != 'pending') {
        _error = 'تعذّر تأكيد إرسال الطلب.';
      }
    });
  }

  void _back() {
    if (!_busy) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final frame = _open ? 'A-S06' : 'A-S05';
    final message =
        _error ??
        switch (_status) {
          'pending' => 'طلبك قيد مراجعة الإدارة.',
          'approved' =>
            'وافقت الإدارة على الطلب. أعد تسجيل الدخول للتحقق من الوصول.',
          'rejected' => 'رفضت الإدارة الطلب السابق.',
          _ => null,
        };
    return PopScope<Object?>(
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: HasobjyVisualScope(
        frameName: light ? '$frame-LIGHT' : frame,
        child: _open
            ? HasobjyDeviceTransferScreen(
                onSubmit: () {},
                onSubmitReason: _submit,
                onBack: _back,
                deviceName: 'هذا الجهاز',
                enabled:
                    !_busy &&
                    _statusVerified &&
                    _status != 'pending' &&
                    _status != 'approved',
                message: _busy ? 'جارٍ التحقق…' : message,
              )
            : HasobjyDeviceConflictScreen(
                onRequestTransfer: _openForm,
                onSignOut: widget.onSignOut,
              ),
      ),
    );
  }
}
