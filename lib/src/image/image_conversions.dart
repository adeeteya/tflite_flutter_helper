import 'package:image/image.dart';
import 'package:tflite_flutter_helper/src/common/tflitetypehelper.dart';
import 'package:tflite_flutter_helper/src/image/color_space_type.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

/// Implements some stateless image conversion methods.
///
/// This class is an internal helper.
class ImageConversions {
  static Image convertRgbTensorBufferToImage(TensorBuffer buffer) {
    List<int> shape = buffer.getShape();
    ColorSpaceType rgb = ColorSpaceType.RGB;
    rgb.assertShape(shape);

    int h = rgb.getHeight(shape);
    int w = rgb.getWidth(shape);
    Image image = Image(width: w, height: h);

    List<int> rgbValues = buffer.getIntList();
    assert(rgbValues.length == w * h * 3);

    for (int i = 0, j = 0, wi = 0, hi = 0; j < rgbValues.length; i++) {
      int r = rgbValues[j++];
      int g = rgbValues[j++];
      int b = rgbValues[j++];
      image.setPixelRgb(wi, hi, r, g, b);
      wi++;
      if (wi % w == 0) {
        wi = 0;
        hi++;
      }
    }

    return image;
  }

  static Image convertGrayscaleTensorBufferToImage(TensorBuffer buffer) {
    // Convert buffer into Uint8 as needed.
    TensorBuffer uint8Buffer = buffer.getDataType() == TfLiteTypeHelper.uint8
        ? buffer
        : TensorBuffer.createFrom(buffer, TfLiteTypeHelper.uint8);

    final shape = uint8Buffer.getShape();
    final grayscale = ColorSpaceType.GRAYSCALE;
    grayscale.assertShape(shape);

    final image = Image.fromBytes(
      width: grayscale.getWidth(shape),
      height: grayscale.getHeight(shape),
      bytes: uint8Buffer.getBuffer(),
    );

    return image;
  }

  static void convertImageToTensorBuffer(Image image, TensorBuffer buffer) {
    int w = image.width;
    int h = image.height;
    int flatSize = w * h * 3;
    List<int> shape = [h, w, 3];

    switch (buffer.getDataType()) {
      case TfLiteTypeHelper.uint8:
        List<int> byteArr = List.filled(flatSize, 0);
        int index = 0;
        for (int y = 0; y < h; y++) {
          for (int x = 0; x < w; x++) {
            final pixel = image.getPixel(x, y); // RGBA 32-bit
            byteArr[index++] = pixel.r.toInt();
            byteArr[index++] = pixel.g.toInt();
            byteArr[index++] = pixel.b.toInt();
          }
        }
        buffer.loadList(byteArr, shape: shape);
        break;

      case TfLiteTypeHelper.float32:
        List<double> floatArr = List.filled(flatSize, 0.0);
        int index = 0;
        for (int y = 0; y < h; y++) {
          for (int x = 0; x < w; x++) {
            final pixel = image.getPixel(x, y);
            floatArr[index++] = pixel.r.toDouble();
            floatArr[index++] = pixel.g.toDouble();
            floatArr[index++] = pixel.b.toDouble();
          }
        }
        buffer.loadList(floatArr, shape: shape);
        break;

      default:
        throw StateError(
            "${buffer.getDataType()} is unsupported with TensorBuffer.");
    }
  }
}
