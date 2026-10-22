/*

Copyright 2015-2016 Andreas Würl

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

import Foundation

/// Parses the line-oriented strike logs served by the Blitzortung HTTP source.
///
/// A line looks like:
///
///    2019-02-13 06:07:24.748241830 pos;37.714012;26.801138;0 str;0 dev;7013 sta;18;85;...
///
/// Malformed lines are skipped rather than failing the whole file.
public struct StrikeLogParser {

    /// Provider timestamps are UTC with nanoseconds; milliseconds are kept.
    public static let timeFormat = "yyyyMMdd'T'HH:mm:ss.SSS"

    public init() {}

    /// Parses every line of a log file, skipping malformed lines.
    public func parse(contents: String) -> [Strike] {
        return contents
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { parse(line: String($0)) }
    }

    /// Parses a single log line, or `nil` when it is malformed.
    public func parse(line: String) -> Strike? {
        let fields = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard fields.count > 2 else {
            return nil
        }
        guard let timestamp = Self.timestamp(date: fields[0], time: fields[1]) else {
            return nil
        }

        var latitude: Double?
        var longitude: Double?
        for field in fields[2...] {
            let parts = field.split(separator: ";", omittingEmptySubsequences: false).map(String.init)
            guard parts.first == "pos" else {
                continue
            }
            guard parts.count >= 4, let lat = Double(parts[1]), let lon = Double(parts[2]) else {
                return nil
            }
            latitude = lat
            longitude = lon
        }

        guard let latitude = latitude, let longitude = longitude else {
            return nil
        }
        return Strike(timestamp: timestamp, andMultiplicity: 1, andX: longitude, andY: latitude)
    }

    /// Converts the date and time fields of a log line into epoch seconds.
    static func timestamp(date: String, time: String) -> Int? {
        let compactDate = date.replacingOccurrences(of: "-", with: "")
        guard compactDate.count == 8, time.count >= 12 else {
            return nil
        }

        let millisecondTime = String(time.prefix(12))
        let formatter = DateFormatter()
        formatter.dateFormat = timeFormat
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        guard let parsed = formatter.date(from: compactDate + "T" + millisecondTime) else {
            return nil
        }
        return Int(parsed.timeIntervalSince1970)
    }
}
