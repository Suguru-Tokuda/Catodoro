//
//  AsyncWait.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

@testable import Catodoro
import XCTest

extension XCTestCase {
    /// Waits for work started with a fire-and-forget `Task` (view model actions,
    /// session updates) by polling `condition` on the main actor.
    @MainActor
    func waitUntil(timeout: TimeInterval = 2,
                   _ message: String = "Condition not met in time",
                   file: StaticString = #filePath,
                   line: UInt = #line,
                   _ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() > deadline {
                XCTFail(message, file: file, line: line)
                return
            }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    /// Lets queued main-actor work run, for asserting that something did *not* happen.
    @MainActor
    func settle(_ seconds: TimeInterval = 0.05) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    /// Waits until everything already queued on the shared audio queue has run.
    func flushAudioQueue() async {
        await withCheckedContinuation { continuation in
            AudioManager.playbackQueue.async {
                continuation.resume()
            }
        }
    }
}
