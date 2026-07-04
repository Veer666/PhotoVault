//
//  ByteFormatter.swift
//  PhotoVault
//
//  Created by Vir Daksh on 03/07/26.
//

import Foundation

public struct ByteFormatter {
    /// Formats raw byte size to a human-readable file size string (KB, MB, GB)
    public static func format(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes)
    }
}
