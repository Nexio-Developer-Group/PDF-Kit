// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:pdf_kit/service/signature_service.dart';

// class PlaceSignatureOnPdfPage extends StatefulWidget {
//   const PlaceSignatureOnPdfPage({
//     super.key,
//     required this.fileBytes,
//     required this.fileName,
//     required this.signatureBytes,
//     this.isPdf = true,
//   });

//   final Uint8List fileBytes;
//   final String fileName;
//   final Uint8List signatureBytes;
//   final bool isPdf;

//   @override
//   State<PlaceSignatureOnPdfPage> createState() =>
//       _PlaceSignatureOnPdfPageState();
// }

// class _PlaceSignatureOnPdfPageState extends State<PlaceSignatureOnPdfPage> {
//   Uint8List? _previewImage; // rendered page/image for preview
//   bool _loading = true;
//   bool _saving = false;

//   // Signature position and size as fractions of the page size.
//   double _sigLeftFrac = 0.15;
//   double _sigTopFrac = 0.80;
//   double _sigWidthFrac = 0.35;

//   // Actual widget size for mapping UI → PDF.
//   double _lastPageWidth = 1;
//   double _lastPageHeight = 1;

//   @override
//   void initState() {
//     super.initState();
//     _loadPreview();
//   }

//   Future<void> _loadPreview() async {
//     if (widget.isPdf) {
//       // Load PDF and render first page
//       final result = await SignatureService.loadPdfAsImage(widget.fileBytes);
//       result.fold(
//         (error) {
//           if (mounted) {
//             ScaffoldMessenger.of(
//               context,
//             ).showSnackBar(SnackBar(content: Text(error.message)));
//             Navigator.of(context).pop();
//           }
//         },
//         (pageImage) {
//           setState(() {
//             _previewImage = pageImage.bytes;
//             _loading = false;
//           });
//         },
//       );
//     } else {
//       // For images, use directly
//       setState(() {
//         _previewImage = widget.fileBytes;
//         _loading = false;
//       });
//     }
//   }

//   // Helper to get absolute px from fraction.
//   double _sigLeftPx() => _sigLeftFrac * _lastPageWidth;
//   double _sigTopPx() => _sigTopFrac * _lastPageHeight;
//   double _sigWidthPx() => _sigWidthFrac * _lastPageWidth;

//   void _updateFromDrag(DragUpdateDetails details) {
//     setState(() {
//       _sigLeftFrac += details.delta.dx / _lastPageWidth;
//       _sigTopFrac += details.delta.dy / _lastPageHeight;

//       // Keep inside [0,1] range.
//       _sigLeftFrac = _sigLeftFrac.clamp(0.0, 1.0 - _sigWidthFrac);
//       _sigTopFrac = _sigTopFrac.clamp(0.0, 1.0);
//     });
//   }

//   Future<void> _onSave() async {
//     if (_previewImage == null || _saving) return;

//     setState(() => _saving = true);

//     try {
//       late Uint8List signedBytes;

//       if (widget.isPdf) {
//         // For PDF, load again to get PdfPageImage
//         final result = await SignatureService.loadPdfAsImage(widget.fileBytes);
//         final success = result.fold(
//           (error) {
//             throw Exception(error.message);
//           },
//           (pageImage) {
//             return pageImage;
//           },
//         );

//         signedBytes = await SignatureService.buildSignedPdfBytes(
//           pageImage: success,
//           signatureBytes: widget.signatureBytes,
//           sigLeftFrac: _sigLeftFrac,
//           sigTopFrac: _sigTopFrac,
//           sigWidthFrac: _sigWidthFrac,
//         );
//       } else {
//         // For images
//         signedBytes = await SignatureService.buildSignedImageBytes(
//           imageBytes: widget.fileBytes,
//           signatureBytes: widget.signatureBytes,
//           sigLeftFrac: _sigLeftFrac,
//           sigTopFrac: _sigTopFrac,
//           sigWidthFrac: _sigWidthFrac,
//         );
//       }

//       // Save and open the signed file
//       final saveResult = await SignatureService.saveAndOpenSignedFile(
//         bytes: signedBytes,
//         originalFileName: widget.fileName,
//         isPdf: widget.isPdf,
//       );

//       if (!mounted) return;

//       saveResult.fold(
//         (error) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(error.message),
//               backgroundColor: Theme.of(context).colorScheme.error,
//             ),
//           );
//         },
//         (fileInfo) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Signed file saved: ${fileInfo.name}'),
//               backgroundColor: Colors.green,
//             ),
//           );
//           Navigator.of(context).pop(true); // Success
//         },
//       );
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: $e'),
//             backgroundColor: Theme.of(context).colorScheme.error,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       backgroundColor: const Color(0xFF121212),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF121212),
//         elevation: 0,
//         title: const Text('Add Digital Signature'),
//       ),
//       body: _loading || _previewImage == null
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Expanded(
//                   child: LayoutBuilder(
//                     builder: (context, constraints) {
//                       final maxWidth = constraints.maxWidth - 32;
//                       final maxHeight = constraints.maxHeight - 160;

//                       double width = maxWidth;
//                       double height = maxHeight;

//                       _lastPageWidth = width;
//                       _lastPageHeight = height;

//                       return Center(
//                         child: SizedBox(
//                           width: width,
//                           height: height,
//                           child: Stack(
//                             children: [
//                               Positioned.fill(
//                                 child: DecoratedBox(
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFF1F1F1F),
//                                     borderRadius: BorderRadius.circular(16),
//                                   ),
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(16),
//                                     child: Image.memory(
//                                       _previewImage!,
//                                       fit: BoxFit.contain,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: _sigLeftPx(),
//                                 top: _sigTopPx(),
//                                 child: GestureDetector(
//                                   onPanUpdate: _updateFromDrag,
//                                   child: Image.memory(
//                                     widget.signatureBytes,
//                                     width: _sigWidthPx(),
//                                   ),
//                                 ), // Draggable signature overlay in Stack. [web:27][web:29][web:31]
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   'Page 1 of 1',
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     color: Colors.white70,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: () => Navigator.of(context).pop(),
//                           style: OutlinedButton.styleFrom(
//                             foregroundColor: Colors.white70,
//                             side: const BorderSide(color: Colors.white24),
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                           ),
//                           child: const Text('Cancel'),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: _saving ? null : _onSave,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF2962FF),
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(24),
//                             ),
//                           ),
//                           child: _saving
//                               ? const SizedBox(
//                                   height: 20,
//                                   width: 20,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     color: Colors.white,
//                                   ),
//                                 )
//                               : const Text('Save'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }
