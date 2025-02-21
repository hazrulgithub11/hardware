package com.example.hardwarelab

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.FirebaseApp

class MainActivity : FlutterActivity() {

    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private val pairedDevices: Set<BluetoothDevice> = bluetoothAdapter?.bondedDevices ?: emptySet()

    private val channel = "com.example.hardwarelab/bluetooth"
    private val db = FirebaseFirestore.getInstance()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize Firebase
        FirebaseApp.initializeApp(this)

        // Setup the Flutter MethodChannel to handle messages from Flutter
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "pairDevice" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        pairDevice(address)
                        result.success("Pairing initiated.")
                    } else {
                        result.error("ERROR", "Bluetooth address not found", null)
                    }
                }
                "getPairedDevices" -> {
                    val devices = pairedDevices.map { it.name + " - " + it.address }
                    result.success(devices)
                }
                "startScan" -> {
                    startBluetoothScan()
                    result.success("Scanning for devices...")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pairDevice(address: String) {
        val device = bluetoothAdapter?.getRemoteDevice(address)
        device?.let {
            // Add Bluetooth pairing code if needed, otherwise show the Bluetooth settings
            val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            startActivity(intent)

            // Log device pairing to Firestore
            logDevicePairing(device.name ?: "Unknown", device.address)
        }
    }

    private fun logDevicePairing(name: String, address: String) {
        val deviceData = hashMapOf(
            "name" to name,
            "address" to address,
            "paired_at" to System.currentTimeMillis() // Timestamp of pairing
        )

        db.collection("device_pairings")
            .add(deviceData)
            .addOnSuccessListener {
                Toast.makeText(this, "Device logged to Firestore", Toast.LENGTH_SHORT).show()
            }
            .addOnFailureListener { e ->
                Toast.makeText(this, "Error logging device: ${e.message}", Toast.LENGTH_SHORT).show()
            }
    }

    private fun startBluetoothScan() {
        if (bluetoothAdapter?.isEnabled == true) {
            val filter = IntentFilter(BluetoothDevice.ACTION_FOUND)
            registerReceiver(bluetoothReceiver, filter)
            bluetoothAdapter.startDiscovery()
        } else {
            Toast.makeText(this, "Please enable Bluetooth first.", Toast.LENGTH_SHORT).show()
        }
    }

    private val bluetoothReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val action = intent.action
            if (BluetoothDevice.ACTION_FOUND == action) {
                val device: BluetoothDevice = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)!!
                val deviceName = device.name ?: "Unnamed Device"
                val deviceAddress = device.address
                val pairedDevicesList = pairedDevices.map { it.address }

                // Send discovered device to Flutter via MethodChannel
                if (!pairedDevicesList.contains(deviceAddress)) {
                    val result = hashMapOf("name" to deviceName, "address" to deviceAddress)
                    // Use MethodChannel to send data to Flutter
                    MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, channel)
                        .invokeMethod("onDeviceFound", result)
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // Register Bluetooth receiver for scanning
        val filter = IntentFilter(BluetoothDevice.ACTION_PAIRING_REQUEST)
        registerReceiver(bluetoothReceiver, filter)
    }

    override fun onPause() {
        super.onPause()
        unregisterReceiver(bluetoothReceiver)
    }
}
