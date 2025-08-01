//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import _Concurrency

/// The build configuration, such as debug or release.
public struct BuildConfiguration: Sendable {
    /// The configuration of the build. Valid values are `debug` and `release`.
    let config: String

    private init(_ config: String) {
        self.config = config
    }

    /// The debug build configuration.
    public static let debug: BuildConfiguration = BuildConfiguration("debug")

    /// The release build configuration.
    public static let release: BuildConfiguration = BuildConfiguration("release")
}

/// A condition that limits the application of a build setting.
///
/// By default, build settings are applicable for all platforms and build
/// configurations. Use the `.when` modifier to define a build setting for a
/// specific condition. Invalid usage of `.when` emits an error during manifest
/// parsing. For example, it's invalid to specify a `.when` condition with both
/// parameters as `nil`.
///
/// The following example shows how to use build setting conditions with various
/// APIs:
///
/// ```swift
/// ...
/// .target(
///     name: "MyTool",
///     dependencies: ["Utility"],
///     cSettings: [
///         .headerSearchPath("path/relative/to/my/target"),
///         .define("DISABLE_SOMETHING", .when(platforms: [.iOS], configuration: .release)),
///     ],
///     swiftSettings: [
///         .define("ENABLE_SOMETHING", .when(configuration: .release)),
///     ],
///     linkerSettings: [
///         .linkLibrary("openssl", .when(platforms: [.linux])),
///     ]
/// ),
/// ```
public struct BuildSettingCondition: Sendable {
    /// The applicable platforms for this build setting condition.
    let platforms: [Platform]?
    /// The applicable build configuration for this build setting condition.
    let config: BuildConfiguration?
    /// The applicable traits for this build setting condition.
    let traits: Set<String>?

    private init(platforms: [Platform]?, config: BuildConfiguration?, traits: Set<String>?) {
        self.platforms = platforms
        self.config = config
        self.traits = traits
    }

    @available(_PackageDescription, deprecated: 5.7)
    public static func when(
        platforms: [Platform]? = nil,
        configuration: BuildConfiguration? = nil
    ) -> BuildSettingCondition {
        precondition(!(platforms == nil && configuration == nil))
        return BuildSettingCondition(platforms: platforms, config: configuration, traits: nil)
    }

    /// Creates a build setting condition.
    ///
    /// - Parameters:
    ///   - platforms: The applicable platforms for this build setting condition.
    ///   - configuration: The applicable build configuration for this build setting condition.
    ///   - traits: The applicable traits for this build setting condition.
    @available(_PackageDescription, introduced: 6.1)
    public static func when(
        platforms: [Platform]? = nil,
        configuration: BuildConfiguration? = nil,
        traits: Set<String>? = nil
    ) -> BuildSettingCondition {
        precondition(!(platforms == nil && configuration == nil && traits == nil))
        return BuildSettingCondition(platforms: platforms, config: configuration, traits: traits)
    }

    /// Creates a build setting condition.
    ///
    /// - Parameters:
    ///   - platforms: The applicable platforms for this build setting condition.
    ///   - configuration: The applicable build configuration for this build setting condition.
    @available(_PackageDescription, introduced: 5.7)
    public static func when(platforms: [Platform], configuration: BuildConfiguration) -> BuildSettingCondition {
        BuildSettingCondition(platforms: platforms, config: configuration, traits: nil)
    }

    /// Creates a build setting condition.
    ///
    /// - Parameter platforms: The applicable platforms for this build setting condition.
    @available(_PackageDescription, introduced: 5.7)
    public static func when(platforms: [Platform]) -> BuildSettingCondition {
        BuildSettingCondition(platforms: platforms, config: .none, traits: nil)
    }

    /// Creates a build setting condition.
    ///
    /// - Parameter configuration: The applicable build configuration for this build setting condition.
    @available(_PackageDescription, introduced: 5.7)
    public static func when(configuration: BuildConfiguration) -> BuildSettingCondition {
        BuildSettingCondition(platforms: .none, config: configuration, traits: nil)
    }
}

/// The underlying build setting data.
struct BuildSettingData {

    /// The name of the build setting.
    let name: String

    /// The value of the build setting.
    let value: [String]

    /// A condition that restricts the application of the build setting.
    let condition: BuildSettingCondition?
}

/// A C language build setting.
public struct CSetting: Sendable {
    /// The abstract build setting data.
    let data: BuildSettingData

    private init(name: String, value: [String], condition: BuildSettingCondition?) {
        self.data = BuildSettingData(name: name, value: value, condition: condition)
    }

    /// Provides a header search path relative to the target's directory.
    ///
    /// Use this setting to add a search path for headers within your target.
    /// You can't use absolute paths and you can't use this setting to provide
    /// headers that are visible to other targets.
    ///
    /// The path must be a directory inside the package.
    ///
    /// - Since: First available in PackageDescription 5.0.
    ///
    /// - Parameters:
    ///   - path: The path of the directory that contains the headers. The path is relative to the target's directory.
    ///   - condition: A condition that restricts the use of the build setting.
    @available(_PackageDescription, introduced: 5.0)
    public static func headerSearchPath(_ path: String, _ condition: BuildSettingCondition? = nil) -> CSetting {
        return CSetting(name: "headerSearchPath", value: [path], condition: condition)
    }

    /// Defines a value for a macro.
    ///
    /// If you don't specify a value, the macro's default value is 1.
    ///
    /// - Since: First available in PackageDescription 5.0.
    ///
    /// - Parameters:
    ///   - name: The name of the macro.
    ///   - value: The value of the macro.
    ///   - condition: A condition that restricts the use of the build
    /// setting.
    @available(_PackageDescription, introduced: 5.0)
    public static func define(_ name: String, to value: String? = nil, _ condition: BuildSettingCondition? = nil) -> CSetting {
        var settingValue = name
        if let value {
            settingValue += "=" + value
        }
        return CSetting(name: "define", value: [settingValue], condition: condition)
    }

    /// Sets unsafe flags to pass arbitrary command-line flags to the
    /// corresponding build tool.
    ///
    /// As the usage of the word “unsafe” implies, Swift Package Manager can't safely determine
    /// if the build flags have any negative side effect on the build since
    /// certain flags can change the behavior of how it performs a build.
    ///
    /// As some build flags can be exploited for unsupported or malicious
    /// behavior, the use of unsafe flags makes the products containing this
    /// target ineligible for use by other packages.
    ///
    /// - Since: First available in PackageDescription 5.0.
    ///
    /// - Parameters:
    ///   - flags: The unsafe flags to set.
    ///   - condition: A condition that restricts the application of the build
    /// setting.
    @available(_PackageDescription, introduced: 5.0)
    public static func unsafeFlags(_ flags: [String], _ condition: BuildSettingCondition? = nil) -> CSetting {
        return CSetting(name: "unsafeFlags", value: flags, condition: condition)
    }
    
    /// Controls how all C compiler warnings are treated during compilation.
    ///
    /// Use this setting to specify whether all warnings should be treated as warnings (default behavior)
    /// or as errors. This is equivalent to passing `-Werror` or `-Wno-error`
    /// to the C compiler.
    ///
    /// This setting applies to all warnings emitted by the C compiler. To control specific
    /// warnings individually, use `treatWarning(name:as:_:)` instead.
    ///
    /// - Since: First available in PackageDescription 6.2.
    ///
    /// - Parameters:
    ///   - level: The treatment level for all warnings (`.warning` or `.error`).
    ///   - condition: A condition that restricts the application of the build setting.
    @available(_PackageDescription, introduced: 6.2)
    public static func treatAllWarnings(
      as level: WarningLevel,
      _ condition: BuildSettingCondition? = nil
    ) -> CSetting {
        return CSetting(
            name: "treatAllWarnings", value: [level.rawValue], condition: condition)
    }

    /// Controls how a specific C compiler warning is treated during compilation.
    ///
    /// Use this setting to specify whether a particular warning should be treated as a warning
    /// (default behavior) or as an error. This is equivalent to passing `-Werror=` or `-Wno-error=`
    /// followed by the warning name to the C compiler.
    ///
    /// This setting allows for fine-grained control over individual warnings. To control all
    /// warnings at once, use `treatAllWarnings(as:_:)` instead.
    ///
    /// - Since: First available in PackageDescription 6.2.
    ///
    /// - Parameters:
    ///   - name: The name of the specific warning to control.
    ///   - level: The treatment level for the warning (`.warning` or `.error`).
    ///   - condition: A condition that restricts the application of the build setting.
    @available(_PackageDescription, introduced: 6.2)
    public static func treatWarning(
      _ name: String,
      as level: WarningLevel,
      _ condition: BuildSettingCondition? = nil
    ) -> CSetting {
        return CSetting(
            name: "treatWarning", value: [name, level.rawValue], condition: condition)
    }

    /// Enable a specific C compiler warning group.
    ///
    /// Use this setting to enable a specific warning group. This is equivalent to passing
    /// `-W` followed by the group name to the C compiler.
    ///
    /// - Since: First available in PackageDescription 6.2.
    ///
    /// - Parameters:
    ///   - name: The name of the warning group to enable.
    ///   - condition: A condition that restricts the application of the build setting.
    @available(_PackageDescription, introduced: 6.2)
    public static func enableWarning(
      _ name: String,
      _ condition: BuildSettingCondition? = nil
    ) -> CSetting {
        return CSetting(
            name: "enableWarning", value: [name], condition: condition)
    }

    /// Disable a specific C compiler warning group.
    ///
    /// Use this setting to disable a specific warning group. This is equivalent to passing
    /// `-Wno-` followed by the group name to the C compiler.
    ///
    /// - Since: First available in PackageDescription 6.2.
    ///
    /// - Parameters:
    ///   - name: The name of the warning group to disable.
    ///   - condition: A condition that restricts the application of the build setting.
    @available(_PackageDescription, introduced: 6.2)
    public static func disableWarning(
      _ name: String,
      _ condition: BuildSettingCondition? = nil
    ) -> CSetting {
        return CSetting(
            name: "disableWarning", value: [name], condition: condition)
    }
}

/// A CXX-language build setting.
public struct CXXSetting: Sendable {
    /// The data store for the CXX build setting.
    let data: BuildSettingData

    private init(name: String, value: [String], condition: BuildSettingCondition?) {
        self.data = BuildSettingData(name: name, value: value, condition: condition)
    }

    /// Provides a header search path relative to the target's directory.
    ///
    /// Use this setting to add a search path for headers within your target.
    /// You can't use absolute paths and you can't use this setting to provide
    /// headers that are visible to other targets.
    ///
    /// The path must be a directory inside the package.
    ///
    /// - Since: First available in PackageDescription 5.0.
    ///
    /// - Parameters:
    ///   - path: The path of the directory that contains the headers. The path is
    ///   relative to the target's directory.
    ///   - condition: A condition that restricts the application of the build setting.
    @available(_PackageDescription, introduced: 5.0)
    public static func headerSearchPath(_ path: String, _ condition: BuildSettingCondition? = nil) -> CXXSetting {
        return CXXSetting(name: "headerSearchPath", value: [path], condition: condition)
    }

    /// Defines a value for a macro.
    ///
    /// If you don't specify a value, the macro's default value is 1.
    ///
    /// - Since: First available in PackageDescription 5.0.
    ///
    /// - Parameters:
    ///   - name: The name of the macro.
    ///   - value: The value of the macro.
    ///   - condition: A condition that restricts the application of the build
    /// setting.
    @available(_PackageDescription, introduced: 5.0)
    public static func define(_ name: String, to value: String? = nil, _ condition: BuildSettingCondition? = nil) -> CXXSetting {
        var settingValue = name
        if let value {
            settingValue += "=" + value
        }
        return CXXSetting(name: "define", value: [settingValue], condition: condition)
    }

    /// Sets unsafe flags to pass arbitrary command-line flags to the
    /// corresponding build tool.
    ///
    /// As the usage of the word “unsafe” implies, Swift Package Manager can't safely determine
    /// if the build flags have any negative side effect on the build since
    /// certain flags can change the behavior of how it performs a build.
    ///
    /// As some build flags can be exploited for unsupported or malicious
    /// behavior, you can't use products with unsafe build flags as dependencies in another package.
    ///
    /// - Since: First available in PackageDescription 5.0.
    ///
    /// - Parameters:
    ///   - flags: The unsafe flags to set.
    ///   - condition: A condition that restricts the application of the build
    /// setting.
    @available(_PackageDescription, introduced: 5.0)
    public static func unsafeFlags(_ flags: [String], _ condition: BuildSettingCondition? = nil) -> CXXSetting {
        return CXXSetting(name: "unsafeFlags", value: flags, condition: condition)
    }
    
    /// Controls how all C++ compiler warnings are treated during compilation.
    ///
    /// Use this setting to specify whether all warnings should be treated as warnings (default behavior)
    /// or as errors. This is equivalent to passing `-Werror` or `-Wno-error`
    /// to the C++ compiler.
    ///
    /// This setting applies to all warnings emitted by the C++ compiler. To control specific
    /// warnings individually, use `treatWarning(name:as:_:)` instead.
    ///
    /// - Since: First available in PackageDescription 6.2.
    ///
    /// - Parameters:
    ///   - level: The treatment level for all warnings (`.warning` or `.error`).
    ///   - condition: A condition that restricts the application of the build setting.
    @available(_PackageDescription, introduced: 6.2)
    public static func treatAllWarnings(
      as level: WarningLevel,
      _ condition: BuildSettingCondition? = nil
    ) -> CXXSetting {
        return CXXSetting(
            name: "treatAllWarnings", value: [level.rawValue], condition: condition)
    }

    /// Controls how a specific C++ compiler warning is treated during compilation.
    ///
    /// Use this setting to specify whether a particular warning should be treated as a warning
    /// (default behavior) or as an error. This is equivalent to passing `-Werror=` or `-Wno-error=`
    /// followed by the warning name to the C++ compiler.
    ///
    /// This setting allows for fine-grained control over individual warnings. To control all
    /// warnings at once, use `treatAllWarnings(as:_:)` instead.
    ///
    /// - Since: First available in PackageDescription 6.2.
    ///
    /// - Parameters:
    ///   - name: The name of the specific warning to control.
    ///   - level: The treatment level for the warning (`.warning` or `.error`).
    ///   - condition: A condition that restricts the application of the build setting.
    @available(_PackageDescription, introduced: 6.2)
    public static func treatWarning(
      _ name: String,
      as level: WarningLevel,
      _ condition: BuildSettingCondition? = nil
    ) -> CXXSetting {
        return CXXSetting(
            name: "treatWarning", value: [name, level.rawValue], condition: condition)
    }

    /// Enable a specific C++ compiler warning group.
    ///
    /// Use this setting to enable a specific warning group. This is equivalent to passing
    /// `-W` followed by the group name to the C++ compiler.
    ///
    /// - Since: First available in PackageDescription 6.2.
    ///
    /// - Parameters:
    ///   - name: The name of the warning group to enable.
    ///   - condition: A condition that restricts the application of the build setting.
    @available(_PackageDescription, introduced: 6.2)
    public static func enableWarning(
      _ name: String,
      _ condition: BuildSettingCondition? = nil
    ) -> CXXSetting {
        return CXXSetting(
            name: "enableWarning", value: [name], condition: condition)
    }

    /// Disable a specific C++ compiler warning group.
    ///
    /// Use this setting to disable a specific warning group. This is equivalent to passing
    /// `-Wno-` followed by the group name to the C++ compiler.
    ///
    /// - Since: First available in PackageDescription 6.2.
    ///
    /// - Parameters:
    ///   - name: The name of the warning group to disable.
    ///   - condition: A condition that restricts the application of the build setting.
    @available(_PackageDescription, introduced: 6.2)
    public static func disableWarning(
      _ name: String,
      _ condition: BuildSettingCondition? = nil
    ) -> CXXSetting {
        return CXXSetting(
            name: "disableWarning", value: [name], condition: condition)
    }
}

/// A Swift language build setting.
public struct SwiftSetting: Sendable {
    /// The data store for the Swift build setting.
    let data: BuildSettingData

    private init(name: String, value: [String], condition: BuildSettingCondition?) {
        self.data = BuildSettingData(name: name, value: value, condition: condition)
    }

    /// Defines a compilation condition.
    ///
    /// Use compilation conditions to only compile statements if a certain
    /// condition is true. For example, the Swift compiler will only compile the
    /// statements inside the `#if` block when `ENABLE_SOMETHING` is defined:
    ///
    /// ```swift
    /// #if ENABLE_SOMETHING
    ///    ...
    /// #endif
    /// ```
    ///
    /// Unlike macros in C/C++, compilation conditions don't have an associated
    /// value.
    ///
    /// - Since: First available in PackageDescription 5.0.
    ///
    /// - Parameters:
    ///   - name: The name of the macro.
    ///   - condition: A condition that restricts the application of the build
    /// setting.
    @available(_PackageDescription, introduced: 5.0)
    public static func define(_ name: String, _ condition: BuildSettingCondition? = nil) -> SwiftSetting {
        return SwiftSetting(name: "define", value: [name], condition: condition)
    }

    /// Set unsafe flags to pass arbitrary command-line flags to the
    /// corresponding build tool.
    ///
    /// As the usage of the word “unsafe” implies, Swift Package Manager can't safely determine
    /// if the build flags have any negative side effect on the build since
    /// certain flags can change the behavior of how it performs a build.
    ///
    /// As some build flags can be exploited for unsupported or malicious
    /// behavior, the use of unsafe flags makes the products containing this
    /// target ineligible for use by other packages.
    ///
    /// - Since: First available in PackageDescription 5.0.
    ///
    /// - Parameters:
    ///   - flags: The unsafe flags to set.
    ///   - condition: A condition that restricts the application of the build
    /// setting.
    @available(_PackageDescription, introduced: 5.0)
    public static func unsafeFlags(_ flags: [String], _ condition: BuildSettingCondition? = nil) -> SwiftSetting {
        return SwiftSetting(name: "unsafeFlags", value: flags, condition: condition)
    }

    /// Enable an upcoming feature with the given name.
    ///
    /// An upcoming feature is one that is available in Swift as of a
    /// certain language version, but isn't available by default in prior
    /// language modes because it has some impact on source compatibility.
    ///
    /// You can add and use multiple upcoming features in a given target
    /// without affecting its dependencies. Targets will ignore any unknown
    /// upcoming features.
    ///
    /// - Since: First available in PackageDescription 5.8.
    ///
    /// - Parameters:
    ///   - name: The name of the upcoming feature; for example, `ConciseMagicFile`.
    ///   - condition: A condition that restricts the application of the build
    /// setting.
    @available(_PackageDescription, introduced: 5.8)
    public static func enableUpcomingFeature(
        _ name: String,
        _ condition: BuildSettingCondition? = nil
    ) -> SwiftSetting {
        return SwiftSetting(
            name: "enableUpcomingFeature", value: [name], condition: condition)
    }

    /// Enable an experimental feature with the given name.
    ///
    /// An experimental feature is one that's in development, but
    /// is not yet available in Swift as a language feature.
    ///
    /// You can add and use multiple experimental features in a given target
    /// without affecting its dependencies. Targets will ignore any  unknown
    /// experimental features.
    ///
    /// - Since: First available in PackageDescription 5.8.
    ///
    /// - Parameters:
    ///   - name: The name of the experimental feature; for example, `VariadicGenerics`.
    ///   - condition: A condition that restricts the application of the build
    /// setting.
    @available(_PackageDescription, introduced: 5.8)
    public static func enableExperimentalFeature(
        _ name: String,
        _ condition: BuildSettingCondition? = nil
    ) -> SwiftSetting {
        return SwiftSetting(
            name: "enableExperimentalFeature", value: [name], condition: condition)
    }

    /// Enable strict memory safety checking.
    ///
    /// Strict memory safety checking is an opt-in compiler feature that
    /// identifies any uses of language constructs or APIs that break
    /// memory safety. Issues are reported as warnings and can generally
    /// be suppressed by adding annotations (such as `@unsafe` and `unsafe`)
    /// that acknowledge the presence of unsafe code, making it easier to
    /// review and audit at a later time.
    ///
    /// - Since: First available in PackageDescription 6.2.
    ///
    /// - Parameters:
    ///   - condition: A condition that restricts the application of the build
    /// setting.
    @available(_PackageDescription, introduced: 6.2)
    public static func strictMemorySafety(
      _ condition: BuildSettingCondition? = nil
    ) -> SwiftSetting {
        return SwiftSetting(
            name: "strictMemorySafety", value: ["ON"], condition: condition)
    }

    /// The interoperability mode
    public enum InteroperabilityMode: String {
        /// Emit code compatible with being imported from C and Objective-C.
        case C
        /// Emit code compatible with being imported from C++ and Objective-C++.
        case Cxx
    }

    /// Enables Swift interoperability with a given language.
    ///
    /// This is useful for enabling interoperability between Swift and C++ for
    /// a given target.
    ///
    /// Enabling C++ interoperability mode might alter the way some existing
    /// C and Objective-C APIs are imported.
    ///
    /// - Since: First available in PackageDescription 5.9.
    ///
    /// - Parameters:
    ///   - mode: The interoperability mode, either C-compatible or C++-compatible.
    ///   - condition: A condition that restricts the application of the build
    /// setting.
    @available(_PackageDescription, introduced: 5.9)
    public static func interoperabilityMode(
      _ mode: InteroperabilityMode,
      _ condition: BuildSettingCondition? = nil
    ) -> SwiftSetting {
        return SwiftSetting(
          name: "interoperabilityMode", value: [mode.rawValue], condition: condition)
    }

    /// Defines a `-swift-version` to pass  to the
    /// corresponding build tool.
    ///
    /// - Since: First available in PackageDescription 6.0.
    ///
    /// - Parameters:
    ///   - version: The Swift language version to use.
    ///   - condition: A condition that restricts the application of the build setting.
    @available(_PackageDescription, introduced: 6.0, deprecated: 6.0, renamed: "swiftLanguageMode(_:_:)")
    public static func swiftLanguageVersion(
      _ version: SwiftVersion,
      _ condition: BuildSettingCondition? = nil
    ) -> SwiftSetting {
        return SwiftSetting(
            name: "swiftLanguageMode", value: [.init(describing: version)], condition: condition)
    }

    /// Defines a `-language-mode` to pass  to the
    /// corresponding build tool.
    ///
    /// - Since: First available in PackageDescription 6.0.
    ///
    /// - Parameters:
    ///   - mode: The Swift language mode to use.
    ///   - condition: A condition that restricts the application of the build setting.
    @available(_PackageDescription, introduced: 6.0)
    public static func swiftLanguageMode(
      _ mode: SwiftLanguageMode,
      _ condition: BuildSettingCondition? = nil
    ) -> SwiftSetting {
        return SwiftSetting(
            name: "swiftLanguageMode", value: [.init(describing: mode)], condition: condition)
    }

    /// Controls how all Swift compiler warnings are treated during compilation.
    ///
    /// Use this setting to specify whether all warnings should be treated as warnings (default behavior)
    /// or as errors. This is equivalent to passing `-warnings-as-errors` or `-no-warnings-as-errors`
    /// to the Swift compiler.
    ///
    /// This setting applies to all warnings emitted by the Swift compiler. To control specific
    /// warnings individually, use `treatWarning(name:as:_:)` instead.
    ///
    /// - Since: First available in PackageDescription 6.2.
    ///
    /// - Parameters:
    ///   - level: The treatment level for all warnings (`.warning` or `.error`).
    ///   - condition: A condition that restricts the application of the build setting.
    @available(_PackageDescription, introduced: 6.2)
    public static func treatAllWarnings(
      as level: WarningLevel,
      _ condition: BuildSettingCondition? = nil
    ) -> SwiftSetting {
        return SwiftSetting(
            name: "treatAllWarnings", value: [level.rawValue], condition: condition)
    }

    /// Controls how a specific Swift compiler warning is treated during compilation.
    ///
    /// Use this setting to specify whether a particular warning should be treated as a warning
    /// (default behavior) or as an error. This is equivalent to passing `-Werror` or `-Wwarning`
    /// followed by the warning name to the Swift compiler.
    ///
    /// This setting allows for fine-grained control over individual warnings. To control all
    /// warnings at once, use `treatAllWarnings(as:_:)` instead.
    ///
    /// - Since: First available in PackageDescription 6.2.
    ///
    /// - Parameters:
    ///   - name: The name of the specific warning to control.
    ///   - level: The treatment level for the warning (`.warning` or `.error`).
    ///   - condition: A condition that restricts the application of the build setting.
    @available(_PackageDescription, introduced: 6.2)
    public static func treatWarning(
      _ name: String,
      as level: WarningLevel,
      _ condition: BuildSettingCondition? = nil
    ) -> SwiftSetting {
        return SwiftSetting(
            name: "treatWarning", value: [name, level.rawValue], condition: condition)
    }

    /// Set the default isolation to the given global actor type.
    ///
    /// - Since: First available in PackageDescription 6.2.
    ///
    /// - Parameters:
    ///   - isolation: The type of global actor to use for default actor isolation
    ///     inference. The only valid arguments are `MainActor.self` and `nil`.
    ///   - condition: A condition that restricts the application of the build
    ///     setting.
    ///
    /// The compiler defaults to inferring unannotated code as `nonisolated` if unspecified,
    /// or if the `isolation` parameter is set to `nil`.
    @available(_PackageDescription, introduced: 6.2)
    public static func defaultIsolation(
        _ isolation: MainActor.Type?,
        _ condition: BuildSettingCondition? = nil
    ) -> SwiftSetting {
        let isolationString =
            if isolation == nil {
                "nonisolated"
            } else {
                "MainActor"
            }
        return SwiftSetting(
            name: "defaultIsolation", value: [isolationString], condition: condition)
    }
}

/// A linker build setting.
public struct LinkerSetting: Sendable {
    /// The data store for the Linker setting.
    let data: BuildSettingData

    private init(name: String, value: [String], condition: BuildSettingCondition?) {
        self.data = BuildSettingData(name: name, value: value, condition: condition)
    }

    /// Declares linkage to a system library.
    ///
    /// This setting is most useful when the library can't be linked
    /// automatically, such as C++ based libraries and non-modular libraries.
    ///
    /// - Since: First available in PackageDescription 5.0.
    ///
    /// - Parameters:
    ///   - library: The library name.
    ///   - condition: A condition that restricts the application of the build
    /// setting.
    @available(_PackageDescription, introduced: 5.0)
    public static func linkedLibrary(_ library: String, _ condition: BuildSettingCondition? = nil) -> LinkerSetting {
        return LinkerSetting(name: "linkedLibrary", value: [library], condition: condition)
    }

    /// Declares linkage to a system framework.
    ///
    /// This setting is most useful when the framework can't be linked
    /// automatically, such as C++ based frameworks and non-modular frameworks.
    ///
    /// - Since: First available in PackageDescription 5.0.
    ///
    /// - Parameters:
    ///   - framework: The framework name.
    ///   - condition: A condition that restricts the application of the build
    /// setting.
    @available(_PackageDescription, introduced: 5.0)
    public static func linkedFramework(_ framework: String, _ condition: BuildSettingCondition? = nil) -> LinkerSetting {
        return LinkerSetting(name: "linkedFramework", value: [framework], condition: condition)
    }
   
    /// Sets unsafe flags to pass arbitrary command-line flags to the
    /// corresponding build tool.
    ///
    /// As the usage of the word “unsafe” implies, Swift Package Manager can't safely determine
    /// if the build flags have any negative side effect on the build since
    /// certain flags can change the behavior of how it performs a build.
    ///
    /// As some build flags can be exploited for unsupported or malicious
    /// behavior, the use of unsafe flags makes the products containing this
    /// target ineligible for use by other packages.
    ///
    /// - Since: First available in PackageDescription 5.0.
    ///
    /// - Parameters:
    ///   - flags: The unsafe flags to set.
    ///   - condition: A condition that restricts the application of the build
    /// setting.
    @available(_PackageDescription, introduced: 5.0)
    public static func unsafeFlags(_ flags: [String], _ condition: BuildSettingCondition? = nil) -> LinkerSetting {
        return LinkerSetting(name: "unsafeFlags", value: flags, condition: condition)
    }
}
