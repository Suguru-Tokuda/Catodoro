//
//  SyncError.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import Foundation

enum SyncError: Error {
    case differentAccount
    case iCloudUnavailable
    case invalidMetadata
}
