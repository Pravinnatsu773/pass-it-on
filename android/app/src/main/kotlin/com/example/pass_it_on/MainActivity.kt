package com.example.pass_it_on

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.example.pass_it_on/gemma"
    private val EVENT_CHANNEL = "com.example.pass_it_on/gemma_stream"
    
    private var llmInference: LlmInference? = null
    private var eventSink: EventChannel.EventSink? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val modelName = call.argument<String>("modelName") ?: "gemma-2b-it-gpu-int4.bin"
                    initializeModel(modelName, result)
                }
                "generateResponse" -> {
                    val prompt = call.argument<String>("prompt")
                    if (prompt != null) {
                        generateResponse(prompt, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Prompt cannot be null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun initializeModel(modelName: String, result: MethodChannel.Result) {
        if (llmInference != null) {
            result.success(true)
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                // MediaPipe LLM Inference currently requires an absolute file path. 
                // We copy the asset to the internal storage cache directory to get an absolute path.
                val modelFile = File(context.cacheDir, modelName)
                if (!modelFile.exists()) {
                    copyAssetToFile(modelName, modelFile)
                }

                val options = LlmInference.LlmInferenceOptions.builder()
                    .setModelPath(modelFile.absolutePath)
                    .setMaxTokens(512)
                    .setTemperature(0.8f)
                    .setTopK(40)
                    .setResultListener { partialResult, done ->
                        CoroutineScope(Dispatchers.Main).launch {
                            if (partialResult != null) {
                                eventSink?.success(partialResult)
                            }
                            if (done) {
                                eventSink?.success("[DONE]")
                            }
                        }
                    }
                    .build()

                llmInference = LlmInference.createFromOptions(context, options)

                withContext(Dispatchers.Main) {
                    result.success(true)
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error initializing Gemma model", e)
                withContext(Dispatchers.Main) {
                    result.error("INIT_FAILED", e.message, null)
                }
            }
        }
    }

    private fun generateResponse(prompt: String, result: MethodChannel.Result) {
        if (llmInference == null) {
            result.error("NOT_INITIALIZED", "LlmInference is not initialized.", null)
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                // Async generation emits to the event sink configured during initialization.
                llmInference?.generateResponseAsync(prompt)
                withContext(Dispatchers.Main) {
                    result.success(true)
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error generating response", e)
                withContext(Dispatchers.Main) {
                    result.error("GENERATE_FAILED", e.message, null)
                }
            }
        }
    }

    private fun copyAssetToFile(assetName: String, outputFile: File) {
        context.assets.open(assetName).use { inputStream ->
            FileOutputStream(outputFile).use { outputStream ->
                val buffer = ByteArray(1024 * 1024)
                var read: Int
                while (inputStream.read(buffer).also { read = it } != -1) {
                    outputStream.write(buffer, 0, read)
                }
                outputStream.flush()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        llmInference?.close()
        llmInference = null
    }
}
