import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

class RepaintBoundaryPage extends StatefulWidget {
  const RepaintBoundaryPage({Key? key}) : super(key: key);

  @override
  State<RepaintBoundaryPage> createState() => _RepaintBoundaryPageState();
}

class _RepaintBoundaryPageState extends State<RepaintBoundaryPage> {
  final GlobalKey _repaintKey = GlobalKey();

  Future<void> _capturePng() async {
    try {
      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        // Do something with the PNG bytes (byteData.buffer.asUint8List())
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Screenshot captured!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RepaintBoundary Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              key: _repaintKey,
              child: Container(
                color: Colors.amber,
                width: 200,
                height: 200,
                child: const Center(
                  child: Text(
                    'Capture Me!',
                    style: TextStyle(fontSize: 24, color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _capturePng,
              child: const Text('Capture Screenshot'),
            ),
          ],
        ),
      ),
    );
  }
}