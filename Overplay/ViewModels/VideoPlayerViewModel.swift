//
//  VideoPlayerViewModel.swift
//  Overplay
//
//  Created by Juan José Granados Moreno on 9/04/24.
//

import AVKit
import CoreLocation
import CoreMotion

@MainActor
final class VideoPlayerViewModel: NSObject, ObservableObject {
    
    @Published var player: AVPlayer?
    private let videoURLString = Constants.videoURL
    private let locationManager = CLLocationManager()
    private var previousLocation: CLLocation?
    private let motionManager = CMMotionManager()
    private let fileManager = FileManager.default
    
    override init() {
        super.init()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationUpdates()
    }
    
    private func requestLocationUpdates() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default: break
        }
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func downloadVideo() async throws {
        guard let url = URL(string: videoURLString) else { return }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            return
        }
        let videoURL = documentsURL.appendingPathComponent("WeAreGoingOnBullrun.mp4")
        try data.write(to: videoURL)
        setupVideoPlayer(with: videoURL)
    }
    
    
    private func setupVideoPlayer(with videoURL: URL) {
        player = AVPlayer(url: videoURL)
        play()
        startMotionUpdates()
    }
    
    func startMotionUpdates() {
        guard motionManager.isGyroAvailable else {
            return
        }
        motionManager.gyroUpdateInterval = 0.1
        motionManager.startGyroUpdates(to: .main) { [weak self] gyroData, error in
            guard let gyroData, let self else {
                return
            }
            // Update current time
            self.updateCurrentTime(basedOn: gyroData.rotationRate.z)
            
            // Update volumen
            self.updateVolument(basedOn: gyroData.rotationRate.x)
        }
    }
    
    private func updateCurrentTime(basedOn rateZ: Double) {
        guard abs(rateZ) > 1 else { return }
        let currentTime = player?.currentTime() ?? CMTime.zero
        let newSeconds: Double = rateZ > 0 ? -5 : 5
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: newSeconds, preferredTimescale: 1))
        if newTime != currentTime {
            player?.seek(to: newTime)
        }
    }
    
    private func updateVolument(basedOn rateX: Double) {
        let currentVolumen = player?.volume ?? 1.0
        let newVolumen = max(0.0, min(1.0, currentVolumen + Float(rateX) * 0.05))
        player?.volume = newVolumen
    }
    
    func stopMotionUpdates() {
        motionManager.stopGyroUpdates()
    }
    
    func stopMonitoringLocation() {
        locationManager.stopUpdatingLocation()
    }
    
}

// MARK: LocationManagerDelegate
extension VideoPlayerViewModel: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        if let previousLocation {
            let distance = newLocation.distance(from: previousLocation)
            if distance >= 10 {
                self.previousLocation = newLocation
                self.player?.seek(to: .zero)
                self.play()
            }
        } else {
            self.previousLocation = newLocation
        }
    }
    
}
