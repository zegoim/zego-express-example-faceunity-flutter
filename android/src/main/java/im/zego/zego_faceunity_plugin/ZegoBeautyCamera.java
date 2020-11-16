package im.zego.zego_faceunity_plugin;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.hardware.Camera;
import android.opengl.GLES11Ext;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.os.SystemClock;
import android.util.Log;
import android.view.TextureView;

import com.faceunity.FURenderer;
import com.faceunity.wrapper.faceunity;

import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import im.zego.zego_express_engine.IZegoFlutterCustomVideoCaptureHandler;
import im.zego.zego_express_engine.ZegoCustomVideoCaptureManager;


public class ZegoBeautyCamera implements IZegoFlutterCustomVideoCaptureHandler, Camera.PreviewCallback {
    private static boolean mIsSetup = false;
    private Context mContext;

    private FURenderer mRenderer;
    private static final String BUNDLE_FACE_BEAUTIFICATION = "graphics/face_beautification.bundle";
    private int[] mItemsArray = new int[1];

    private static final int NUMBER_OF_CAPTURE_BUFFERS = 3;
    private final Set<byte[]> queuedBuffers = new HashSet<byte[]>();
    private int mFrameSize = 0;
    private Handler uiHandler = new Handler(Looper.getMainLooper());
    private HandlerThread mThread = null;
    private volatile Handler cameraThreadHandler = null;
    private final AtomicBoolean isCameraRunning = new AtomicBoolean();
    private final Object pendingCameraRestartLock = new Object();
    private volatile boolean pendingCameraRestart = false;

    private static final String TAG = "VideoCaptureFromCamera";
    private static final int CAMERA_STOP_TIMEOUT_MS = 7000;

    private SurfaceTexture mTexture = null;

    private Camera mCam = null;
    private Camera.CameraInfo mCamInfo = null;

    public static final int FACE_BACK = Camera.CameraInfo.CAMERA_FACING_BACK;
    public static final int FACE_FRONT = Camera.CameraInfo.CAMERA_FACING_FRONT;
    public static final int FRONT_CAMERA_ORIENTATION = 270;
    public static final int BACK_CAMERA_ORIENTATION = 90;
    protected int mCameraFacing = FACE_FRONT;
    protected int mBackCameraOrientation = BACK_CAMERA_ORIENTATION;
    protected int mFrontCameraOrientation = FRONT_CAMERA_ORIENTATION;
    protected int mCameraOrientation = FRONT_CAMERA_ORIENTATION;

    // 默认为前置摄像头
    // The default is the rear camera
    boolean mFront = true;
    // 预设分辨率宽
    // Wide preset resolution
    int mWidth = 640;
    // 预设分辨率高
    // High preset resolution
    int mHeight = 480;
    // 预设采集帧率
    // Preset acquisition frame rate
    int mFrameRate = 30;
    // 默认不旋转
    // No rotation by default
    int mRotation = 0;

    boolean mIsCaptured = false;

    public static void setup(Context context) {
        if(!mIsSetup) {
            FURenderer.initFURenderer(context);
            if(FURenderer.isLibInit())
                mIsSetup = true;
        }
    }

    public ZegoBeautyCamera(Context context) {
        mContext = context;
        //FURenderer
        FURenderer.Builder builder = new FURenderer.Builder(mContext);
        mRenderer = builder.maxFaces(1).maxHumans(1).createEGLContext(true).build();
        mRenderer.setBeautificationOn(true);
    }

    public void setWhitenParam(float whiten) {
        mRenderer.onColorLevelSelected(whiten);
    }

    public void setRedParam(float red) {
        mRenderer.onRedLevelSelected(red);
    }

    public void setBlurParam(float blur) {
        mRenderer.onBlurLevelSelected(blur);
    }

    public void setEnlargingParam(float enlarging) {
        mRenderer.onEyeEnlargeSelected(enlarging);
    }

    public void setThinningParam(float thinning) {
        mRenderer.onCheekThinningSelected(thinning);
    }

    public void setVParam(float v) {
        mRenderer.onCheekVSelected(v);
    }

    public void setNarrowParam(float narrow) {
        mRenderer.onCheekNarrowSelected(narrow);
    }

    public void setSmallParam(float small) {
        mRenderer.onCheekSmallSelected(small);
    }

    public void setChinParam(float chin) {
        mRenderer.onIntensityChinSelected(chin);
    }

    public void setForeheadParam(float forehead) {
        mRenderer.onIntensityForeheadSelected(forehead);
    }

    public void setNoseParam(float nose) {
        mRenderer.onIntensityNoseSelected(nose);
    }

    public void setMouthParam(float mouth) {
        mRenderer.onIntensityMouthSelected(mouth);
    }

    public void resetBeautyOption() {
        loadDefaultBeautyOption();
    }

    // 设置采集帧率
    // Set the acquisition frame rate
    public void setFrameRate(int framerate) {
        mFrameRate = framerate;
        // 更新camera的采集帧率
        // Update camera frame rate
        updateRateOnCameraThread(framerate);
    }

    // 前后摄像头的切换
    // Switching between front and back cameras
    public void switchCamera(int position) {
        mFront = (position == 0);
        // 切换摄像头后需要重启camera
        // Camera needs to be restarted after switching cameras
        restartCam(mFront);
    }

    @Override
    public void onStart(int channel) {

        mIsCaptured = true;

        mThread = new HandlerThread("camera-cap");
        mThread.start();
        // 创建camera异步消息处理handler
        // Create a camera asynchronous message processing handler
        cameraThreadHandler = new Handler(mThread.getLooper());

        cameraThreadHandler.post(new Runnable() {
            @Override
            public void run() {
                Log.e("VideoCamera:", "onSurfaceCreated cameraThread: " + Thread.currentThread().getName());
                mRenderer.onSurfaceCreated();
                setFrameRate(30);
                setResolution(360, 640);
            }
        });

        startCapture();
    }

    @Override
    public void onStop(int channel) {
        // 停止camera采集任务
        stopCapture();
        if (mThread != null) {
            mThread.quit();
            mThread = null;
        }

        mIsCaptured = false;
    }

    private void startCapture() {
        if (isCameraRunning.getAndSet(true)) {
            Log.e(TAG, "Camera has already been started.");
            return;
        }

        final boolean didPost = maybePostOnCameraThread(new Runnable() {
            @Override
            public void run() {
                // 创建camera
                // create camera
                createCamOnCameraThread(mCameraFacing);
                // 启动camera
                //start camera
                startCamOnCameraThread();
                mRenderer.onCameraChange(FACE_FRONT, FRONT_CAMERA_ORIENTATION);
            }
        });
    }

    private void stopCapture() {
        Log.d(TAG, "stopCapture");
        final CountDownLatch barrier = new CountDownLatch(1);
        final boolean didPost = maybePostOnCameraThread(new Runnable() {
            @Override
            public void run() {
                // 停止camera
                // stop camera
                stopCaptureOnCameraThread(true /* stopHandler */);
                // 释放camera资源
                // Free camera resources
                Log.e("VideoCamera:", "onSurfaceDestroyed cameraThread: " + Thread.currentThread().getName());
                mRenderer.onSurfaceDestroyed();
                releaseCam();
                barrier.countDown();

                //mClient = null;
            }
        });
        if (!didPost) {
            Log.e(TAG, "Calling stopCapture() for already stopped camera.");
            return;
        }
        try {
            if (!barrier.await(CAMERA_STOP_TIMEOUT_MS, TimeUnit.MILLISECONDS)) {
                Log.e(TAG, "Camera stop timeout");
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        Log.d(TAG, "stopCapture done");
    }

    private void loadDefaultBeautyOption() {
        mRenderer.onColorLevelSelected(1.0f);
        mRenderer.onRedLevelSelected(0.5f);
        mRenderer.onBlurLevelSelected(4.2f);

        mRenderer.onEyeEnlargeSelected(0.4f);
        mRenderer.onCheekThinningSelected(0.0f);
        mRenderer.onCheekVSelected(0.5f);
        mRenderer.onCheekNarrowSelected(0.0f);
        mRenderer.onCheekSmallSelected(0.0f);
        mRenderer.onIntensityChinSelected(0.3f);
        mRenderer.onIntensityForeheadSelected(0.3f);
        mRenderer.onIntensityNoseSelected(0.5f);
        mRenderer.onIntensityMouthSelected(0.4f);
    }

    // 设置视图宽高
    // Set view width and height
    private void setResolution(int width, int height) {
        mWidth = width;
        mHeight = height;
        // 修改视图宽高后需要重启camera
        // You need to restart the camera after changing the view width and height
        restartCam(mFront);
    }

    private boolean maybePostOnCameraThread(Runnable runnable) {
        return cameraThreadHandler != null && isCameraRunning.get()
                && cameraThreadHandler.postAtTime(runnable, this, SystemClock.uptimeMillis());
    }

    private int createCamOnCameraThread(int cameraFacing) {
        checkIsOnCameraThread();
        if (!isCameraRunning.get()) {
            Log.e(TAG, "startCaptureOnCameraThread: Camera is stopped");
            return 0;
        }

        // 获取欲设置camera的索引号
        //Get the index number of the camera to be setx
        if (mCam != null) {
            // 已打开camera
            // Camera opened
            return 0;
        }

        mCamInfo = new Camera.CameraInfo();
        // 获取设备上camera的数目
        // Get the number of cameras on the device
        int nCnt = Camera.getNumberOfCameras();
        // 得到欲设置camera的索引号并打开camera
        // Get the index number of the camera you want to set and open the camera
        for (int i = 0; i < nCnt; i++) {
            Camera.getCameraInfo(i, mCamInfo);
            //if(isFront) {
                if (cameraFacing == i) {
                    mCam = Camera.open(i);
                    break;
                }
            /*} else {
                if (mCamInfo.CAMERA_FACING_BACK == i) {
                    mCam = Camera.open(i);
                    break;
                }
            }*/

        }

        // 没找到欲设置的camera
        // Did not find the camera to be set
        if (mCam == null) {
            Log.i(TAG, "[WARNING] no camera found, try default\n");
            // 先试图打开默认camera
            // First try to open the default camera
            mCam = Camera.open();

            if (mCam == null) {
                Log.i(TAG, "[ERROR] no camera found\n");
                return -1;
            }
        }


        boolean bSizeSet = false;
        Camera.Parameters parms = mCam.getParameters();
        // 获取camera首选的size
        // Get the camera's preferred size
        Camera.Size psz = parms.getPreferredPreviewSizeForVideo();

        mWidth = 640;
        mHeight = 480;

        parms.setPreviewSize(640, 480);

        // 获取camera支持的帧率范围，并设置预览帧率范围
        // Get the frame rate range supported by the camera and set the preview frame rate range
        List<int[]> supported = parms.getSupportedPreviewFpsRange();

        for (int[] entry : supported) {
            if ((entry[0] == entry[1]) && entry[0] == mFrameRate * 1000) {
                parms.setPreviewFpsRange(entry[0], entry[1]);
                break;
            }
        }

        // 获取camera的实际帧率
        // Get the actual frame rate of the camera
        int[] realRate = new int[2];
        parms.getPreviewFpsRange(realRate);
        if (realRate[0] == realRate[1]) {
            mFrameRate = realRate[0] / 1000;
        } else {
            mFrameRate = realRate[1] / 2 / 1000;
        }

        // 不启用提高MediaRecorder录制摄像头视频性能的功能，可能会导致在某些手机上预览界面变形的问题
        // Failure to enable the function that improves the performance of the MediaRecorder to record camera video may cause distortions in the preview interface on some phones
        parms.setRecordingHint(false);

        // 设置camera的对焦模式
        // Set the camera's focus mode
        boolean bFocusModeSet = false;
        for (String mode : parms.getSupportedFocusModes()) {
            if (mode.compareTo(Camera.Parameters.FOCUS_MODE_CONTINUOUS_VIDEO) == 0) {
                try {
                    parms.setFocusMode(mode);
                    bFocusModeSet = true;
                    break;
                } catch (Exception ex) {
                    Log.i(TAG, "[WARNING] vcap: set focus mode error (stack trace followed)!!!\n");
                    ex.printStackTrace();
                }
            }
        }
        if (!bFocusModeSet) {
            Log.i(TAG, "[WARNING] vcap: focus mode left unset !!\n");
        }

        // 设置camera的参数
        // Set camera parameters
        try {
            mCam.setParameters(parms);
        } catch (Exception ex) {
            Log.i(TAG, "vcap: set camera parameters error with exception\n");
            ex.printStackTrace();
        }

        Camera.Parameters actualParm = mCam.getParameters();

        mWidth = actualParm.getPreviewSize().width;
        mHeight = actualParm.getPreviewSize().height;
        Log.i(TAG, "[WARNING] vcap: focus mode " + actualParm.getFocusMode());

        createPool();

        int result;
        if (mCamInfo.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
            result = (mCamInfo.orientation + mRotation) % 360;
            result = (360 - result) % 360;  // compensate the mirror
        } else {  // back-facing
            result = (mCamInfo.orientation - mRotation + 360) % 360;
        }
        // 设置预览图像的转方向
        // Set the rotation direction of the preview image
        mCam.setDisplayOrientation(result);

        return 0;
    }

    // 为camera分配内存存放采集数据
    // Allocate memory for camera to store collected data
    private void createPool() {
        queuedBuffers.clear();
        mFrameSize = mWidth * mHeight * 3 / 2;
        for (int i = 0; i < NUMBER_OF_CAPTURE_BUFFERS; ++i) {
            final ByteBuffer buffer = ByteBuffer.allocateDirect(mFrameSize);
            queuedBuffers.add(buffer.array());
            // 减少camera预览时的内存占用
            // Reduce memory usage during camera preview
            mCam.addCallbackBuffer(buffer.array());
        }
    }

    SurfaceTexture mSurfaceTexture = new SurfaceTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES);

    // 启动camera
    //start camera
    private int startCamOnCameraThread() {
        checkIsOnCameraThread();
        if (!isCameraRunning.get() || mCam == null) {
            Log.e(TAG, "startPreviewOnCameraThread: Camera is stopped");
            return 0;
        }
        SurfaceTexture surfaceTexture;
        if (mTexture == null) {
            surfaceTexture = mSurfaceTexture;
        } else {
            surfaceTexture = mTexture;
        }
        try {

            mCam.setPreviewTexture(surfaceTexture);
            // mCam.setPreviewTexture(mTexture);
        } catch (IOException e) {
            e.printStackTrace();
        }

        // 在打开摄像头预览前先分配一个buffer地址，目的是为了后面内存复用
        // Before opening the camera preview, first allocate a buffer address, the purpose is to reuse memory later
        mCam.setPreviewCallbackWithBuffer(this);
        // 启动camera预览
        // Start camera preview
        mCam.startPreview();
        return 0;
    }

    // 停止camera采集
    // Stop camera collection
    private int stopCaptureOnCameraThread(boolean stopHandler) {
        checkIsOnCameraThread();
        Log.d(TAG, "stopCaptureOnCameraThread");

        if (stopHandler) {
            // Clear the cameraThreadHandler first, in case stopPreview or
            // other driver code deadlocks. Deadlock in
            // android.hardware.Camera._stopPreview(Native Method) has
            // been observed on Nexus 5 (hammerhead), OS version LMY48I.
            // The camera might post another one or two preview frames
            // before stopped, so we have to check |isCameraRunning|.
            // Remove all pending Runnables posted from |this|.
            isCameraRunning.set(false);
            cameraThreadHandler.removeCallbacksAndMessages(this /* token */);
        }

        if (mCam != null) {
            // 停止camera预览
            // stop camera preview
            mCam.stopPreview();
            mCam.setPreviewCallbackWithBuffer(null);
        }
        queuedBuffers.clear();
        return 0;
    }

    private int restartCam(final boolean isFront) {
        synchronized (pendingCameraRestartLock) {
            if (pendingCameraRestart) {
                // Do not handle multiple camera switch request to avoid blocking
                // camera thread by handling too many switch request from a queue.
                Log.w(TAG, "Ignoring camera switch request.");
                return 0;
            }
            pendingCameraRestart = true;
        }

        final boolean didPost = maybePostOnCameraThread(new Runnable() {
            @Override
            public void run() {

                mCameraFacing = isFront ? FACE_FRONT : FACE_BACK;
                mCameraOrientation = isFront ? mFrontCameraOrientation : mBackCameraOrientation;
                stopCaptureOnCameraThread(false);
                releaseCam();
                synchronized (pendingCameraRestartLock) {
                    pendingCameraRestart = false;
                }

                createCamOnCameraThread(mCameraFacing);
                startCamOnCameraThread();
                //if(mClient != null) {
                if(isFront)
                    ZegoCustomVideoCaptureManager.getInstance().setVideoMirrorMode(0, 0);
                else
                    ZegoCustomVideoCaptureManager.getInstance().setVideoMirrorMode(2, 0);
                //}
                mRenderer.onCameraChange(isFront ? FACE_FRONT : FACE_BACK, isFront ? FRONT_CAMERA_ORIENTATION : BACK_CAMERA_ORIENTATION);

            }
        });

        if (!didPost) {
            synchronized (pendingCameraRestartLock) {
                pendingCameraRestart = false;
            }
        }

        return 0;
    }

    // 释放camera
    // release camera
    private int releaseCam() {
        // * release cam
        if (mCam != null) {
            mCam.release();
            mCam = null;
        }

        // * release cam info
        mCamInfo = null;
        return 0;
    }

    // 更新camera的采集帧率
    // Update camera frame rate
    private int updateRateOnCameraThread(final int framerate) {
        checkIsOnCameraThread();
        if (mCam == null) {
            return 0;
        }

        mFrameRate = framerate;

        Camera.Parameters parms = mCam.getParameters();
        List<int[]> supported = parms.getSupportedPreviewFpsRange();

        for (int[] entry : supported) {
            if ((entry[0] == entry[1]) && entry[0] == mFrameRate * 1000) {
                parms.setPreviewFpsRange(entry[0], entry[1]);
                break;
            }
        }

        int[] realRate = new int[2];
        parms.getPreviewFpsRange(realRate);
        if (realRate[0] == realRate[1]) {
            mFrameRate = realRate[0] / 1000;
        } else {
            mFrameRate = realRate[1] / 2 / 1000;
        }

        try {
            mCam.setParameters(parms);
        } catch (Exception ex) {
            Log.i(TAG, "vcap: update fps -- set camera parameters error with exception\n");
            ex.printStackTrace();
        }
        return 0;
    }

    // 检查CameraThread是否正常运行
    // Check if CameraThread is running normally
    private void checkIsOnCameraThread() {
        if (cameraThreadHandler == null) {
            Log.e(TAG, "Camera is not initialized - can't check thread.");
        } else if (Thread.currentThread() != cameraThreadHandler.getLooper().getThread()) {
            throw new IllegalStateException("Wrong thread");
        }
    }

    ByteBuffer byteBuffer;
    int i =0;
    @Override
    public void onPreviewFrame(byte[] data, Camera camera) {

        checkIsOnCameraThread();
        if (!isCameraRunning.get()) {
            Log.e(TAG, "onPreviewFrame: Camera is stopped");
            return;
        }

        if (!queuedBuffers.contains(data)) {
            // |data| is an old invalid buffer.
            return;
        }

        if (!mIsCaptured) {
            return;
        }

        if(i < 5) {
            i++;
            Log.e("VideoCamera:", "onDrawFrame cameraThread: " + Thread.currentThread().getName());
        }
        // 使用采集视频帧信息构造VideoCaptureFormat
        // Constructing VideoCaptureFormat using captured video frame information
        ZegoCustomVideoCaptureManager.VideoFrameParam param = new ZegoCustomVideoCaptureManager.VideoFrameParam();
        param.width = mWidth;
        param.height = mHeight;
        param.strides[0] = mWidth;
        param.strides[1] = mWidth;
        param.format = ZegoCustomVideoCaptureManager.VideoFrameFormat.NV21;
        param.rotation = mCamInfo.orientation;

        long now;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            now = SystemClock.elapsedRealtimeNanos();
        } else {
            now = TimeUnit.MILLISECONDS.toNanos(SystemClock.elapsedRealtime());
        }

        mRenderer.onDrawFrame(data, mWidth, mHeight, data, mWidth, mHeight);

        // 将采集的数据传给ZEGO SDK
        // Pass the collected data to ZEGO SDK
        if (byteBuffer == null) {
            byteBuffer = ByteBuffer.allocateDirect(data.length);
        }
        byteBuffer.put(data);
        byteBuffer.flip();

        if(mIsCaptured) {
            ZegoCustomVideoCaptureManager.getInstance().sendRawData(byteBuffer, data.length, param, now, 0);
        }

        // 实现camera预览时的内存复用
        // Memory reuse during camera preview
        camera.addCallbackBuffer(data);
    }
}
