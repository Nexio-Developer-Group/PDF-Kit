// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:pdf_kit/presentation/pages/place_signature.dart';
// import 'package:signature/signature.dart';

// class AddSignaturePage extends StatefulWidget {
//   const AddSignaturePage({
//     super.key,
//     required this.fileBytes,
//     required this.fileName,
//     this.isPdf = true,
//   });

//   final Uint8List fileBytes;
//   final String fileName;
//   final bool isPdf;

//   @override
//   State<AddSignaturePage> createState() => _AddSignaturePageState();
// }

// class _AddSignaturePageState extends State<AddSignaturePage> {
//   late final SignatureController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = SignatureController(
//       penStrokeWidth: 3,
//       penColor: Colors.white,
//       exportBackgroundColor: Colors.transparent,
//     ); // Controller config based on package docs. [web:5][web:6]
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   Future<void> _onContinue() async {
//     if (_controller.isEmpty) return;

//     final Uint8List? signatureBytes = await _controller.toPngBytes();
//     // signature.toPngBytes() is the standard export method. [web:5][web:6]

//     if (signatureBytes == null) return;

//     if (!mounted) return;

//     final result = await Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (_) => PlaceSignatureOnPdfPage(
//           fileBytes: widget.fileBytes,
//           fileName: widget.fileName,
//           signatureBytes: signatureBytes,
//           isPdf: widget.isPdf,
//         ),
//       ),
//     );

//     // If successfully signed, pop with true
//     if (result == true && mounted) {
//       Navigator.of(context).pop(true);
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
//       body: Column(
//         children: [
//           const SizedBox(height: 16),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1F1F1F),
//                 borderRadius: BorderRadius.circular(24),
//               ),
//               child: Text(
//                 'Draw your signature or add from the library',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: Colors.white70,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24.0),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF1F1F1F),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(16),
//                   child: Signature(
//                     controller: _controller,
//                     backgroundColor: const Color(0xFF1F1F1F),
//                   ), // Signature canvas from the package. [web:5][web:6]
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.white70,
//                       side: const BorderSide(color: Colors.white24),
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                     ),
//                     child: const Text('Cancel'),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _controller.isEmpty ? null : _onContinue,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF2962FF),
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(24),
//                       ),
//                     ),
//                     child: const Text('Continue'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
