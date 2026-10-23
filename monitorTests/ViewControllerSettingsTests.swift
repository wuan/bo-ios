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

    func testTheRpcSourceCarriesTheGlobalRegionForEveryStoredValue() {
        for region in SelectableSettings.regions {
            XCTAssertTrue(settings.setChoice(region.value, for: .region))

            XCTAssertEqual(controller.regionSetting, region.value)
            XCTAssertEqual(controller.baseParameters().region, Parameters.globalRegion,
                           "the RPC source must ignore the stored region \(region.value)")
            XCTAssertEqual(provider.received.last?.region, Parameters.globalRegion)
        }
    }

    func testAnHttpRequestCarriesTheStoredNamedRegion() {
        settings.set(DataProviderType.http.rawValue, for: .dataSource)
        XCTAssertTrue(settings.setChoice(3, for: .region))

        XCTAssertEqual(provider.received.last?.region, 3)
        XCTAssertEqual(controller.requestCurrentParameters().region, 3)
        XCTAssertEqual(controller.activeRegionName, "N. America")
    }

    func testAnHttpRequestResolvesAnUnnamedStoredRegionToEuropeWithoutWriting() {
        settings.set(DataProviderType.http.rawValue, for: .dataSource)
        XCTAssertEqual(settings.choice(for: .region), SelectableSettings.defaultRegion,
                       "the region setting is left at its 0 default")

        XCTAssertEqual(controller.requestCurrentParameters().region, SelectableSettings.defaultHttpRegion)
        XCTAssertEqual(provider.received.last?.region, SelectableSettings.defaultHttpRegion)
        XCTAssertEqual(settings.choice(for: .region), SelectableSettings.defaultRegion,
                       "resolving the region must not write to the settings store")
    }

    func testTheStoredLocalRegionFallsBackToGlobalForRpcWithoutADataArea() {
        XCTAssertTrue(settings.setChoice(Parameters.localRegion, for: .region))

        XCTAssertEqual(controller.requestCurrentParameters().region, Parameters.globalRegion)
        XCTAssertEqual(controller.activeRegionName, "Global",
                       "the legend follows the resolved request, not the stored setting")
    }

    // MARK: - Data source

    func testChangingTheSourceReRequestsWithTheRegionOfTheNewSource() {
        XCTAssertTrue(settings.setChoice(3, for: .region))
        XCTAssertEqual(provider.received.last?.region, Parameters.globalRegion,
                       "the RPC source ignores the stored region")

        settings.set(DataProviderType.http.rawValue, for: .dataSource)

        XCTAssertEqual(provider.received.last?.region, 3,
                       "the next request must follow the newly active source")

        settings.set(DataProviderType.rpc.rawValue, for: .dataSource)

        XCTAssertEqual(provider.received.last?.region, Parameters.globalRegion)
    }

    // MARK: - Mode controls

    func testTheSliderRangeIsLabelledFromHistoryToNow() {
        XCTAssertEqual(ViewController.rangeStartText(lowerLimitMinutes: -1380), "-23 h")
        XCTAssertEqual(controller.rangeStartLabel.text, "-23 h")
        XCTAssertEqual(controller.rangeEndLabel.text, "now")
    }

    func testTheRangeStartFollowsTheIntervalDuration() {
        // The fractional value uses the locale's decimal separator, so only the
        // magnitude is asserted, not the exact string.
        let fractional = ViewController.rangeStartText(lowerLimitMinutes: -1410)
        XCTAssertTrue(fractional.hasPrefix("-23") && fractional.hasSuffix(" h"),
                      "expected about -23.5 h, got '\(fractional)'")

        settings.setChoice(240, for: .intervalDuration)

        XCTAssertEqual(controller.rangeStartLabel.text, "-20 h")
    }
}
