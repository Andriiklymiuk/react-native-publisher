package com.reactnativertmppublisher;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReadableMap;
import com.reactnativertmppublisher.enums.AudioInputType;
import com.reactnativertmppublisher.modules.VideoSettings;

public class RTMPModule extends ReactContextBaseJavaModule {
  private final String REACT_MODULE_NAME = "RTMPPublisher";

  public RTMPModule(@Nullable ReactApplicationContext reactContext) {
    super(reactContext);
  }

  @NonNull
  @Override
  public String getName() {
    return REACT_MODULE_NAME;
  }

  @ReactMethod
  public void isStreaming(Promise promise) {
    try {
      boolean streamStatus = RTMPManager.publisher.isStreaming();
      promise.resolve(streamStatus);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void isCameraOnPreview(Promise promise) {
    try {
      boolean streamStatus = RTMPManager.publisher.isOnPreview();
      promise.resolve(streamStatus);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void getPublishURL(Promise promise) {
    try {
      String url = RTMPManager.publisher.getPublishURL();
      promise.resolve(url);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void hasCongestion(Promise promise) {
    try {
      boolean congestionStatus = RTMPManager.publisher.hasCongestion();
      promise.resolve(congestionStatus);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void isAudioPrepared(Promise promise) {
    try {
      boolean status = RTMPManager.publisher.isAudioPrepared();
      promise.resolve(status);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void isVideoPrepared(Promise promise) {
    try {
      boolean status = RTMPManager.publisher.isVideoPrepared();
      promise.resolve(status);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void isMuted(Promise promise) {
    try {
      boolean status = RTMPManager.publisher.isAudioMuted();
      promise.resolve(status);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void mute(Promise promise) {
    try {
      if (RTMPManager.publisher.isAudioMuted()) {
        return;
      }

      RTMPManager.publisher.disableAudio();
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void unmute(Promise promise) {
    try {
      if (!RTMPManager.publisher.isAudioMuted()) {
        return;
      }

      RTMPManager.publisher.enableAudio();
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void switchCamera(Promise promise) {
    try {
      RTMPManager.publisher.switchCamera();
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void startStream(Promise promise) {
    try {
      RTMPManager.publisher.startStream();
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void stopStream(Promise promise) {
    try {
      RTMPManager.publisher.stopStream();
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void toggleFlash(Promise promise) {
    try {
      RTMPManager.publisher.toggleFlash();
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void setAudioInput(int audioInputType, Promise promise) {
    try {
      AudioInputType selectedType = AudioInputType.values()[audioInputType];
      RTMPManager.publisher.setAudioInput(selectedType);
    } catch (Exception e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void setVideoSettings(ReadableMap videoSettingsMap, Promise promise) {
    Log.d("RTMPPublisher","setVideoSettings" +  String.valueOf(videoSettingsMap));
    try {
      VideoSettings defaultSettings = VideoSettings.getDefault();

      int width = getIntOrDefault(videoSettingsMap, "width", defaultSettings.width);
      int height = getIntOrDefault(videoSettingsMap, "height", defaultSettings.height);
      int bitrate = getIntOrDefault(videoSettingsMap, "bitrate", defaultSettings.bitrate);
      int audioBitrate = getIntOrDefault(videoSettingsMap, "audioBitrate", defaultSettings.audioBitrate);

      VideoSettings settings = new VideoSettings(width, height, bitrate, audioBitrate);
      RTMPManager.publisher.setVideoSettings(settings);
      promise.resolve(null);

    } catch (Exception e) {
      promise.reject(e);
    }
  }

  private int getIntOrDefault(ReadableMap map, String key, int defaultValue) {
    return map.hasKey(key) ? map.getInt(key) : defaultValue;
  }
}
