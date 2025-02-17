//
//  RTMPCreator.swift
//  rtmpPackageExample
//
//  Created by Ezran Bayantemur on 15.01.2022.
//
import HaishinKit
import AVFoundation
import VideoToolbox

struct VideoSettingsType {
    var width: Int32
    var height: Int32
    var bitrate: UInt32
    var audioBitrate: Int
}

class RTMPCreator {
    public static let connection: RTMPConnection = RTMPConnection()
    public static let stream: RTMPStream = RTMPStream(connection: connection)
    private static let session: AVAudioSession = AVAudioSession.sharedInstance()
    private static var _streamUrl: String = ""
    private static var _streamName: String = ""
    public static var isStreaming: Bool = false
    public static var videoSettings: VideoSettingsType = VideoSettingsType(
        width: 720,
        height: 1280,
        bitrate: 3000 * 1024,
        audioBitrate: 128 * 1000
    )
    public static var cameraPosition: AVCaptureDevice.Position = .back

    public static var videoOrientation: AVCaptureVideoOrientation = AVCaptureVideoOrientation.portrait
    public static var allowedVideoOrientations: [AVCaptureVideoOrientation] = [
        .portrait,
        .landscapeLeft,
        .landscapeRight,
        .portraitUpsideDown
    ]

    public static func setStreamUrl(url: String){
        _streamUrl = url
    }

    public static func setStreamName(name: String){
        _streamName = name
    }

  
    public static func getPublishURL() -> String {
    // TODO: Object formatına dönüştürülebilir
    /**
      {
        streamName: _streamName
        streamUrl: _streamUrl
      }
     */
    return "\(_streamUrl)/\(_streamName)"
    }
  
    public static func startPublish(){
        connection.requireNetworkFramework = true
        connection.connect(_streamUrl)
        isStreaming = true
    }
    
    public static func setVideoSettings(_ newVideoSettings: VideoSettingsType) {
        videoSettings = newVideoSettings
        let width = videoOrientation.isPortrait ? videoSettings.width : videoSettings.height
        let height = videoOrientation.isPortrait ? videoSettings.height : videoSettings.width
        stream.videoSettings = VideoCodecSettings(
            videoSize: .init(width: width, height: height),
            profileLevel: kVTProfileLevel_H264_High_AutoLevel as String,
            bitRate: videoSettings.bitrate,
            maxKeyFrameIntervalDuration: 2,
            scalingMode: .cropSourceToCleanAperture,
            bitRateMode: .average,
            allowFrameReordering: nil,
            isHardwareEncoderEnabled: true
        )
        
        stream.audioSettings = AudioCodecSettings(
          bitRate: videoSettings.audioBitrate
        )
    }
  
    public static func stopPublish(){
        stream.close()
        connection.close()
        isStreaming = false
    }
    
    public static func setAudioInput(audioInput: Int){
        switch audioInput {
        case 0:
            switchToBluetooth()
            break;

        case 1:
            switchToSpeaker()
            break;

        case 2:
            switchToHeadset()
            break;

        default:
            return;
        }
    }
    
    private static func switchToSpeaker(){
        let inputs: [AVAudioSessionPortDescription] = session.availableInputs!
        
        if let selectedDesc = inputs.first(where: { (desc) -> Bool in
            return desc.portType == AVAudioSession.Port.builtInMic
        }){
            do{
                
                let selectedDataSource = selectedDesc.dataSources?.first(where: { (source) -> Bool in
                    return source.orientation == AVAudioSession.Orientation.front
                })
                
                try session.setPreferredInput(selectedDesc)
                try session.setInputDataSource(selectedDataSource)
            } catch let error{
                print(error)
            }
        }
    }
      
    private static func switchToHeadset(){
        let inputs: [AVAudioSessionPortDescription] = session.availableInputs!

        if let selectedDesc = inputs.first(where: { (desc) -> Bool in
            return desc.portType == AVAudioSession.Port.headsetMic
        }){
            do{
                try session.setPreferredInput(selectedDesc)
            } catch let error{
                print(error)
            }
        }
    }
    
    private static func switchToBluetooth(){
        let inputs: [AVAudioSessionPortDescription] = session.availableInputs!
        
        if let selectedDesc = inputs.first(where: { (desc) -> Bool in
            return desc.portType == AVAudioSession.Port.bluetoothHFP
        }){
            do{
                try session.setPreferredInput(selectedDesc)
            } catch let error{
                print(error)
            }
        }
    }
      

}
