// Run from repo root after editing assets/launcher/iconapp.png:
//   dart run tool/gen_launcher_icons.dart
// Generates gradient adaptive background + opaque mipmap/Web source.

import 'dart:io';

import 'package:image/image.dart';

/// Slight zoom so launcher masks do not show empty bands at the edges.
const _kForegroundZoom = 1.14;

const _launcherDir = 'assets/launcher';

int _clamp255(num v) => v.round().clamp(0, 255).toInt();

/// Scale up then center-crop back to [src] size (fills adaptive / mipmap silhouettes).
Image _zoomCenterCrop(Image src) {
  final w = src.width;
  final h = src.height;
  final zw = (w * _kForegroundZoom).round();
  final zh = (h * _kForegroundZoom).round();
  final big = copyResize(
    src,
    width: zw,
    height: zh,
    interpolation: Interpolation.linear,
  );
  final x = (zw - w) ~/ 2;
  final y = (zh - h) ~/ 2;
  return copyCrop(big, x: x, y: y, width: w, height: h);
}

void _fillHorizontalGradient(Image im, Color left, Color right) {
  final w = im.width;
  final h = im.height;
  final lr = _clamp255(left.r);
  final lg = _clamp255(left.g);
  final lb = _clamp255(left.b);
  final rr = _clamp255(right.r);
  final rg = _clamp255(right.g);
  final rb = _clamp255(right.b);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final t = w <= 1 ? 0.0 : x / (w - 1);
      final r = _clamp255(lr + (rr - lr) * t);
      final g = _clamp255(lg + (rg - lg) * t);
      final b = _clamp255(lb + (rb - lb) * t);
      im.setPixelRgba(x, y, r, g, b, 255);
    }
  }
}

Color? _firstOpaqueRgb(Image src, int y, {required bool scanLeft}) {
  final w = src.width;
  if (scanLeft) {
    for (var x = 0; x < w; x++) {
      final p = src.getPixel(x, y);
      if (p.a >= 128) return p;
    }
  } else {
    for (var x = w - 1; x >= 0; x--) {
      final p = src.getPixel(x, y);
      if (p.a >= 128) return p;
    }
  }
  return null;
}

void main() {
  final root = Directory.current.path;
  final srcFile = File('$root/$_launcherDir/iconapp.png');
  if (!srcFile.existsSync()) {
    stderr.writeln('Missing ${srcFile.path}');
    exitCode = 1;
    return;
  }

  final src = decodePng(srcFile.readAsBytesSync());
  if (src == null) {
    stderr.writeln('Could not decode ${srcFile.path}');
    exitCode = 1;
    return;
  }

  final w = src.width;
  final h = src.height;
  final cy = h ~/ 2;

  final left = _firstOpaqueRgb(src, cy, scanLeft: true);
  final right = _firstOpaqueRgb(src, cy, scanLeft: false);
  final l = left ?? ColorUint8.rgba(30, 64, 175, 255);
  final r = right ?? ColorUint8.rgba(123, 31, 162, 255);

  final zoomed = _zoomCenterCrop(src);

  final grad = Image(width: w, height: h, numChannels: 4);
  _fillHorizontalGradient(grad, l, r);
  File('$root/$_launcherDir/iconapp_adaptive_gradient_bg.png')
      .writeAsBytesSync(encodePng(grad));

  File('$root/$_launcherDir/iconapp_foreground_launcher.png')
      .writeAsBytesSync(encodePng(zoomed));

  final merged = grad.clone();
  compositeImage(merged, zoomed, blend: BlendMode.alpha);
  File('$root/$_launcherDir/iconapp_legacy_mipmap.png')
      .writeAsBytesSync(encodePng(merged));

  stdout.writeln(
    'OK: $_launcherDir/iconapp_adaptive_gradient_bg.png, '
    'iconapp_foreground_launcher.png, iconapp_legacy_mipmap.png',
  );
}
