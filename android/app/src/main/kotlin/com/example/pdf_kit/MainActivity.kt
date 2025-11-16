package com.example.pdf_kit

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.itextpdf.kernel.pdf.PdfDocument
import com.itextpdf.kernel.pdf.PdfReader
import com.itextpdf.kernel.pdf.PdfWriter
import com.itextpdf.kernel.pdf.WriterProperties
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.pdf_kit/pdf_protection"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "protectPdf" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val outputPath = call.argument<String>("outputPath")
                    val password = call.argument<String>("password")

                    if (inputPath == null || outputPath == null || password == null) {
                        result.error(
                            "INVALID_ARGS",
                            "Missing required arguments",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        val protectedPath = protectPdfFile(
                            inputPath,
                            outputPath,
                            password
                        )
                        result.success(protectedPath)
                    } catch (e: Exception) {
                        result.error(
                            "PROTECTION_ERROR",
                            e.message,
                            null
                        )
                    }
                }
                
                "isPdfProtected" -> {
                    val pdfPath = call.argument<String>("pdfPath")
                    if (pdfPath == null) {
                        result.error(
                            "INVALID_ARGS",
                            "Missing PDF path",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        val isProtected = checkIfPdfProtected(pdfPath)
                        result.success(isProtected)
                    } catch (e: Exception) {
                        result.error(
                            "CHECK_ERROR",
                            e.message,
                            null
                        )
                    }
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun protectPdfFile(
        inputPath: String,
        outputPath: String,
        password: String
    ): String {
        val inputFile = File(inputPath)
        if (!inputFile.exists()) {
            throw Exception("Input PDF file not found")
        }

        val reader = PdfReader(inputPath)
        
        val writerProperties = WriterProperties()
            .setStandardEncryption(
                password.toByteArray(),
                password.toByteArray(),
                0,
                WriterProperties.ENCRYPTION_AES_256
            )
        
        val writer = PdfWriter(outputPath, writerProperties)
        val pdfDoc = PdfDocument(reader, writer)
        pdfDoc.close()

        return outputPath
    }

    private fun checkIfPdfProtected(pdfPath: String): Boolean {
        return try {
            val reader = PdfReader(pdfPath)
            val pdfDoc = PdfDocument(reader)
            val isEncrypted = pdfDoc.reader.isEncrypted
            pdfDoc.close()
            isEncrypted
        } catch (e: Exception) {
            true
        }
    }
}
