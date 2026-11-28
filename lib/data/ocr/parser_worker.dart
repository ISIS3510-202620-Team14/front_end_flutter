import 'dart:isolate';

import 'package:front_end_flutter/data/ocr/student_list_scanner.dart';
import 'package:front_end_flutter/domain/model/scanned_row.dart';

typedef OcrWord = ({String text, double left, double top, double bottom});

// =================== MULTI-THREADING ===================

/* Worker isolate that is created ONCE and reused for every page.
 * (compute / Isolate.run create and kill a new isolate for every job.)
 */
class ParserWorker {
  Future<SendPort>? _worker;
  Isolate? _isolate;
  int parsedPages = 0;

  bool get alive {
    return _isolate != null;
  }

  Future<List<ScannedRow>> parse(List<OcrWord> words) async {
    // 1. Create the worker the first time. Next pages reuse it.
    // 2. Send the page together with a mailbox for the answer.
    // 3. Wait for the rows in that mailbox.

    // 1
    _worker ??= _start();
    final SendPort worker = await _worker!;
    // 2
    final ReceivePort answer = ReceivePort();
    worker.send((words, answer.sendPort));
    // 3
    final List<ScannedRow>? rows = await answer.first as List<ScannedRow>?;
    if (rows == null) {
      throw StateError('No se pudo leer la página');
    }
    parsedPages++;
    return rows;
  }

  Future<SendPort> _start() async {
    final ReceivePort ready = ReceivePort();
    _isolate = await Isolate.spawn(_workerMain, ready.sendPort);
    return await ready.first as SendPort;
  }

  void close() {
    _isolate?.kill();
    _isolate = null;
    _worker = null;
  }
}

/** Runs inside the worker isolate: answers every page it receives. */
void _workerMain(SendPort toMain) {
  final ReceivePort inbox = ReceivePort();
  toMain.send(inbox.sendPort);
  inbox.listen((message) {
    final (List<OcrWord> words, SendPort reply) =
        message as (List<OcrWord>, SendPort);
    try {
      reply.send(StudentListScanner.parseLines(words));
    } catch (_) {
      reply.send(null);
    }
  });
}
