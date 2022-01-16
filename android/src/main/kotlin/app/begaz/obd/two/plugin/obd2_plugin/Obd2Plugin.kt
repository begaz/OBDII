package app.begaz.obd.two.plugin.obd2_plugin

import android.bluetooth.BluetoothAdapter
import android.content.Intent
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat.startActivityForResult

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import android.bluetooth.BluetoothManager

import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.activity.ActivityAware


/** Obd2Plugin */
class Obd2Plugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var activity: Activity
  private var bluetoothAdapter: BluetoothAdapter? = null
  private val REQUEST_ENABLE_BLUETOOTH: Int = 1337
  private val REQUEST_DISCOVERABLE_BLUETOOTH: Int = 2137

  private var pendingResultForActivityResult: Result? = null

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
      this.activity = binding.activity;
      val bluetoothManager: BluetoothManager = activity.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager


      this.bluetoothAdapter = bluetoothManager.adapter

      binding.addActivityResultListener { requestCode, resultCode, data ->
          when (requestCode) {
              REQUEST_ENABLE_BLUETOOTH -> {
                  if (pendingResultForActivityResult != null) {
                      pendingResultForActivityResult?.success(resultCode != 0)
                  }
                  return@addActivityResultListener true
              }
              REQUEST_DISCOVERABLE_BLUETOOTH -> {
                  pendingResultForActivityResult?.success(if (resultCode == 0) -1 else resultCode)
                  return@addActivityResultListener true
              }
              else -> return@addActivityResultListener false
          }
      }
  }

    override fun onDetachedFromActivityForConfigChanges() {

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {

    }

    override fun onDetachedFromActivity() {

    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "obd2_plugin")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
        "enableBluetooth" -> {
            if (bluetoothAdapter?.isEnabled != true) {
                pendingResultForActivityResult = result
                val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                startActivityForResult(activity, intent, REQUEST_ENABLE_BLUETOOTH, null)
            } else {
                result.success(true)
            }

//          result.success("Android ${android.os.Build.VERSION.RELEASE}")
        }
        "getPlatformVersion" -> {
          result.success("Android ${android.os.Build.VERSION.RELEASE}")
        }
        else -> {
          result.notImplemented()
        }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
