/*
 The MIT License (MIT)

 Copyright (c) Jeremy Greenwood

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */


import ArgumentParser
import Foundation
import Git
import PathKit
import XcodeProj

fileprivate enum Constants {
    static let buildKey = "CURRENT_PROJECT_VERSION"
    static let infoPlistKey = "INFOPLIST_FILE"
    static let versionKey = "MARKETING_VERSION"
    static let bundleVersionKey = "CFBundleShortVersionString"
}

@main
struct XCBump: ParsableCommand {
    @Option(help: "Path of the project file")
    var path: String?

    @Option(help: "Specific version to use")
    var version: String?

    @Option(help: "Specific build to use")
    var build: String?

    @Flag(help: "Specifies whether version bump should be commited and tagged")
    var tag = false

    mutating func run() throws {
        let projectPath = try Path(path ?? Self.projectPath())
        let project = try XcodeProj(path: projectPath)

        try project.configureInfoPlistRef()

        if let version = version {
            try project.setVersion(version)
        }

        if let build = build {
            try project.setBuild(build)
        } else {
            guard let buildNumber = try Int(project.getBuild()) else {
                throw "Build number is not an Int"
            }

            try project.setBuild(String(buildNumber + 1))
        }

        try project.write(path: projectPath)

        if tag {
            guard Path(".git").exists else {
                throw "Current directory is not version controlled with git"
            }

            let repo = try GitRepository(atPath: Path.current.string)
            try repo.commit(options: GitCommitOptions(message: "version", files: .all))
            try repo.tag(
                options: .annotate(
                    tag: "\(project.getVersion())(\(project.getBuild()))",
                    message: "Version bumped with XCBump")
            )
        }
    }
}

private extension XCBump {
    static func projectPath() throws -> String {
        let paths = Path.glob("*.xcodeproj")

        switch paths.count {
        case 0:
            throw "Unable to find project file. Specify one with --path"
        case 1:
            return paths.first!.string
        default:
            throw "Found more then one project file. Specify one with --path"
        }
    }
}

extension XcodeProj {
    func getVersion() throws -> String {
        try pbxproj.appBuildSettings()[Constants.versionKey] as! String
    }

    func setVersion(_ version: String) throws {
        var buildSettings = try pbxproj.appBuildSettings()
        buildSettings[Constants.versionKey] = version

        pbxproj.setAppBuildSettings(buildSettings)
    }

    func getBuild() throws -> String {
        try pbxproj.appBuildSettings()[Constants.buildKey] as! String
    }

    func setBuild(_ build: String) throws {
        var buildSettings = try pbxproj.appBuildSettings()
        buildSettings[Constants.buildKey] = build

        pbxproj.setAppBuildSettings(buildSettings)
    }

    func getAppInfoPlistPath() throws -> Path {
        let plistPath = try pbxproj.appBuildSettings()[Constants.infoPlistKey] as! String
        return Path(plistPath)
    }

    func configureInfoPlistRef() throws {
        // get the version from the app plist and check whether it is already configured
        let bundleVersion = try getVersionFromAppPlist()
        guard bundleVersion != "$(\(Constants.versionKey))" else {
            return
        }

        try setVersion(bundleVersion)

        let plistPath = try getAppInfoPlistPath()
        var plist = try Dictionary<String, Any>(plist: plistPath)
        plist[Constants.bundleVersionKey] = "$(\(Constants.versionKey))"

        let plistData = try plist.plistData()
        try plistPath.write(plistData)
    }

    func getVersionFromAppPlist() throws -> String {
        // get version string from plist
        guard let version = try Dictionary<String, Any>(plist: getAppInfoPlistPath())[Constants.bundleVersionKey] as? String else {
            throw "Cound not find bundle version."
        }

        return version
    }
}

extension PBXProj {
    func appBuildSettings() throws -> BuildSettings {
        guard let appTarget = (nativeTargets.first { $0.productType == .application }),
              let buildSettings = appTarget
                .buildConfigurationList?
                .buildConfigurations.first?
                .buildSettings else {
                    throw "Could not find application target"
                }

        return buildSettings
    }

    func setAppBuildSettings(_ buildSettings: BuildSettings) {
        nativeTargets.first { $0.productType == .application }?
            .buildConfigurationList?
            .buildConfigurations.first?
            .buildSettings = buildSettings
    }
}

extension String: Error {}

extension Dictionary {
    init(plist: Path) throws {
        let data = try Data(contentsOf: plist.url)
        var propertyListFormat = PropertyListSerialization.PropertyListFormat.xml
        let serialized = try PropertyListSerialization.propertyList(
            from: data,
            options: .mutableContainersAndLeaves,
            format: &propertyListFormat
        ) as! [Key: Value]

        self = serialized
    }

    func plistData() throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: self, format: .xml, options: 0)
    }
}
