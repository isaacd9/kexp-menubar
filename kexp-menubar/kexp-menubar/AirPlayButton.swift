//
//  AirPlayButton.swift
//  kexp-menubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import AVKit
import SwiftUI

struct AirPlayButton: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.isRoutePickerButtonBordered = false
        return picker
    }

    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {}
}
