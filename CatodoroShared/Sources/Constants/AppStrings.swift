import Foundation

/// User-facing copy shared by the app and widgets. Keep identifiers and resource names separate.
public enum AppStrings {
    private final class BundleToken {}
    private static let bundle = Bundle(for: BundleToken.self)

    /// AlarmKit alert, countdown and paused presentations. AlarmKit takes `LocalizedStringResource`.
    public enum Alarm {
        public static var pauseButton: LocalizedStringResource {
            LocalizedStringResource("alarm.pauseButton", defaultValue: "Pause", bundle: .atURL(bundle.bundleURL))
        }

        public static var resumeButton: LocalizedStringResource {
            LocalizedStringResource("alarm.resumeButton", defaultValue: "Resume", bundle: .atURL(bundle.bundleURL))
        }

        public static var restartButton: LocalizedStringResource {
            LocalizedStringResource("alarm.restartButton", defaultValue: "Restart", bundle: .atURL(bundle.bundleURL))
        }

        public static var skipBreakButton: LocalizedStringResource {
            LocalizedStringResource("alarm.skipBreakButton", defaultValue: "Skip break", bundle: .atURL(bundle.bundleURL))
        }

        public static var paused: LocalizedStringResource {
            LocalizedStringResource("alarm.paused", defaultValue: "Paused", bundle: .atURL(bundle.bundleURL))
        }

        public static var cycleComplete: LocalizedStringResource {
            LocalizedStringResource("alarm.cycleComplete", defaultValue: "Cycle complete", bundle: .atURL(bundle.bundleURL))
        }

        public static var focusComplete: LocalizedStringResource {
            LocalizedStringResource("alarm.focusComplete", defaultValue: "Focus complete", bundle: .atURL(bundle.bundleURL))
        }

        public static var breakOver: LocalizedStringResource {
            LocalizedStringResource("alarm.breakOver", defaultValue: "Break's over", bundle: .atURL(bundle.bundleURL))
        }

        public static var catnapBreak: LocalizedStringResource {
            LocalizedStringResource("alarm.catnapBreak", defaultValue: "Catnap break", bundle: .atURL(bundle.bundleURL))
        }

        public static func focusCountdown(_ interval: Int, of total: Int) -> LocalizedStringResource {
            LocalizedStringResource("alarm.focusCountdown", defaultValue: "Focus · \(interval) of \(total)", bundle: .atURL(bundle.bundleURL))
        }
    }

    public enum AlertStyles {
        public static let alarmTitle = String(localized: "alertStyles.alarmTitle", defaultValue: "Alarm", bundle: bundle)

        public static let notificationTitle = String(localized: "alertStyles.notificationTitle", defaultValue: "Notification", bundle: bundle)

        public static let liveActivityTitle = String(localized: "alertStyles.liveActivityTitle", defaultValue: "Live Activity Only", bundle: bundle)

        public static let alarmDetail = String(localized: "alertStyles.alarmDetail", defaultValue: "Rings like an alarm when a phase ends, even in Silent mode.", bundle: bundle)

        public static let notificationDetail = String(localized: "alertStyles.notificationDetail", defaultValue: "Shows a notification with sound when a phase ends.", bundle: bundle)

        public static let liveActivityDetail = String(localized: "alertStyles.liveActivityDetail", defaultValue: "Shows the countdown on the Lock Screen. No alert sounds when a phase ends while you're away.", bundle: bundle)

        public static let alarmsTurnedOff = String(localized: "alertStyles.alarmsTurnedOff", defaultValue: "Alarms are turned off", bundle: bundle)

        public static let notificationsTurnedOff = String(localized: "alertStyles.notificationsTurnedOff", defaultValue: "Notifications are turned off", bundle: bundle)

        public static let allowAlarmsInSettings = String(localized: "alertStyles.allowAlarmsInSettings", defaultValue: "Allow alarms for Catodoro in Settings to use this alert style.", bundle: bundle)

        public static let allowNotificationsInSettings = String(localized: "alertStyles.allowNotificationsInSettings", defaultValue: "Allow notifications for Catodoro in Settings to use this alert style.", bundle: bundle)

        public static let openSettings = String(localized: "alertStyles.openSettings", defaultValue: "Open Settings", bundle: bundle)
    }

    public enum Colors {
        public static let blue = String(localized: "colors.blue", defaultValue: "Blue", bundle: bundle)

        public static let green = String(localized: "colors.green", defaultValue: "Green", bundle: bundle)

        public static let orange = String(localized: "colors.orange", defaultValue: "Orange", bundle: bundle)

        public static let pink = String(localized: "colors.pink", defaultValue: "Pink", bundle: bundle)

        public static let purple = String(localized: "colors.purple", defaultValue: "Purple", bundle: bundle)

        public static let yellow = String(localized: "colors.yellow", defaultValue: "Yellow", bundle: bundle)
    }

    public enum Common {
        public static let routine = String(localized: "common.routine", defaultValue: "Routine", bundle: bundle)

        public static let catnapBreak = String(localized: "common.catnapBreak", defaultValue: "Catnap break", bundle: bundle)

        public static let catodoro = String(localized: "common.catodoro", defaultValue: "Catodoro", bundle: bundle)

        public static let chooseYourCat = String(localized: "common.chooseYourCat", defaultValue: "Choose your cat", bundle: bundle)

        public static let close = String(localized: "common.close", defaultValue: "Close", bundle: bundle)

        public static let focus = String(localized: "common.focus", defaultValue: "Focus", bundle: bundle)

        public static let focusAgain = String(localized: "common.focusAgain", defaultValue: "Focus again", bundle: bundle)

        public static let focusTime = String(localized: "common.focusTime", defaultValue: "Focus time", bundle: bundle)

        public static let noBreak = String(localized: "common.noBreak", defaultValue: "No break", bundle: bundle)

        public static let notSelected = String(localized: "common.notSelected", defaultValue: "Not Selected", bundle: bundle)

        public static let end = String(localized: "common.end", defaultValue: "End", bundle: bundle)

        public static let ok = String(localized: "common.ok", defaultValue: "OK", bundle: bundle)

        public static let pause = String(localized: "common.pause", defaultValue: "Pause", bundle: bundle)

        public static let paused = String(localized: "common.paused", defaultValue: "Paused", bundle: bundle)

        public static let presetName = String(localized: "common.presetName", defaultValue: "Preset name", bundle: bundle)

        public static let presets = String(localized: "common.presets", defaultValue: "Presets", bundle: bundle)

        public static let restYourPaws = String(localized: "common.restYourPaws", defaultValue: "Rest your paws.", bundle: bundle)

        public static let resume = String(localized: "common.resume", defaultValue: "Resume", bundle: bundle)

        public static let retry = String(localized: "common.retry", defaultValue: "Retry", bundle: bundle)

        public static let routineComplete = String(localized: "common.routineComplete", defaultValue: "Routine complete", bundle: bundle)

        public static let selected = String(localized: "common.selected", defaultValue: "Selected", bundle: bundle)

        public static let sessions = String(localized: "common.sessions", defaultValue: "Sessions", bundle: bundle)

        public static let settings = String(localized: "common.settings", defaultValue: "Settings", bundle: bundle)

        public static let skipBreak = String(localized: "common.skipBreak", defaultValue: "Skip break", bundle: bundle)

        public static let start = String(localized: "common.start", defaultValue: "Start", bundle: bundle)

        public static let timeRemaining = String(localized: "common.timeRemaining", defaultValue: "Time remaining", bundle: bundle)

        public static let timeToFocus = String(localized: "common.timeToFocus", defaultValue: "Time to focus.", bundle: bundle)

        public static let totalTime = String(localized: "common.totalTime", defaultValue: "Total time", bundle: bundle)
    }

    /// `CountdownError` descriptions.
    public enum CountdownErrors {
        public static let alreadyRunning = String(localized: "countdownErrors.alreadyRunning", defaultValue: "A countdown is already running.", bundle: bundle)

        public static let alarmKitUnavailable = String(localized: "countdownErrors.alarmKitUnavailable", defaultValue: "AlarmKit requires iOS 26.", bundle: bundle)

        public static let invalidSteps = String(localized: "countdownErrors.invalidSteps", defaultValue: "Invalid steps", bundle: bundle)

        public static let notAuthorized = String(localized: "countdownErrors.notAuthorized", defaultValue: "Permission was not granted.", bundle: bundle)
    }

    /// Developer-facing messages for preconditions, crashes and debug identifiers.
    /// Never shown to users, so not localized.
    public enum Diagnostics {
        public static let onboardingNeedsSteps = "Onboarding needs at least one step"

        public static let initCoderNotImplemented = "init(coder:) has not been implemented"

        public static let missingStoreDescription = "Unable to get a persistent store description."

        public static func localStoreLoadFailed(_ error: Error) -> String {
            "Unable to load Catodoro's local store: \(error)"
        }

        public static func localStoreReopenFailed(_ error: Error) -> String {
            "Couldn't reopen the local store: \(error)"
        }

        public static let phaseTransitionTaskName = "Catodoro phase transition"
    }

    /// Titles of the phase-end notifications.
    public enum Notifications {
        public static let cycleComplete = String(localized: "notifications.cycleComplete", defaultValue: "Cycle complete", bundle: bundle)

        public static let focusCompleteBreakNext = String(localized: "notifications.focusCompleteBreakNext", defaultValue: "Focus complete · Break next", bundle: bundle)

        public static let breakOverFocusNext = String(localized: "notifications.breakOverFocusNext", defaultValue: "Break's over · Focus next", bundle: bundle)
    }

    public enum Onboarding {
        public static let bringBackPresetsAlreadySavedInICloud = String(localized: "onboarding.bringBackPresetsAlreadySavedInICloud", defaultValue: "Bring back presets already saved in iCloud", bundle: bundle)

        public static let catodoro = String(localized: "onboarding.catodoro", defaultValue: "CATODORO", bundle: bundle)

        public static let continueOnThisDevice = String(localized: "onboarding.continueOnThisDevice", defaultValue: "Continue on This Device", bundle: bundle)

        public static let enableSyncError = String(localized: "onboarding.enableSyncError", defaultValue: "Couldn’t enable iCloud Sync. Please try again, or continue on this device.", bundle: bundle)

        public static let updateSyncError = String(localized: "onboarding.updateSyncError", defaultValue: "Couldn't update sync settings. Please try again.", bundle: bundle)

        public static let enableICloudSync = String(localized: "onboarding.enableICloudSync", defaultValue: "Enable iCloud Sync", bundle: bundle)

        public static let keepFocusingAndSavingPresetsOffline = String(localized: "onboarding.keepFocusingAndSavingPresetsOffline", defaultValue: "Keep focusing and saving presets offline", bundle: bundle)

        public static let keepPresetsInSyncAcrossYourDevices = String(localized: "onboarding.keepPresetsInSyncAcrossYourDevices", defaultValue: "Keep presets in sync across your devices", bundle: bundle)

        public static let syncDescription = String(localized: "onboarding.syncDescription", defaultValue: "Keep your presets together with iCloud, or start with everything on this device.", bundle: bundle)

        public static let retryICloudSync = String(localized: "onboarding.retryICloudSync", defaultValue: "Retry iCloud Sync", bundle: bundle)

        public static let youCanChangeThisLaterInSettings = String(localized: "onboarding.youCanChangeThisLaterInSettings", defaultValue: "You can change this later in Settings.", bundle: bundle)

        public static let headline = String(localized: "onboarding.headline", defaultValue: "Your routines,\nwherever you focus.", bundle: bundle)

        public static let alertHeadline = String(localized: "onboarding.alertHeadline", defaultValue: "Know when\neach phase ends.", bundle: bundle)

        public static let alarmDescription = String(localized: "onboarding.alarmDescription", defaultValue: "Catodoro can ring an alarm when a focus session or catnap ends, even if your iPhone is locked or in Silent mode.", bundle: bundle)

        public static let notificationDescription = String(localized: "onboarding.notificationDescription", defaultValue: "Catodoro can send a notification when a focus session or catnap ends, even when the app is closed.", bundle: bundle)

        public static let alarmRingsInSilentMode = String(localized: "onboarding.alarmRingsInSilentMode", defaultValue: "Rings even in Silent mode or a Focus", bundle: bundle)

        public static let alarmShowsCountdownOnLockScreen = String(localized: "onboarding.alarmShowsCountdownOnLockScreen", defaultValue: "Shows the countdown on the Lock Screen and in the Dynamic Island", bundle: bundle)

        public static let alarmStopFromLockScreen = String(localized: "onboarding.alarmStopFromLockScreen", defaultValue: "Stop the alarm right from the Lock Screen", bundle: bundle)

        public static let notificationAlertsWhenPhaseEnds = String(localized: "onboarding.notificationAlertsWhenPhaseEnds", defaultValue: "Get an alert when each phase ends", bundle: bundle)

        public static let notificationShowsOnLockScreen = String(localized: "onboarding.notificationShowsOnLockScreen", defaultValue: "See it on the Lock Screen, even when Catodoro is closed", bundle: bundle)

        public static let allowAlarms = String(localized: "onboarding.allowAlarms", defaultValue: "Allow Alarms", bundle: bundle)

        public static let allowNotifications = String(localized: "onboarding.allowNotifications", defaultValue: "Allow Notifications", bundle: bundle)

        public static let notNow = String(localized: "onboarding.notNow", defaultValue: "Not Now", bundle: bundle)
    }

    public enum Presets {
        public static let catnapCat = String(localized: "presets.catnapCat", defaultValue: "Catnap cat", bundle: bundle)

        public static let couldntSavePreset = String(localized: "presets.couldntSavePreset", defaultValue: "Couldn't save preset", bundle: bundle)

        public static let couldntUpdatePresets = String(localized: "presets.couldntUpdatePresets", defaultValue: "Couldn't update presets", bundle: bundle)

        public static let createPreset = String(localized: "presets.createPreset", defaultValue: "Create preset", bundle: bundle)

        public static func defaultName(_ duration: String) -> String {
            String(localized: "presets.defaultName", defaultValue: "\(duration) focus", bundle: bundle)
        }

        public static let editPreset = String(localized: "presets.editPreset", defaultValue: "Edit preset", bundle: bundle)

        public static let focusCat = String(localized: "presets.focusCat", defaultValue: "Focus cat", bundle: bundle)

        public static let newPreset = String(localized: "presets.newPreset", defaultValue: "New preset", bundle: bundle)

        public static let playfulCat = String(localized: "presets.playfulCat", defaultValue: "Playful cat", bundle: bundle)

        public static let updateErrorMessage = String(localized: "presets.updateErrorMessage", defaultValue: "Please try again. Your saved presets have not been removed.", bundle: bundle)

        public static func routineSummary(_ focus: String, _ catnap: String, _ sessions: Int) -> String {
            String(localized: "presets.routineSummary", defaultValue: "\(focus) focus · \(catnap) break · \(sessions) sessions", bundle: bundle)
        }

        public static let emptyMessage = String(localized: "presets.emptyMessage", defaultValue: "Save a favorite rhythm and choose a cat to keep you company.", bundle: bundle)

        public static let savePreset = String(localized: "presets.savePreset", defaultValue: "Save preset", bundle: bundle)

        public static let sittingCat = String(localized: "presets.sittingCat", defaultValue: "Sitting cat", bundle: bundle)

        public static let sleepingCat = String(localized: "presets.sleepingCat", defaultValue: "Sleeping cat", bundle: bundle)

        public static func startNamedPreset(_ name: String) -> String {
            String(localized: "presets.startNamedPreset", defaultValue: "Start \(name)", bundle: bundle)
        }

        public static let startPreset = String(localized: "presets.startPreset", defaultValue: "Start preset", bundle: bundle)

        public static let stretchingCat = String(localized: "presets.stretchingCat", defaultValue: "Stretching cat", bundle: bundle)

        public static func totalDuration(_ duration: String) -> String {
            String(localized: "presets.totalDuration", defaultValue: "Total: \(duration)", bundle: bundle)
        }

        public static let saveErrorMessage = String(localized: "presets.saveErrorMessage", defaultValue: "Your changes are still here. Please try again.", bundle: bundle)

        public static let emptyTitle = String(localized: "presets.emptyTitle", defaultValue: "Your routines belong here", bundle: bundle)
    }

    public enum Resources {
        public static var appName: LocalizedStringResource {
            LocalizedStringResource("resources.appName", defaultValue: "Catodoro", bundle: .atURL(bundle.bundleURL))
        }

        public static var restYourPaws: LocalizedStringResource {
            LocalizedStringResource("resources.restYourPaws", defaultValue: "Rest your paws.", bundle: .atURL(bundle.bundleURL))
        }

        public static var routineComplete: LocalizedStringResource {
            LocalizedStringResource("resources.routineComplete", defaultValue: "Routine complete", bundle: .atURL(bundle.bundleURL))
        }

        public static var timeToFocus: LocalizedStringResource {
            LocalizedStringResource("resources.timeToFocus", defaultValue: "Time to focus.", bundle: .atURL(bundle.bundleURL))
        }
    }

    public enum Settings {
        public static let accentColor = String(localized: "settings.accentColor", defaultValue: "Accent color", bundle: bundle)

        public static func accentLabel(_ color: String) -> String {
            String(localized: "settings.accentLabel", defaultValue: "\(color) accent", bundle: bundle)
        }

        public static let checkingICloudAvailability = String(localized: "settings.checkingICloudAvailability", defaultValue: "Checking iCloud availability…", bundle: bundle)

        public static let alarm = String(localized: "settings.alarm", defaultValue: "Alarm", bundle: bundle)

        public static let color = String(localized: "settings.color", defaultValue: "Color", bundle: bundle)

        public static let couldntPreviewSound = String(localized: "settings.couldntPreviewSound", defaultValue: "Couldn't preview sound", bundle: bundle)

        public static let darkTheme = String(localized: "settings.darkTheme", defaultValue: "Dark", bundle: bundle)

        public static let enableSyncMessage = String(localized: "settings.enableSyncMessage", defaultValue: "Enable iCloud for Catodoro in iOS iCloud Settings to sync your presets.", bundle: bundle)

        public static let icloudSync = String(localized: "settings.icloudSync", defaultValue: "iCloud Sync", bundle: bundle)

        public static let liveActivityDescription = String(localized: "settings.liveActivityDescription", defaultValue: "Keep your timer and cat nearby on the Lock Screen and Dynamic Island.", bundle: bundle)

        public static let lightTheme = String(localized: "settings.lightTheme", defaultValue: "Light", bundle: bundle)

        public static let liveActivityUnavailableMessage = String(localized: "settings.liveActivityUnavailableMessage", defaultValue: "Live Activities are unavailable or disabled in iOS Settings. Your app preference is saved.", bundle: bundle)

        public static let liveActivity = String(localized: "settings.liveActivity", defaultValue: "Live Activity", bundle: bundle)

        public static let openIOSSettings = String(localized: "settings.openIOSSettings", defaultValue: "Open iOS Settings", bundle: bundle)

        public static let pleaseTryAgain = String(localized: "settings.pleaseTryAgain", defaultValue: "Please try again.", bundle: bundle)

        public static let localPresetsMessage = String(localized: "settings.localPresetsMessage", defaultValue: "Presets stay on this device. Turn on iCloud to merge them with your other devices.", bundle: bundle)

        public static let syncEnabledMessage = String(localized: "settings.syncEnabledMessage", defaultValue: "Presets sync automatically when iCloud is available.", bundle: bundle)

        public static let sound = String(localized: "settings.sound", defaultValue: "Sound", bundle: bundle)

        public static let syncingPresetsWithICloud = String(localized: "settings.syncingPresetsWithICloud", defaultValue: "Syncing presets with iCloud…", bundle: bundle)

        public static let systemTheme = String(localized: "settings.systemTheme", defaultValue: "System", bundle: bundle)

        public static let theme = String(localized: "settings.theme", defaultValue: "Theme", bundle: bundle)

        public static let timerSound = String(localized: "settings.timerSound", defaultValue: "Timer sound", bundle: bundle)

        public static let yourCozyCorner = String(localized: "settings.yourCozyCorner", defaultValue: "Your cozy corner", bundle: bundle)
    }

    public enum Sounds {
        public static let angry = String(localized: "sounds.angry", defaultValue: "Angry", bundle: bundle)

        public static let hungry = String(localized: "sounds.hungry", defaultValue: "Hungry", bundle: bundle)

        public static let kitty = String(localized: "sounds.kitty", defaultValue: "Kitty", bundle: bundle)

        public static let meowLoud = String(localized: "sounds.meowLoud", defaultValue: "Meow (Loud)", bundle: bundle)

        public static let meowRegular = String(localized: "sounds.meowRegular", defaultValue: "Meow (Regular)", bundle: bundle)
    }

    public enum Sync {
        public static let restrictedMessage = String(localized: "sync.restrictedMessage", defaultValue: "iCloud access is restricted. Check your device’s iCloud restrictions.", bundle: bundle)

        public static let temporarilyUnavailableMessage = String(localized: "sync.temporarilyUnavailableMessage", defaultValue: "iCloud is temporarily unavailable. Catodoro will check again when you return to the app.", bundle: bundle)

        public static let unavailableMessage = String(localized: "sync.unavailableMessage", defaultValue: "iCloud is unavailable right now. Your presets remain available locally.", bundle: bundle)

        public static let signInMessage = String(localized: "sync.signInMessage", defaultValue: "iCloud is unavailable. Sign in to iCloud and enable Catodoro in iOS iCloud Settings.", bundle: bundle)
    }

    public enum Timer {
        public static let secondUnit = String(localized: "timer.secondUnit", defaultValue: "sec", bundle: bundle)

        public static let minuteUnit = String(localized: "timer.minuteUnit", defaultValue: "min", bundle: bundle)

        public static let hourUnit = String(localized: "timer.hourUnit", defaultValue: "hr", bundle: bundle)

        public static let breaks = String(localized: "timer.breaks", defaultValue: "Breaks", bundle: bundle)

        public static let minutes = String(localized: "timer.minutes", defaultValue: "Minutes", bundle: bundle)

        public static let focusSessions = String(localized: "timer.focusSessions", defaultValue: "Focus sessions", bundle: bundle)

        public static let zeroMinutes = String(localized: "timer.zeroMinutes", defaultValue: "0 min", bundle: bundle)

        public static let aLittleTimeForDeepFocus = String(localized: "timer.aLittleTimeForDeepFocus", defaultValue: "A little time for deep focus.", bundle: bundle)

        public static func aboutFocusTime(_ total: String) -> String {
            String(localized: "timer.aboutFocusTime", defaultValue: "About \(total) of focus time.", bundle: bundle)
        }

        public static func aboutIncludingBreaks(_ total: String) -> String {
            String(localized: "timer.aboutIncludingBreaks", defaultValue: "About \(total), including breaks.", bundle: bundle)
        }

        public static let backToRoutine = String(localized: "timer.backToRoutine", defaultValue: "Back to routine", bundle: bundle)

        public static let breaksHappenBetweenSessions = String(localized: "timer.breaksHappenBetweenSessions", defaultValue: "Breaks happen between sessions.", bundle: bundle)

        public static let catodoroTimer = String(localized: "timer.catodoroTimer", defaultValue: "Catodoro Timer", bundle: bundle)

        public static let sessionRange = String(localized: "timer.sessionRange", defaultValue: "Choose 1–20 sessions", bundle: bundle)

        public static let invalidFocusDuration = String(localized: "timer.invalidFocusDuration", defaultValue: "Choose a focus time greater than zero.", bundle: bundle)

        public static let createARoutine = String(localized: "timer.createARoutine", defaultValue: "Create a routine", bundle: bundle)

        public static func durationTimesCount(_ duration: String, _ count: Int) -> String {
            String(localized: "timer.durationTimesCount", defaultValue: "\(duration) × \(count)", bundle: bundle)
        }

        public static let endSession = String(localized: "timer.endSession", defaultValue: "End session", bundle: bundle)

        public static let fewerSessions = String(localized: "timer.fewerSessions", defaultValue: "Fewer sessions", bundle: bundle)

        public static let focusSession = String(localized: "timer.focusSession", defaultValue: "Focus session", bundle: bundle)

        public static func focusSessionCount(_ count: Int) -> String {
            String(localized: "timer.focusSessionCount", defaultValue: "\(count) focus sessions", bundle: bundle)
        }

        public static let hours = String(localized: "timer.hours", defaultValue: "Hours", bundle: bundle)

        public static let sessionPrompt = String(localized: "timer.sessionPrompt", defaultValue: "How many focus sessions would you like?", bundle: bundle)

        public static func minuteCount(_ count: Int) -> String {
            String(localized: "timer.minuteCount", defaultValue: "\(count) min", bundle: bundle)
        }

        public static let moreSessions = String(localized: "timer.moreSessions", defaultValue: "More sessions", bundle: bundle)

        public static func nextSession(_ current: Int, _ total: Int) -> String {
            String(localized: "timer.nextSession", defaultValue: "Next: session \(current) of \(total)", bundle: bundle)
        }

        public static let noBreaks = String(localized: "timer.noBreaks", defaultValue: "No breaks", bundle: bundle)

        public static let onePawAtATime = String(localized: "timer.onePawAtATime", defaultValue: "One paw at a time.", bundle: bundle)

        public static let onePawAtATimeYouDidIt = String(localized: "timer.onePawAtATimeYouDidIt", defaultValue: "One paw at a time. You did it!", bundle: bundle)

        public static let restYourPawsBetweenSessions = String(localized: "timer.restYourPawsBetweenSessions", defaultValue: "Rest your paws between sessions.", bundle: bundle)

        public static let seconds = String(localized: "timer.seconds", defaultValue: "Seconds", bundle: bundle)

        public static func sessionOf(_ current: Int, _ total: Int) -> String {
            String(localized: "timer.sessionOf", defaultValue: "Session \(current) of \(total)", bundle: bundle)
        }

        public static func sessionProgress(_ current: Int, _ total: Int) -> String {
            String(localized: "timer.sessionProgress", defaultValue: "\(current) of \(total)", bundle: bundle)
        }

        public static func sessionsCompleted(_ count: Int) -> String {
            String(localized: "timer.sessionsCompleted", defaultValue: "\(count) sessions completed", bundle: bundle)
        }

        public static let setBreakTime = String(localized: "timer.setBreakTime", defaultValue: "Set break time", bundle: bundle)

        public static let setFocusTime = String(localized: "timer.setFocusTime", defaultValue: "Set focus time", bundle: bundle)

        public static let setSessions = String(localized: "timer.setSessions", defaultValue: "Set sessions", bundle: bundle)

        public static let startFocusing = String(localized: "timer.startFocusing", defaultValue: "Start focusing", bundle: bundle)

        public static let timerConfig = String(localized: "timer.timerConfig", defaultValue: "Timer Config", bundle: bundle)

        public static let unavailable = String(localized: "timer.unavailable", defaultValue: "Unavailable", bundle: bundle)

        public static let wellDone = String(localized: "timer.wellDone", defaultValue: "Well done!", bundle: bundle)

        public static let yourCatIsKeepingYouCompany = String(localized: "timer.yourCatIsKeepingYouCompany", defaultValue: "Your cat is keeping you company.", bundle: bundle)

        public static let yourFocusRoutine = String(localized: "timer.yourFocusRoutine", defaultValue: "Your focus routine", bundle: bundle)

        public static let yourRoutineWillBeHereWhenYoureReady = String(localized: "timer.yourRoutineWillBeHereWhenYoureReady", defaultValue: "Your routine will be here when you’re ready.", bundle: bundle)
    }

    public enum Widget {
        public static let emoji = String(localized: "widget.emoji", defaultValue: "Emoji:", bundle: bundle)

        public static let myWidget = String(localized: "widget.myWidget", defaultValue: "My Widget", bundle: bundle)

        public static let thisIsAnExampleWidget = String(localized: "widget.thisIsAnExampleWidget", defaultValue: "This is an example widget.", bundle: bundle)

        public static let time = String(localized: "widget.time", defaultValue: "Time:", bundle: bundle)

        public static let openToContinue = String(localized: "widget.openToContinue", defaultValue: "Open Catodoro to continue", bundle: bundle)
    }
}
