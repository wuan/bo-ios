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

class ColorScheme {

    let colors: Array<UInt> = [0xffe4f9f9, 0xffd8f360, 0xffdfbc51, 0xffe48044, 0xffe73c3b, 0xffb82e2d]

    func getColorSection(now: Int, eventTime: Int, timeIntervalWithOffset: TimeIntervalWithOffset) -> Int {
        return getColorSection(now, eventTime: eventTime, intervalDuration: timeIntervalWithOffset.intervalDuration, intervalOffset: timeIntervalWithOffset.intervalOffset)
    }

    func getColor(now: Int, eventTime: Int, intervalDuration: Int) -> UInt {
        let color = getColor(getColorSection(now, eventTime: eventTime, intervalDuration: intervalDuration, intervalOffset: 0))
        return color
    }

    func getColor(section: Int) -> UInt {
        return colors[limitToValidRange(section)]
    }

    private func getColorSection(now: Int, eventTime: Int, intervalDuration: Int, intervalOffset: Int = 0) -> Int {
        let minutesPerColor = intervalDuration / colors.count
        let startTime = intervalOffset * 60 * 1000
        var section = (now + startTime - eventTime) / 1000 / 60 / minutesPerColor
        section = limitToValidRange(section)

        return section
    }

    private func limitToValidRange(section_: Int) -> Int {
        return max(min(section_, colors.count - 1), 0)
    }
}
