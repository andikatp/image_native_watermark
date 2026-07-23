package com.andikatp.image_native_watermark

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Typeface
import android.graphics.YuvImage
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream

class ImageNativeWatermarkPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "image_native_watermark")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    val mainHandler = Handler(Looper.getMainLooper())

    when (call.method) {
      "processFrame" -> {
        val bytes = call.argument<ByteArray>("bytes")!!
        val width = call.argument<Int>("width")!!
        val height = call.argument<Int>("height")!!
        val rotationAngle = call.argument<Int>("rotationAngle")!!
        val isFrontCamera = call.argument<Boolean>("isFrontCamera")!!
        val watermarkText = call.argument<String>("watermarkText")!!
        val quality = call.argument<Int>("quality")!!
        val targetMaxWidth = call.argument<Int>("targetMaxWidth")!!
        val outputPath = call.argument<String>("outputPath")!!

        Thread {
            try {
                val path = processFrame(
                    bytes, width, height, rotationAngle,
                    isFrontCamera, watermarkText, quality,
                    targetMaxWidth, outputPath
                )
                mainHandler.post { result.success(path) }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error(
                        "PROCESS_ERROR",
                        e.message,
                        e.stackTraceToString()
                    )
                }
            }
        }.start()
      }
      "processImageFile" -> {
        val bytes = call.argument<ByteArray>("bytes")!!
        val watermarkText = call.argument<String>("watermarkText")!!
        val quality = call.argument<Int>("quality")!!
        val targetMaxWidth = call.argument<Int>("targetMaxWidth")!!
        val outputPath = call.argument<String>("outputPath")!!

        Thread {
            try {
                val path = processImageFile(
                    bytes, watermarkText, quality,
                    targetMaxWidth, outputPath
                )
                mainHandler.post { result.success(path) }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error(
                        "PROCESS_ERROR",
                        e.message,
                        e.stackTraceToString()
                    )
                }
            }
        }.start()
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun processImageFile(
      imageBytes: ByteArray,
      watermarkText: String,
      quality: Int,
      targetMaxWidth: Int,
      outputPath: String
  ): String {
      var bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
          ?: throw IllegalArgumentException("Failed to decode image bytes")

      return renderAndSaveBitmap(bitmap, watermarkText, quality, targetMaxWidth, outputPath)
  }

  private fun processFrame(
      nv21Bytes: ByteArray,
      width: Int,
      height: Int,
      rotationAngle: Int,
      isFrontCamera: Boolean,
      watermarkText: String,
      quality: Int,
      targetMaxWidth: Int,
      outputPath: String
  ): String {
      val yuvImage = YuvImage(nv21Bytes, ImageFormat.NV21, width, height, null)
      val baos = ByteArrayOutputStream()
      yuvImage.compressToJpeg(Rect(0, 0, width, height), 100, baos)
      val jpegBytes = baos.toByteArray()
      var bitmap = BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.size)

      if (rotationAngle != 0 || isFrontCamera) {
          val matrix = Matrix()
          if (rotationAngle != 0) {
              matrix.postRotate(rotationAngle.toFloat())
          }
          if (isFrontCamera) {
              matrix.postScale(-1f, 1f)
          }
          val transformed = Bitmap.createBitmap(
              bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true
          )
          if (transformed !== bitmap) bitmap.recycle()
          bitmap = transformed
      }

      return renderAndSaveBitmap(bitmap, watermarkText, quality, targetMaxWidth, outputPath)
  }

  private fun renderAndSaveBitmap(
      inputBitmap: Bitmap,
      watermarkText: String,
      quality: Int,
      targetMaxWidth: Int,
      outputPath: String
  ): String {
      var bitmap = inputBitmap

      if (bitmap.width > targetMaxWidth) {
          val scale = targetMaxWidth.toFloat() / bitmap.width
          val newHeight = (bitmap.height * scale).toInt()
          val resized = Bitmap.createScaledBitmap(
              bitmap, targetMaxWidth, newHeight, true
          )
          if (resized !== bitmap) bitmap.recycle()
          bitmap = resized
      }

      if (watermarkText.isNotEmpty()) {
          val mutable = bitmap.copy(Bitmap.Config.ARGB_8888, true)
          bitmap.recycle()
          bitmap = mutable

          val canvas = Canvas(bitmap)
          val textPaint = Paint().apply {
              color = Color.WHITE
              textSize = 24f
              isAntiAlias = true
              typeface = Typeface.DEFAULT
          }
          val bgPaint = Paint().apply {
              color = Color.argb(51, 0, 0, 0) // ~0.2 alpha
          }

          val lines = watermarkText.split("\n")
              .map { it.trim() }
              .filter { it.isNotEmpty() }

          if (lines.isNotEmpty()) {
              var maxLineWidth = 0f
              var totalTextHeight = 0f
              val lineHeights = mutableListOf<Float>()

              for (line in lines) {
                  val textBounds = Rect()
                  textPaint.getTextBounds(line, 0, line.length, textBounds)
                  val lw = textPaint.measureText(line)
                  if (lw > maxLineWidth) {
                      maxLineWidth = lw
                  }
                  val lh = textBounds.height().toFloat()
                  lineHeights.add(lh)
                  totalTextHeight += lh + 8f
              }

              val x = 40f
              val yStart = bitmap.height * 0.7f
              
              val bgPadding = 15f
              canvas.drawRect(
                  x - bgPadding,
                  yStart - lineHeights[0] - bgPadding,
                  x + maxLineWidth + bgPadding,
                  yStart + totalTextHeight - 8f + bgPadding,
                  bgPaint
              )

              var currentY = yStart
              for (i in lines.indices) {
                  canvas.drawText(lines[i], x, currentY, textPaint)
                  currentY += lineHeights[i] + 8f
              }
          }
      }

      val file = File(outputPath)
      FileOutputStream(file).use { fos ->
          bitmap.compress(Bitmap.CompressFormat.JPEG, quality, fos)
      }
      bitmap.recycle()

      return outputPath
  }
}
