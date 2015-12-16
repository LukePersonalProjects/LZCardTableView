//
//  ALCameraView.swift
//  ALCameraViewController
//
//  Created by Alex Littlejohn on 2015/06/17.
//  Copyright (c) 2015 zero. All rights reserved.
//

import UIKit
import AVFoundation

public typealias CameraShotCompletion = (CIImage) -> Void


public class CameraView: UIView {
  
  var applyFilter: ((CIImage) -> Void)?
  var session: AVCaptureSession!
  var input: AVCaptureDeviceInput!
  var device: AVCaptureDevice!
  var imageOutput: AVCaptureStillImageOutput!
  var videoOutput: AVCaptureVideoDataOutput!
  var videoSize: CGSize!
  var preview: AVCaptureVideoPreviewLayer!
  
  let cameraQueue = dispatch_queue_create("com.mochaka.CameraViewController.Queue", DISPATCH_QUEUE_SERIAL);
  
  public var currentPosition = AVCaptureDevicePosition.Back
  
  public func startSession() {
    createPreview()
    
    dispatch_async(cameraQueue) {
      self.session.startRunning()
    }
  }
  
  public func stopSession() {
    if session != nil {
      dispatch_async(cameraQueue) {
        self.session.stopRunning()
        self.preview.removeFromSuperlayer()
        
        self.session = nil
        self.input = nil
        self.imageOutput = nil
        self.preview = nil
        self.device = nil
      }
    }
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    if let p = preview {
      p.frame = bounds
    }
  }
  
  public func convertImagePoint(point:CGPoint) -> CGPoint{
    return preview.pointForCaptureDevicePointOfInterest(CGPointMake(point.x*1/videoSize.width,1-point.y*1/videoSize.height))
  }
  
  private func createPreview() {
    session = AVCaptureSession()
    session.sessionPreset = AVCaptureSessionPresetHigh
    
    device = cameraWithPosition(currentPosition)
    
    let outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
    
    do {
      input = try AVCaptureDeviceInput(device: device)
    } catch let error as NSError {
      input = nil
      print("Error: \(error.localizedDescription)")
      return
    }
    
    if session.canAddInput(input) {
      session.addInput(input)
    }
    
    imageOutput = AVCaptureStillImageOutput()
    imageOutput.outputSettings = outputSettings
    
    session.addOutput(imageOutput)
    
    videoOutput = AVCaptureVideoDataOutput()
    
    videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA)]
    videoOutput.alwaysDiscardsLateVideoFrames = true
    videoOutput.setSampleBufferDelegate(self, queue: cameraQueue)
    session.addOutput(videoOutput)
    
    preview = AVCaptureVideoPreviewLayer(session: session)
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill
    preview.frame = bounds
    
    layer.addSublayer(preview)
  }
  
  private func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
    let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
    var _device: AVCaptureDevice?
    for d in devices {
      if d.position == position {
        _device = d as? AVCaptureDevice
        break
      }
    }
    
    return _device
  }
  
  public func capturePhoto(completion: CameraShotCompletion) {
    dispatch_async(cameraQueue) {
      let orientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!
      self.takePhoto(self.imageOutput, videoOrientation: orientation, cropSize: self.frame.size, completion:  completion)
    }
  }
  
  func takePhoto(stillImageOutput: AVCaptureStillImageOutput, videoOrientation: AVCaptureVideoOrientation, cropSize: CGSize, completion: CameraShotCompletion) {
    var videoConnection: AVCaptureConnection? = nil
    
    for connection in stillImageOutput.connections {
      for port in (connection as! AVCaptureConnection).inputPorts {
        if port.mediaType == AVMediaTypeVideo {
          videoConnection = connection as? AVCaptureConnection
          break;
        }
      }
      
      if videoConnection != nil {
        break;
      }
    }
    
    videoConnection?.videoOrientation = videoOrientation
    
    stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection!, completionHandler: { buffer, error in
      if buffer != nil {
        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
        let image = CIImage(data: imageData)!
        completion(image)
      }
    })
  }
  
  public func swapCameraInput() {
    if session != nil && input != nil {
      session.beginConfiguration()
      session.removeInput(input)
      
      if input.device.position == AVCaptureDevicePosition.Back {
        currentPosition = AVCaptureDevicePosition.Front
        device = cameraWithPosition(currentPosition)
      } else {
        currentPosition = AVCaptureDevicePosition.Back
        device = cameraWithPosition(currentPosition)
      }
      
      let error = NSErrorPointer()
      do {
        input = try AVCaptureDeviceInput(device: device)
      } catch let error1 as NSError {
        error.memory = error1
        input = nil
      }
      
      session.addInput(input)
      session.commitConfiguration()
    }
  }
  
}

extension CameraView:AVCaptureVideoDataOutputSampleBufferDelegate{
  public func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
    let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
    let opaqueBuffer = Unmanaged<CVImageBuffer>.passUnretained(imageBuffer).toOpaque()
    let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(opaqueBuffer).takeUnretainedValue()
    
    let outputImage = CIImage(CVPixelBuffer: pixelBuffer, options: nil)
    videoSize = outputImage.extent.size
    applyFilter?(outputImage)
  }
}
