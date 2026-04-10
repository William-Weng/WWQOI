//
//  Extension.swift
//  Example
//
//  Created by William.Weng on 2026/4/11.
//

import Foundation

// MARK: - Int64 (function)
extension Int64 {
    
    /// [單位轉換 (3188 => 3,188 bytes)](https://stackoverflow.com/questions/28268145/get-file-size-in-swift)
    /// - Parameter units: ByteCountFormatter.Units
    /// - Returns: String
    func _bytes(units: ByteCountFormatter.Units = [.useBytes]) -> String {
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = units
        formatter.countStyle = .file
        
        return formatter.string(fromByteCount: self)
    }
}
