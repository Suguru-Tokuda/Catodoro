//
//  DeepLink.swift
//  CatodoroShared
//
//  Created by Suguru Tokuda on 11/12/26.
//

import Foundation

public enum DeepLink {
    public static let scheme = "catodoro"
    public static let timer = URL(string: "\(scheme)://timer")!

    public static func isTimer(_ url: URL) -> Bool {
        url.scheme == scheme && url.host == "timer"
    }
    
}
