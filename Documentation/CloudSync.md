# Preset sync

Catodoro uses `NSPersistentCloudKitContainer` to mirror `PresetEntity` to the private database in `iCloud.com.stokuda.catodoro`. Core Data manages the CloudKit schema, record identity, change tracking, imports, exports, conflicts, accounts, and network retries.

## Ownership

- `AppDependencies` owns one persistence controller, manager, preferences instance, and lifecycle manager.
- `CatodoroPersistentController` opens the existing `CatodoroCoreData.sqlite` URL. It owns the cloud container and one background context shared by all app CRUD and store reconfiguration.
- `CatodoroCoreDataManager` only reads and saves presets. Saving the context is enough for automatic mirroring; there is no pending-action queue or notification to a custom sync engine.
- `SyncLifecycleManager` checks CloudKit account availability on startup, foreground entry, and `CKAccountChanged`; it restores the saved opt-in setting, requests store reconfiguration, and observes Core Data mirroring events for activity and errors.
- Onboarding and Settings ViewModels call the lifecycle manager. Navigation stays in coordinators.
- `PresetsViewModel` reloads value models on persistent-store remote changes so downloaded presets appear while the screen is open.

## Opt-in and runtime changes

The store starts locally. On startup, `MainCoordinator.start()` starts the lifecycle manager, which enables mirroring if `CatodoroPreferences.syncEnabled` is true. Both onboarding choices and the Settings switch take effect in the running app.

The Settings switch shows the effective state: the saved opt-in preference combined with current CloudKit availability. It is disabled while checking availability or when CloudKit reports unavailable. A system-level restriction or a temporary account-check failure does not erase the saved preference. When availability returns, the lifecycle manager reapplies that preference. Account checks use `CKContainer.accountStatus()` for the app’s container, rather than the iCloud Drive identity token. The UI reports availability; there is no direct API here for reading the exact Settings toggle or distinguishing every reason access is unavailable. Validate the system-toggle behavior on a signed-in physical device.

Changing `cloudKitContainerOptions` alone after loading a store doesn't reconfigure it. The controller serializes reconfiguration on the same queue as preset reads and writes: save, reset the writer context, remove the persistent store from its coordinator, change the options, and reload the same SQLite file. Removing a store does not delete its file. If reopening fails, it attempts to restore the previous configuration and reports the error.

History tracking and remote-change notifications remain enabled in both modes. Local inserts, edits, and deletions made while sync is off are retained for Core Data to reconcile when mirroring is enabled again. Disabling mirroring leaves downloaded presets on the device and leaves the cloud database intact.

All app persistence access must use this controller's writer context, and must return value models rather than managed objects. Don't cache managed objects or add a second app writer context without revisiting the reload boundary.

Enabling mirroring is a configuration operation, not a promise that downloading finished. Imports and exports happen asynchronously at system-selected times. There is no forced Sync Now operation, accurate pending-record count, or guaranteed "everything is synced" flag. A successful import/export event only describes that transfer.

See Apple's [setup documentation](https://developer.apple.com/documentation/coredata/setting-up-core-data-with-cloudkit), [synchronization technote](https://developer.apple.com/documentation/technotes/tn3163-understanding-the-synchronization-of-nspersistentcloudkitcontainer), and [history-tracking guidance when disabling mirroring](https://developer.apple.com/forums/thread/118924).

## Model migration

V3 retains `PresetEntity` and removes the obsolete custom-engine bookkeeping entities. Keep V1 and V2 in the model bundle so existing SQLite stores can migrate automatically. The store path and preset UUIDs remain unchanged.

The previous custom CloudKit zone/records are not imported by this implementation. Core Data uses its own schema and record mapping. Presets still in the local SQLite store are migrated and then eligible for mirroring. Recovering records that exist *only* in the old custom CloudKit schema would require a separate one-time importer. No old cloud records or zones are deleted here.

Core Data reconciles managed-object identities; it does not deduplicate independent objects by name or preset UUID. If multiple devices already contain independent copies previously synchronized by the custom engine, a production migration would also need a deduplication strategy.

Before TestFlight/App Store release, initialize/verify the Core Data schema in the development CloudKit environment, then [deploy the schema to production](https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema). Existing custom-engine record types don't replace Core Data's schema. Schema initialization/deployment is not run automatically by this change.

## Verification

Automated tests use SQLite with `cloudIdentifier: nil`, so no test records are uploaded. They exercise migration from V1/V2, store reloads with the same manager, offline updates/deletions, concurrent saves and toggles, preference restoration, mirroring-event status, onboarding, and Settings delegation. They do not exercise a live mirroring delegate or prove cross-device synchronization.

Before release, test with two signed-in devices on the same iCloud account:

1. Create a local preset, enable sync, and verify it appears on the other device alongside that device's presets.
2. Turn sync off, edit/create/delete presets, then turn it back on without relaunching. Verify convergence on both devices.
3. Reinstall on a test device, choose local-only, create a preset, then enable sync from Settings. Verify existing cloud presets and the new local preset appear together.
4. Change a preset on the other device while the preset list is visible. Verify the list updates after import.
5. Test offline operation, reconnection, iCloud sign-out/sign-in/account switching, and rapid toggles; verify errors are visible and local data remains usable.
6. Repeat against the production environment through TestFlight after deploying the schema.

CloudKit import/export timing depends on system scheduling, connectivity, account availability, and push delivery. Allow asynchronous convergence rather than asserting an immediate download on opt-in.
