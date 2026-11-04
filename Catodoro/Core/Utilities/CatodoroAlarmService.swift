//
//  CatodoroAlarmService.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/3/26.
//

import AlarmKit
import CatodoroShared
import SwiftUI

protocol CatodoroAlarmServiceProtocol {
    func authorize() async throws
    func schedule(id: UUID, title: LocalizedStringResource, session: Int, duration: TimeInterval?, fireDate: Date?) async throws
    func cancel(id: UUID) throws
}

@available(iOS 26.0, *)
@MainActor
final class CatodoroAlarmService {
    enum Failure: Error {
        case authorizationDenied
    }

    func authorize() async throws {
        let manager = AlarmManager.shared
        var state = manager.authorizationState

        if state == .notDetermined {
            state = try await manager.requestAuthorization()
        }

        guard state == .authorized else {
            throw Failure.authorizationDenied
        }
    }

    func schedule(
        id: UUID,
        title: LocalizedStringResource,
        session: Int,
        duration: TimeInterval?,
        fireDate: Date?
    ) async throws {
        // Caller supplies exactly one scheduling mode.
        precondition((duration != nil) != (fireDate != nil))

        let alert: AlarmPresentation.Alert

        if #available(iOS 26.1, *) {
            alert = AlarmPresentation.Alert(title: title)
        } else {
            alert = AlarmPresentation.Alert(
                title: title,
                stopButton: AlarmButton(
                    text: "Dismiss",
                    textColor: .white,
                    systemImageName: "stop.circle"
                )
            )
        }

        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(
                alert: alert,
                countdown: duration == nil ? nil :
                    AlarmPresentation.Countdown(title: "Focus time")
            ),
            metadata: CatodoroAlarmMetadata(session: session),
            tintColor: .orange
        )

        let configuration = AlarmManager.AlarmConfiguration<CatodoroAlarmMetadata>(
            countdownDuration: duration.map {
                Alarm.CountdownDuration(
                    preAlert: $0,
                    postAlert: nil
                )
            },
            schedule: fireDate.map { .fixed($0) },
            attributes: attributes
        )

        _ = try await AlarmManager.shared.schedule(
            id: id,
            configuration: configuration
        )
    }

    func cancel(id: UUID) throws {
        try AlarmManager.shared.cancel(id: id)
    }
}
