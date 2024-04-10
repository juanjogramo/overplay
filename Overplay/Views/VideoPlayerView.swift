//
//  VideoPlayerView.swift
//  Overplay
//
//  Created by Juan José Granados Moreno on 9/04/24.
//

import SwiftUI
import AVKit
import CoreLocation

struct VideoPlayerView: View {
    @ObservedObject var viewModel = VideoPlayerViewModel()
    
    var body: some View {
        VStack {
            if let player = viewModel.player {
                VideoPlayer(player: player)
            } else {
                ProgressView("Downloading...")
                    .task {
                        try? await viewModel.downloadVideo()
                    }
            }
        }
        .onShake {
            viewModel.pause()
        }
    }
}



#Preview {
    VideoPlayerView()
}
