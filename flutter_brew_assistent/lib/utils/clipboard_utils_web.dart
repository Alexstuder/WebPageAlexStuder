import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:js_util' as js_util;
import 'package:web/web.dart' as web;

Future<void> copyImageToClipboard(Uint8List bytes) async {
  try {
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'image/png'));
    
    // Create a plain JS object for the mapping
    final itemData = js_util.newObject();
    js_util.setProperty(itemData, 'image/png', blob);
    
    final clipboardItem = web.ClipboardItem(itemData as JSObject);
    
    await web.window.navigator.clipboard.write([clipboardItem].toJS).toDart;
  } catch (e) {
    print('Web Clipboard Error: $e');
    rethrow;
  }
}
