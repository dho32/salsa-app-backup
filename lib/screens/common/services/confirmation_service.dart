import 'package:hive/hive.dart';
import 'package:salsa/components/constants.dart';
import '../../../blocs/service/service_repository.dart';
import '../../../models/task_maintenance/confirmation_task_queue.dart';

class ConfirmationService {
  final _repository = ServiceTaskRepository();
  static const _maxRetries = 5; // Batas percobaan ulang

  Future<void> processQueue() async {
    final box =
        await Hive.openBox<ConfirmationTaskModel>(kConfirmationQueueBox);
    if (box.isEmpty) return; // Tidak ada tugas, selesai.

    // Ambil semua kunci agar aman saat menghapus di dalam loop
    final List<dynamic> keys = box.keys.toList();

    for (var key in keys) {
      final task = box.get(key);
      if (task == null) continue;

      try {
        final result = await _repository.confirmUploadSuccess(task.transNo);

        if (result['status'] == 'OK') {
          await box.delete(key); // Hapus jika berhasil
        } else {
          _handleFailure(box, key, task);
        }
      } catch (e) {
        _handleFailure(box, key, task);
      }
    }
  }

  void _handleFailure(
      Box<ConfirmationTaskModel> box, dynamic key, ConfirmationTaskModel task) {
    print(
        "ConfirmationService: Konfirmasi untuk ${task.transNo} GAGAL. Percobaan ke-${task.retryCount + 1}");
    if (task.retryCount + 1 >= _maxRetries) {
      print(
          "ConfirmationService: Batas percobaan ulang untuk ${task.transNo} tercapai. Menghapus tugas.");
      box.delete(key); // Hapus jika sudah terlalu banyak gagal
    } else {
      task.retryCount++;
      box.put(key, task); // Simpan kembali dengan retryCount yang diperbarui
    }
  }
}
