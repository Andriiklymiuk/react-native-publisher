//
//  RTMPView.swift
//  rtmpPackageExample
//
//  Created by Ezran Bayantemur on 15.01.2022.
//

import UIKit
import HaishinKit
import AVFoundation
import VideoToolbox

class RTMPView: UIView {
  private var hkView: MTHKView!
  @objc var onDisconnect: RCTDirectEventBlock?
  @objc var onConnectionFailed: RCTDirectEventBlock?
  @objc var onConnectionStarted: RCTDirectEventBlock?
  @objc var onConnectionSuccess: RCTDirectEventBlock?
  @objc var onNewBitrateReceived: RCTDirectEventBlock?
  @objc var onStreamStateChanged: RCTDirectEventBlock?
  
  @objc var streamURL: NSString = "" {
    didSet {
      RTMPCreator.setStreamUrl(url: streamURL as String)
    }
  }
  
  @objc var streamName: NSString = "" {
    didSet {
      RTMPCreator.setStreamName(name: streamName as String)
    }
  }
  
  @objc var videoSettings: NSDictionary = NSDictionary(
      dictionary: [
        "width": 720,
        "height": 1280,
        "bitrate": 3000 * 1000,
        "audioBitrate": 192 * 1000
      ]
  ){
    didSet {
        let width: Int = videoSettings["width"] as? Int ?? 720
        let height: Int = videoSettings["height"] as? Int ?? 1280
        let bitrate: Int = videoSettings["bitrate"] as? Int ?? (3000 * 1000)
        let audioBitrate: Int = videoSettings["audioBitrate"] as? Int ?? (192 * 1000)
        
        RTMPCreator.setVideoSettings(
            VideoSettingsType(
                width: Int32(width),
                height: Int32(height),
                bitrate: UInt32(bitrate),
                audioBitrate: audioBitrate
            )
        )
    }
  }

  @objc var allowedVideoOrientations: [String] = ["portrait", "landscapeLeft", "landscapeRight", "portraitUpsideDown"] {
      didSet {
          let orientations = allowedVideoOrientations.compactMap { AVCaptureVideoOrientation(string: $0) }
          RTMPCreator.allowedVideoOrientations = orientations
      }
  }

      @objc var videoOrientation: NSString = AVCaptureVideoOrientation.portrait.toString() as NSString {
       didSet {
           if let orientation: AVCaptureVideoOrientation = AVCaptureVideoOrientation(string: videoOrientation as String) {
               RTMPCreator.videoOrientation = orientation
               RTMPCreator.stream.videoOrientation = orientation
               updateVideoSettings(orientation: orientation)
           }
       }
     }
    
    private var retryCount: Int = 0
    private static let maxRetryCount: Int = 10
  
  override init(frame: CGRect) {
    super.init(frame: frame)

    RtmpPublisher.setup()

    UIApplication.shared.isIdleTimerDisabled = true
    
    hkView = MTHKView(frame: UIScreen.main.bounds)
    hkView.videoGravity = .resizeAspectFill
    RTMPCreator.stream.videoOrientation = RTMPCreator.videoOrientation
      
    RTMPCreator.stream.frameRate = 30
    RTMPCreator.stream.sessionPreset = AVCaptureSession.Preset.hd1920x1080

    RTMPCreator.stream.audioSettings = AudioCodecSettings(
        bitRate: RTMPCreator.videoSettings.audioBitrate
    )

    RTMPCreator.stream.frameRate = 30
    RTMPCreator.stream.sessionPreset = AVCaptureSession.Preset.hd1920x1080

    // It provides strange behavior if auto enabled, but can be useful to test
    // RTMPCreator.stream.videoCapture(for: 0).preferredVideoStabilizationMode = .auto

    RTMPCreator.stream.videoCapture(for: 0)?.isVideoMirrored = false

    RTMPCreator.stream.videoSettings = VideoCodecSettings(
        videoSize: .init(width: RTMPCreator.videoSettings.width, height: RTMPCreator.videoSettings.height),
        profileLevel: kVTProfileLevel_H264_High_AutoLevel as String,
        bitRate: RTMPCreator.videoSettings.bitrate,
        maxKeyFrameIntervalDuration: 2,
        scalingMode: .cropSourceToCleanAperture,
        bitRateMode: .average,
        allowFrameReordering: nil,
        isHardwareEncoderEnabled: true
    )

    RTMPCreator.stream.attachAudio(AVCaptureDevice.default(for: .audio))
    RTMPCreator.stream.attachCamera(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back))
    RTMPCreator.cameraPosition = .back

    RTMPCreator.connection.addEventListener(.rtmpStatus, selector: #selector(statusHandler), observer: self)
    RTMPCreator.connection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
      
    NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    hkView.attachStream(RTMPCreator.stream)

    self.addSubview(hkView)
      
}
    
    @objc
    private func rtmpErrorHandler(_ notification: Notification) {
        print("rtmpErrorHandler", notification)

        changeStreamState(status: "I/O ERROR")
        RTMPCreator.connection.connect(streamURL as String)
    }
    
    required init?(coder aDecoder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
     }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        RTMPCreator.stream.attachAudio(nil)
        RTMPCreator.stream.attachCamera(nil)
        RTMPCreator.connection.removeEventListener(.rtmpStatus, selector: #selector(statusHandler), observer: self)
        RTMPCreator.connection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        UIApplication.shared.isIdleTimerDisabled = false
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc
    private func statusHandler(_ notification: Notification){
      let e = Event.from(notification)
       guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
           return
       }
    
       switch code {
       case RTMPConnection.Code.connectSuccess.rawValue:
         if onConnectionSuccess != nil {
              onConnectionSuccess!(nil)
            }
           retryCount = 0
           changeStreamState(status: "CONNECTING")
           RTMPCreator.stream.publish(streamName as String)
           break
       
       case RTMPConnection.Code.connectFailed.rawValue:
         if onConnectionFailed != nil {
              onConnectionFailed!(nil)
            }
           changeStreamState(status: "FAILED")
           reconnect()
           break
         
       case RTMPConnection.Code.connectClosed.rawValue:
         if onDisconnect != nil {
              onDisconnect!(nil)
            }
           changeStreamState(status: "CLOSED")
           reconnect()
           break
         
       case RTMPStream.Code.publishStart.rawValue:
         if onConnectionStarted != nil {
              onConnectionStarted!(nil)
            }
           changeStreamState(status: "CONNECTED")
           break
         
       default:
           changeStreamState(status: code)
           break
       }
    }
    
    public func reconnect(){
        guard retryCount <= RTMPView.maxRetryCount else {
         return
        }
        Thread.sleep(forTimeInterval: pow(2.0, Double(retryCount)))
        RTMPCreator.connection.connect(streamURL as String)
        retryCount += 1
    }

    public func changeStreamState(status: String){
      if onStreamStateChanged != nil {
        onStreamStateChanged!(["data": status])
       }
    }
    
    @objc
    private func deviceOrientationDidChange(_ notification: Notification) {
        guard let deviceOrientation = UIDevice.current.orientation.videoOrientation else {
            return
        }

        if !RTMPCreator.allowedVideoOrientations.contains(deviceOrientation) {
            return
        }

        if RTMPCreator.videoOrientation == deviceOrientation {
            return
        }

        RTMPCreator.videoOrientation = deviceOrientation
        RTMPCreator.stream.videoOrientation = deviceOrientation

        updateVideoSettings(orientation: deviceOrientation)
    }
    
    private func updateVideoSettings(orientation: AVCaptureVideoOrientation) {
        let width: Int
        let height: Int
        let bitrate = RTMPCreator.videoSettings.bitrate
        let audioBitrate = RTMPCreator.videoSettings.audioBitrate

        if orientation == .portrait || orientation == .portraitUpsideDown {
            width = Int(RTMPCreator.videoSettings.width)
            height = Int(RTMPCreator.videoSettings.height)
        } else {
            width = Int(RTMPCreator.videoSettings.height)
            height = Int(RTMPCreator.videoSettings.width)
        }

        videoSettings = NSDictionary(
            dictionary: [
                "width": width,
                "height": height,
                "bitrate": bitrate,
                "audioBitrate": audioBitrate
            ]
        )
    }
}

extension UIDeviceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeRight:
            return .landscapeLeft
        case .landscapeLeft:
            return .landscapeRight
        default:
            return nil
        }
    }
}

extension AVCaptureVideoOrientation {
    init?(string: String) {
        let lowercasedString: String = string.lowercased()
        switch lowercasedString {
        case "portrait":
            self = .portrait
        case "landscapeleft":
            self = .landscapeLeft
        case "landscaperight":
            self = .landscapeRight
        case "portraitupsidedown":
            self = .portraitUpsideDown
        default:
            return nil
        }
    }
    
    func toString() -> String {
        switch self {
        case .portrait:
            return "portrait"
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        @unknown default:
            fatalError("AVCaptureVideoOrientation has an unknown value.")
        }
    }
    
    var isPortrait: Bool {
        return self == .portrait || self == .portraitUpsideDown
    }
}
