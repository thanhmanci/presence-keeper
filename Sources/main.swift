import AppKit
import AVFoundation
import IOKit.pwr_mgt
import CoreImage

final class PresenceKeeper: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private let cameraQueue = DispatchQueue(label: "presence.camera")
    private let checkInterval: TimeInterval = 20
    private let exposureWarmup: TimeInterval = 1.0
    private var samplingStartedAt: Date?
    private var screensAsleep = false
    private var activityAssertion: IOPMAssertionID = 0
    private let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: CIContext(options: [.useSoftwareRenderer: false]), options: [CIDetectorAccuracy: CIDetectorAccuracyLow])!

    func start() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else {
                NSLog("PresenceKeeper: camera access denied")
                exit(1)
            }
            self.cameraQueue.async {
                self.configureSession()
                self.sample()
            }
            DispatchQueue.main.async {
                Timer.scheduledTimer(withTimeInterval: self.checkInterval, repeats: true) { _ in
                    self.cameraQueue.async { self.sample() }
                }
            }
        }
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: nil) { _ in
            self.cameraQueue.async { self.screensAsleep = true }
        }
        center.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: nil) { _ in
            self.cameraQueue.async { self.screensAsleep = false }
        }
    }

    private func configureSession() {
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            NSLog("PresenceKeeper: no camera available")
            exit(1)
        }
        session.beginConfiguration()
        session.sessionPreset = .vga640x480
        if session.canAddInput(input) { session.addInput(input) }
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: cameraQueue)
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
    }

    private func sample() {
        guard !screensAsleep, samplingStartedAt == nil else { return }
        samplingStartedAt = Date()
        session.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let startedAt = samplingStartedAt,
              Date().timeIntervalSince(startedAt) >= exposureWarmup,
              let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        samplingStartedAt = nil
        cameraQueue.async { self.session.stopRunning() }
        if faceVisible(in: frame) {
            IOPMAssertionDeclareUserActivity("PresenceKeeper: face in front of camera" as CFString, kIOPMUserActiveLocal, &activityAssertion)
        }
    }

    private func faceVisible(in frame: CVPixelBuffer) -> Bool {
        !faceDetector.features(in: CIImage(cvPixelBuffer: frame)).isEmpty
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let keeper = PresenceKeeper()
keeper.start()
app.run()
