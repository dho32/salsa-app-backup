import 'package:hive/hive.dart';
import 'captured_image_detail.dart';

abstract class IPicPhotoStorable extends HiveObject {
  CapturedImageDetail? get picImageDetail;
  set picImageDetail(CapturedImageDetail? photo);

  String get transNo;
}