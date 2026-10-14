import Foundation
@testable import Catodoro

final class InMemoryPresetStore: CatodoroCoreDataManaging {
    private var presets: [UUID: PresetModel] = [:]

    func getPresets() async throws -> [PresetModel] { Array(presets.values) }
    func getPreset(id: String) async throws -> PresetModel? {
        UUID(uuidString: id).flatMap { presets[$0] }
    }
    func savePreset(_ preset: PresetModel) async throws { presets[preset.id] = preset }
    func deletePreset(_ id: String) async throws {
        if let uuid = UUID(uuidString: id) { presets[uuid] = nil }
    }
}
