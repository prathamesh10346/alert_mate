package com.example.alert_mate

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraCharacteristics
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import java.io.File
import android.content.Context
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CaptureRequest
import android.media.ImageReader.OnImageAvailableListener
import android.os.Environment
import java.io.FileOutputStream
import java.nio.ByteBuffer
import android.graphics.ImageFormat
import android.os.SystemClock

class CameraService : Service() {
    private lateinit var cameraManager: CameraManager
    private lateinit var cameraDevice: CameraDevice
    private lateinit var imageReader: ImageReader
    private lateinit var backgroundHandler: Handler
    private lateinit var backgroundThread: HandlerThread

    override fun onCreate() {
        super.onCreate()
        startBackgroundThread()
        cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        openCamera()
        return START_NOT_STICKY
    }

    private fun startBackgroundThread() {
        backgroundThread = HandlerThread("CameraBackground")
        backgroundThread.start()
        backgroundHandler = Handler(backgroundThread.looper)
    }

    private fun openCamera() {
        try {
            val cameraId = getFrontCameraId()
            if (cameraId != null) {
                imageReader = ImageReader.newInstance(1920, 1080, ImageFormat.JPEG, 1)
                imageReader.setOnImageAvailableListener(onImageAvailableListener, backgroundHandler)

                cameraManager.openCamera(cameraId, object : CameraDevice.StateCallback() {
                    override fun onOpened(camera: CameraDevice) {
                        cameraDevice = camera
                        createCaptureSession()
                    }

                    override fun onDisconnected(camera: CameraDevice) {
                        camera.close()
                        stopSelf()
                    }

                    override fun onError(camera: CameraDevice, error: Int) {
                        camera.close()
                        stopSelf()
                    }
                }, backgroundHandler)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            stopSelf()
        }
    }

    private fun getFrontCameraId(): String? {
        try {
            for (cameraId in cameraManager.cameraIdList) {
                val characteristics = cameraManager.getCameraCharacteristics(cameraId)
                val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
                if (facing == CameraCharacteristics.LENS_FACING_FRONT) {
                    return cameraId
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }

    private val onImageAvailableListener = OnImageAvailableListener { reader ->
        val image = reader.acquireLatestImage()
        if (image != null) {
            val buffer: ByteBuffer = image.planes[0].buffer
            val bytes = ByteArray(buffer.capacity())
            buffer.get(bytes)
            saveImageToFile(bytes)
            image.close()
            stopSelf()
        }
    }

    private fun createCaptureSession() {
        try {
            val surface = imageReader.surface
            val captureRequestBuilder = cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)
            captureRequestBuilder.addTarget(surface)

            cameraDevice.createCaptureSession(
                listOf(surface),
                object : CameraCaptureSession.StateCallback() {
                    override fun onConfigured(session: CameraCaptureSession) {
                        try {
                            session.capture(captureRequestBuilder.build(), null, backgroundHandler)
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }

                    override fun onConfigureFailed(session: CameraCaptureSession) {
                        stopSelf()
                    }
                },
                backgroundHandler
            )
        } catch (e: Exception) {
            e.printStackTrace()
            stopSelf()
        }
    }

    private fun saveImageToFile(bytes: ByteArray) {
        try {
            val timestamp = SystemClock.elapsedRealtime()
            val filename = "intruder_$timestamp.jpg"
            val file = File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), filename)
            
            FileOutputStream(file).use { output ->
                output.write(bytes)
            }

            // Notify Flutter about the new image
            val intent = Intent("com.example.alert_mate.NEW_INTRUDER_IMAGE")
            intent.putExtra("image_path", file.absolutePath)
            sendBroadcast(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::cameraDevice.isInitialized) {
            cameraDevice.close()
        }
        if (::imageReader.isInitialized) {
            imageReader.close()
        }
        stopBackgroundThread()
    }

    private fun stopBackgroundThread() {
        backgroundThread.quitSafely()
        try {
            backgroundThread.join()
        } catch (e: InterruptedException) {
            e.printStackTrace()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}