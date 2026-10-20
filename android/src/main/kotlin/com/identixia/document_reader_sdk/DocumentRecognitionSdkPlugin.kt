package com.identixia.document_reader_sdk


import android.os.Handler
import android.os.Looper
import android.graphics.Bitmap
import android.graphics.Matrix
import com.identixia.documentrecognitionsdk.DocumentRecognitionSDK
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors


/** Flutter port of RN DocumentRecognitionSdkModule. */
class DocumentRecognitionSdkPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private var appContext: android.content.Context? = null
  private val executor = Executors.newSingleThreadExecutor()
  private val mainHandler = Handler(Looper.getMainLooper())


  private fun success(result: Result, value: Any?) {
    mainHandler.post { result.success(value) }
  }


  private fun error(result: Result, code: String, message: String?) {
    mainHandler.post { result.error(code, message, null) }
  }


  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "DocumentRecognitionSdk")
    channel.setMethodCallHandler(this)
  }


  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    appContext = null
  }


  override fun onMethodCall(call: MethodCall, result: Result) {
    val context = appContext
    if (context == null) {
      result.error("E_CONTEXT", "Plugin not attached", null)
      return
    }


    when (call.method) {
      "getMachineCode" -> executor.execute {
        try {
          success(result, DocumentRecognitionSDK.getMachineCode(context) ?: "")
        } catch (t: Throwable) {
          error(result, "E_MACHINE_CODE", t.message)
        }
      }
      "setActivation" -> {
        val license = call.arguments as? String ?: ""
        executor.execute {
          try {
            success(result, DocumentRecognitionSDK.setActivation(context, license))
          } catch (t: Throwable) {
            error(result, "E_ACTIVATION", t.message)
          }
        }
      }
      "init", "initSDK" -> executor.execute {
        try {
          success(result, DocumentRecognitionSDK.init(context))
        } catch (t: Throwable) {
          error(result, "E_INIT", t.message)
        }
      }
      "deinit", "deinitSDK" -> executor.execute {
        try {
          DocumentRecognitionSDK.deinit()
          success(result, null)
        } catch (t: Throwable) {
          error(result, "E_DEINIT", t.message)
        }
      }
      "startNewSession" -> {
        val optionsJson = call.arguments as? String
        executor.execute {
          try {
            val json = if (optionsJson.isNullOrBlank()) {
              DocumentRecognitionSDK.startNewSession()
            } else {
              DocumentRecognitionSDK.startNewSession(optionsJson)
            }
            success(result, json)
          } catch (t: Throwable) {
            error(result, "E_SESSION", t.message)
          }
        }
      }
      "locateDocument" -> {
        val args = when (val raw = call.arguments) {
          is Map<*, *> -> raw
          is String -> mapOf("image" to raw)
          else -> emptyMap<String, Any?>()
        }
        val imageUri = args["image"] as? String ?: ""
        val alreadyCropped = (args["alreadyCropped"] as? Boolean) == true
        executor.execute {
          try {
            val bitmap = loadBitmap(context, imageUri)
              ?: run {
                error(result, "E_IMAGE", "Could not decode image: $imageUri")
                return@execute
              }
            // Live scores need uprightPortrait on the guide crop (same as pre-camera-OCR fix).
            val upright = uprightPortrait(bitmap)
            val locateBmp = scaleMax(upright, LOCATE_MAX_EDGE)
            val json = DocumentRecognitionSDK.locateDocument(locateBmp)
            success(
              result,
              rescaleLocateJson(
                json,
                locateBmp.width,
                locateBmp.height,
                upright.width,
                upright.height
              )
            )
          } catch (t: Throwable) {
            error(result, "E_LOCATE", t.message)
          }
        }
      }
      "recognize" -> {
        val args = call.arguments as? Map<*, *>
        val frontUri = args?.get("front") as? String ?: ""
        val backUri = args?.get("back") as? String
        val authenticityMode = (args?.get("authenticityMode") as? String)
            ?: if ((args?.get("authenticity") as? Boolean) == false) "none" else "normal"
        val alreadyCropped = (args?.get("alreadyCropped") as? Boolean) == true
        executor.execute {
          try {
            val frontRaw = loadBitmap(context, frontUri)
              ?: run {
                error(result, "E_IMAGE", "Could not decode front image: $frontUri")
                return@execute
              }
            val front = prepareStillBitmap(frontRaw, alreadyCropped)
            val back: Bitmap? =
              if (backUri.isNullOrBlank()) {
                null
              } else {
                loadBitmap(context, backUri)?.let { prepareStillBitmap(it, alreadyCropped) }
              }
            // Liveness product: authenticity / PAD path uses FullAuth.
            DocumentRecognitionSDK.startNewSession("{\"scenario\":\"FullAuth\",\"series\":false}")
            val json = DocumentRecognitionSDK.recognize(front, back, authenticityMode, alreadyCropped)
            success(result, json)
          } catch (t: Throwable) {
            error(result, "E_RECOGNIZE", t.message)
          }
        }
      }
      "documentRecognition", "documentLiveness" -> {
        val args = call.arguments as? Map<*, *>
        val frontUri = args?.get("front") as? String ?: ""
        val backUri = args?.get("back") as? String
        val alreadyCropped = (args?.get("alreadyCropped") as? Boolean) == true
        val livenessOnly = call.method == "documentLiveness"
        executor.execute {
          try {
            val frontRaw = loadBitmap(context, frontUri)
              ?: run {
                error(result, "E_IMAGE", "Could not decode front image: $frontUri")
                return@execute
              }
            val front = prepareStillBitmap(frontRaw, alreadyCropped)
            val back: Bitmap? =
              if (backUri.isNullOrBlank()) {
                null
              } else {
                loadBitmap(context, backUri)?.let { prepareStillBitmap(it, alreadyCropped) }
              }
            val scenario =
              if (livenessOnly) "{\"scenario\":\"FullAuth\",\"series\":false}"
              else "{\"scenario\":\"FullProcess\",\"series\":false}"
            DocumentRecognitionSDK.startNewSession(scenario)
            val json =
              if (livenessOnly) DocumentRecognitionSDK.documentLiveness(front, back, alreadyCropped)
              else DocumentRecognitionSDK.documentRecognition(front, back, alreadyCropped)
            success(result, json)
          } catch (t: Throwable) {
            error(result, if (livenessOnly) "E_LIVENESS" else "E_RECOGNITION", t.message)
          }
        }
      }

      "documentProcess" -> {
        val args = call.arguments as? Map<*, *>
        val imagesJson = args?.get("imagesJson") as? String ?: args?.get("images") as? String ?: "[]"
        val rfidJson = args?.get("rfidJson") as? String ?: args?.get("rfid") as? String ?: ""
        val optionsJson = args?.get("optionsJson") as? String ?: args?.get("options") as? String ?: "{}"
        executor.execute {
          try {
            success(result, DocumentRecognitionSDK.documentProcess(imagesJson, rfidJson, optionsJson))
          } catch (t: Throwable) {
            error(result, "E_DOCUMENT_PROCESS", t.message)
          }
        }
      }
      "faceLiveness" -> {
        val args = call.arguments as? Map<*, *>
        val imageUri = args?.get("image") as? String ?: args?.get("portrait") as? String ?: ""
        val mode = (args?.get("mode") as? Number)?.toInt() ?: 0
        executor.execute {
          try {
            val bitmap = loadBitmap(context, imageUri)
              ?: run {
                error(result, "E_IMAGE", "Could not decode portrait: $imageUri")
                return@execute
              }
            success(result, DocumentRecognitionSDK.faceLiveness(bitmap, mode))
          } catch (t: Throwable) {
            error(result, "E_FACE_LIVENESS", t.message)
          }
        }
      }
      "lastLicenseError" -> {
        try {
          result.success(DocumentRecognitionSDK.lastLicenseError() ?: "")
        } catch (t: Throwable) {
          error(result, "E_LICENSE_ERROR", t.message)
        }
      }
      "getLicenseStatus" -> {
        try {
          result.success(DocumentRecognitionSDK.getLicenseStatus() ?: "{}")
        } catch (t: Throwable) {
          error(result, "E_LICENSE_STATUS", t.message)
        }
      }
      "writeStatus" -> {
        val json = call.arguments as? String ?: "{}"
        try {
          val file = java.io.File(context.filesDir, "docreader_status.json")
          file.writeText(json)
          success(result, null)
        } catch (t: Throwable) {
          error(result, "E_STATUS", t.message)
        }
      }
      else -> result.notImplemented()
    }
  }


  private fun loadBitmap(context: android.content.Context, uriOrBase64: String): Bitmap? {
    return if (uriOrBase64.startsWith("data:") || looksLikeBase64(uriOrBase64)) {
      ImageUtils.bitmapFromBase64(uriOrBase64)
    } else {
      ImageUtils.bitmapFromUri(context, uriOrBase64)
    }
  }


  private fun looksLikeBase64(value: String): Boolean {
    return value.length > 256 &&
      !value.contains("://") &&
      !value.startsWith("/") &&
      !value.startsWith("file:")
  }


  /** Camera guide crops are landscape ID-1 packs — upright when alreadyCropped is false (match native). */
  private fun prepareStillBitmap(src: Bitmap, alreadyCropped: Boolean): Bitmap {
    return if (alreadyCropped) src else uprightPortrait(src)
  }

  private fun uprightPortrait(src: Bitmap): Bitmap {
    if (src.width <= src.height) return src
    val matrix = Matrix().apply { postRotate(90f) }
    return Bitmap.createBitmap(src, 0, 0, src.width, src.height, matrix, true)
  }


  private fun scaleMax(src: Bitmap, maxEdge: Int): Bitmap {
    val longest = maxOf(src.width, src.height)
    if (longest <= maxEdge) return src
    val scale = maxEdge.toFloat() / longest
    return Bitmap.createScaledBitmap(
      src,
      (src.width * scale).toInt().coerceAtLeast(1),
      (src.height * scale).toInt().coerceAtLeast(1),
      true
    )
  }


  private fun rescaleLocateJson(
    json: String,
    locateW: Int,
    locateH: Int,
    imageW: Int,
    imageH: Int
  ): String {
    if (json.isEmpty()) return json
    return try {
      val root = org.json.JSONObject(json)
      root.put("_locateImageWidth", imageW)
      root.put("_locateImageHeight", imageH)
      val pos = root.optJSONObject("position") ?: return root.toString()
      val sx = imageW.toFloat() / locateW.coerceAtLeast(1)
      val sy = imageH.toFloat() / locateH.coerceAtLeast(1)
      val corners = pos.optJSONArray("corners")
      if (corners != null && corners.length() >= 4) {
        for (i in 0 until corners.length()) {
          val p = corners.optJSONObject(i) ?: continue
          p.put("x", p.optDouble("x") * sx)
          p.put("y", p.optDouble("y") * sy)
        }
      } else {
        if (pos.has("left")) pos.put("left", pos.optDouble("left") * sx)
        if (pos.has("top")) pos.put("top", pos.optDouble("top") * sy)
        if (pos.has("right")) pos.put("right", pos.optDouble("right") * sx)
        if (pos.has("bottom")) pos.put("bottom", pos.optDouble("bottom") * sy)
      }
      root.toString()
    } catch (_: Throwable) {
      json
    }
  }


  companion object {
    private const val LOCATE_MAX_EDGE = 480
  }
}
