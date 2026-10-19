import Foundation
import CoreFoundation

/// Relative channel volumes are independent of the existing mute switches.
enum AudioLevels {
    enum Channel: String {
        case music
        case effects

        var defaultsKey: String { "game.\(rawValue)Volume" }
    }

    static func normalized(_ value: Any?) -> Float {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              number.doubleValue.isFinite else { return 1 }
        return Float(min(max(number.doubleValue, 0), 1))
    }

    static func volume(for channel: Channel, defaults: UserDefaults = .standard) -> Float {
        normalized(defaults.object(forKey: channel.defaultsKey))
    }

    @discardableResult
    static func setVolume(_ value: Float, for channel: Channel,
                          defaults: UserDefaults = .standard) -> Float {
        let volume = normalized(value)
        defaults.set(volume, forKey: channel.defaultsKey)
        return volume
    }
}
