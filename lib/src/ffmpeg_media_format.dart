import 'package:sounds_common/sounds_common.dart';

import 'ffmpeg_util.dart';

/// Base class for [MediaFormat] utilising the FFMpeg library.
abstract class FFMpegMediaFormat extends MediaFormat {
  @override
  Future<Duration> getDuration(String path) {
    return FFMpegUtil().duration(path);
  }

  @override
  Future<bool> get isNativeDecoder => Future.value(false);

  @override
  Future<bool> get isNativeEncoder => Future.value(false);
}
