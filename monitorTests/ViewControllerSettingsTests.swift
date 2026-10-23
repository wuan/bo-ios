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

import XCTest
@testable import monitor

/// Provider that records the parameters it is asked for.
private final class RequestRecordingProvider: DataProvider {
    private(set) var received: [Parameters] = []

    func fetchData(parameters: Parameters, completion: @escaping (Result?, Error?) -> Void) {
        received.append(parameters)
        completion(nil, nil)
    }
}

@MainActor
final class ViewControllerSettingsTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var settings: SettingsStore!
    private var provider: RequestRecordingProvider!
    private var controller: ViewController!

    override func setUp() {
        super.setUp()
        suiteName = "ViewControllerSettingsTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        settings = SettingsStore(defaults: defaults)
        provider = RequestRecordingProvider()

        controller = ViewController(dataSource: DataHandler(provider: provider),
                                    settings: settings,
                                    credentialStore: InMemoryCredentialStore())
        controller.loadViewIfNeeded()
        controller.pollingTimer?.invalidate()
    }

    override func tearDown() {
        controller = nil
        provider = nil
        settings = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    // MARK: - Interval duration and history step

    func testIntervalDurationSettingReachesTheTimeModelAndRequest() {
        settings.setChoice(120, for: .intervalDuration)

        XCTAssertEqual(controller.timeModel.interval.duration, 120)

        let parameters = controller.requestCurrentParameters()
        XCTAssertEqual(parameters.intervalDuration, 120)
        XCTAssertEqual(provider.received.last?.intervalDuration, 120)
    }

    func testChangedIntervalDurationAppliesWithoutRelaunch() {
        XCTAssertEqual(controller.timeModel.interval.duration, 60)

        settings.setChoice(240, for: .intervalDuration)

        XCTAssertEqual(controller.timeModel.interval.duration, 240)
        XCTAssertEqual(provider.received.last?.intervalDuration, 240)
    }

    func testHistoryStepSettingReachesTheHistory() {
        settings.setChoice(60, for: .historicTimestep)

        XCTAssertEqual(controller.timeModel.history.timeIncrement, 60)
    }

    func testChangedHistoryStepReshapesTheSliderRange() {
        let defaultMaximum = controller.timeSlider.maximumValue

        settings.setChoice(60, for: .historicTimestep)

        XCTAssertEqual(defaultMaximum, Float((History.maxRange - 60) / 30))
        XCTAssertEqual(controller.timeSlider.maximumValue, Float((History.maxRange - 60) / 60))
    }

    func testChangedIntervalDurationReshapesTheSliderRange() {
        let defaultMaximum = controller.timeSlider.maximumValue

        settings.setChoice(120, for: .intervalDuration)

        XCTAssertEqual(defaultMaximum, Float((History.maxRange - 60) / 30))
        XCTAssertEqual(controller.timeSlider.maximumValue, Float((History.maxRange - 120) / 30))
    }

    // MARK: - Region

    func testEveryRegionValueProducesTheExpectedParameterAndName() {
        for region in SelectableSettings.regions {
            XCTAssertTrue(settings.setChoice(region.value, for: .region))

            XCTAssertEqual(controller.regionSetting, region.value)
            XCTAssertEqual(controller.baseParameters().region, region.value)
            XCTAssertEqual(controller.activeRegionName, region.name)
        }
    }

    func testChangedRegionReachesTheRequest() {
        XCTAssertTrue(settings.setChoice(3, for: .region))

        XCTAssertEqual(provider.received.last?.region, 3)
    }

    func testLocalRegionFallsBackToGlobalWithoutADataArea() {
        XCTAssertTrue(settings.setChoice(Parameters.localRegion, for: .region))

        XCTAssertEqual(controller.requestCurrentParameters().region, Parameters.globalRegion)
        XCTAssertEqual(controller.activeRegionName, "Local")
    }

    // MARK: - Mode controls

    func testTheSliderRangeIsLabelledFromHistoryToNow() {
        XCTAssertEqual(ViewController.rangeStartText, "-24 h")
        XCTAssertEqual(controller.rangeStartLabel.text, "-24 h")
        XCTAssertEqual(controller.rangeEndLabel.text, "now")
    }
}
