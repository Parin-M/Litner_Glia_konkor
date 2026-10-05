import 'dart:math' as math;
import 'dart:typed_data';
import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import '../models/native_models.dart';

class NoqlMatch {
  const NoqlMatch(this.card, this.score);
  final LeitnerCard card;
  final double score;
}

class NoqlService {
  NoqlService._();
  static final NoqlService instance = NoqlService._();

  OnnxRuntime? _runtime;
  OrtSession? _session;
  SentencePieceTokenizer? _tokenizer;
  Float32List? _index;
  int _indexCount = 0;
  int _indexDim = 0;
  bool _ready = false;
  String? error;

  bool get isReady => _ready;

  Future<bool> init() async {
    if (_ready) return true;
    try {
      final tokenizerBytes = (await rootBundle.load('assets/ai/tokenizer.json'))
          .buffer
          .asUint8List();
      _tokenizer = SentencePieceTokenizer.fromBytes(tokenizerBytes);

      _runtime = OnnxRuntime();
      _session = await _runtime!.createSessionFromAsset('assets/ai/noql.onnx');
      await _loadIndex();
      _ready = _index != null && _indexCount > 0 && _indexDim > 0;
      error = _ready ? null : 'نمایه هوش مصنوعی آماده نیست.';
      return _ready;
    } catch (e) {
      error = e.toString();
      _ready = false;
      return false;
    }
  }

  Future<void> _loadIndex() async {
    final bytes = (await rootBundle.load('assets/ai/card_embeddings.bin'))
        .buffer
        .asUint8List();
    if (bytes.length < 8) return;
    final data = ByteData.sublistView(bytes);
    _indexCount = data.getUint32(0, Endian.little);
    _indexDim = data.getUint32(4, Endian.little);
    final expected = 8 + (_indexCount * _indexDim * 4);
    if (bytes.length < expected) {
      _index = null;
      return;
    }
    _index = Float32List.view(bytes.buffer, bytes.offsetInBytes + 8,
        _indexCount * _indexDim);
  }

  Future<List<double>> embed(String text) async {
    if (!await init()) return const [];
    final tokenizer = _tokenizer!;
    final session = _session!;
    final encoding = tokenizer.encode(text);
    final ids = Int64List.fromList(encoding.ids);
    final mask = Int64List.fromList(encoding.attentionMask);
    final inputIds = await OrtValue.fromList(ids, [1, ids.length]);
    final attention = await OrtValue.fromList(mask, [1, mask.length]);
    try {
      final outputs = await session.run({
        session.inputNames.contains('input_ids') ? 'input_ids' : session.inputNames.first: inputIds,
        session.inputNames.contains('attention_mask') ? 'attention_mask' : session.inputNames[1]: attention,
      });
      final output = outputs[session.outputNames.first];
      if (output == null) return const [];
      final raw = await output.asFlattenedList();
      return raw.map((e) => (e as num).toDouble()).toList();
    } finally {
      await inputIds.dispose();
      await attention.dispose();
    }
  }

  Future<List<NoqlMatch>> similarCards(
    String query,
    List<LeitnerCard> cards, {
    int limit = 8,
  }) async {
    final vector = await embed(query);
    final index = _index;
    if (vector.isEmpty || index == null || _indexCount == 0) return const [];
    final count = math.min(_indexCount, cards.length);
    final scores = <NoqlMatch>[];
    for (var i = 0; i < count; i++) {
      var dot = 0.0;
      var aNorm = 0.0;
      var bNorm = 0.0;
      final base = i * _indexDim;
      final dim = math.min(vector.length, _indexDim);
      for (var j = 0; j < dim; j++) {
        final a = vector[j];
        final b = index[base + j];
        dot += a * b;
        aNorm += a * a;
        bNorm += b * b;
      }
      final denom = math.sqrt(aNorm) * math.sqrt(bNorm);
      final score = denom == 0 ? 0.0 : dot / denom;
      scores.add(NoqlMatch(cards[i], score));
    }
    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores.take(limit).toList();
  }

  Future<void> dispose() async {
    await _session?.close();
    _session = null;
    _runtime = null;
    _tokenizer = null;
    _index = null;
    _ready = false;
  }
}
