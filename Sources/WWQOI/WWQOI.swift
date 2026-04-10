//
//  WWQOIImage.swift
//  WWQOIImage
//
//  Created by William.Weng on 2026/4/9.
//

import Foundation
import CoreGraphics

public class WWQOI: Sendable {
    
    public static let shared: WWQOI = .init()
    
    private let encoder: Encoder = .init()
    private let decoder: Decoder = .init()
    
    public init() {}
}

// MARK: - 公開函式
public extension WWQOI {
    
    /// 把CGImqe壓縮成.qoi
    /// - Parameter image: CGImage
    /// - Returns: Data
    func encode(image: CGImage) throws -> Data {
        try encoder.execute(with: image)
    }
    
    /// 把.qoi還原成Image
    /// - Parameter data: Data
    /// - Returns: Image
    func decode(data: Data) throws -> Image {
        try decoder.execute(with: data)
    }
}
