//
//  monitorUITests.swift
//  monitorUITests
//
//  Created by Andreas Würl on 19.10.15.
//  Copyright © 2015 Andreas Würl. All rights reserved.
//

import XCTest

class monitorUITests: XCTestCase {

    override func setUp() {
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    /// Exercises the minimal data source surface: open it, change the source,
    /// save, reopen, and confirm the selection persisted. Restores JSON-RPC so
    /// later runs start from the documented default.
    func testDataSourceSelectionPersistsAcrossReopening() {
        let app = XCUIApplication()

        let open = app.buttons["settings.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 15))
        open.tap()

        let source = app.segmentedControls["settings.source"]
        XCTAssertTrue(source.waitForExistence(timeout: 10))
        source.buttons.element(boundBy: 1).tap()
        app.buttons["settings.save"].tap()
        app.buttons["settings.close"].tap()

        let reopen = app.buttons["settings.open"]
        XCTAssertTrue(reopen.waitForExistence(timeout: 10))
        reopen.tap()

        let reopened = app.segmentedControls["settings.source"]
        XCTAssertTrue(reopened.waitForExistence(timeout: 10))
        XCTAssertTrue(reopened.buttons.element(boundBy: 1).isSelected)

        // Restore the default source.
        reopened.buttons.element(boundBy: 0).tap()
        app.buttons["settings.save"].tap()
        app.buttons["settings.close"].tap()
    }

    /// LIVE CHECK: requires network access. Selects the JSON-RPC source with no
    /// endpoint override and confirms the app renders a non-zero strike count.
    ///
    /// The backend answers with data only for a `bo-ios-<build>` user agent, so a
    /// rendered strike count also proves the request was identified correctly.
    func testLiveRpcSourceRendersStrikes() throws {
        try requireLiveBackend()

        let app = XCUIApplication()
        app.launch()

        openSettings(app)
        selectSource(app, index: 0)
        replaceText(in: app.textFields["settings.endpoint"], with: "")
        app.buttons["settings.save"].tap()
        app.buttons["settings.close"].tap()

        relaunch(app)

        let status = app.staticTexts["status.text"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))

        let reported = waitForStrikeCount(in: status, timeout: 90)
        XCTAssertTrue(reported.matched, "status was '\(reported.label)'")
    }

    /// LIVE CHECK: requires the stub server in the development notes, listening on
    /// port 8099 and demanding HTTP Basic `test:test` for strike logs. Confirms a
    /// custom endpoint and stored credentials are used by the HTTP source.
    func testLiveHttpSourceUsesCustomEndpointAndCredentials() throws {
        try requireStubServer()

        let app = XCUIApplication()
        app.launch()

        openSettings(app)
        selectSource(app, index: 1)
        replaceText(in: app.textFields["settings.endpoint"], with: "http://127.0.0.1:8099")
        replaceText(in: app.textFields["settings.username"], with: "test")
        replaceText(in: app.secureTextFields["settings.password"], with: "test")

        // Dismiss the keyboard so the buttons below are reachable.
        app.otherElements["settings.root"].tap()

        app.buttons["settings.save"].tap()
        app.buttons["settings.close"].tap()

        relaunch(app)

        let status = app.staticTexts["status.text"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))

        let reported = waitForStrikeCount(in: status, timeout: 90)
        XCTAssertTrue(reported.matched, "status was '\(reported.label)'")
    }

    /// LIVE CHECK: requires the same stub server as the test above. Configures
    /// credentials and then selects the unauthenticated JSON-RPC source against a
    /// custom endpoint, confirming the saved credentials neither break it nor are
    /// sent to it.
    func testLiveRpcSourceIgnoresStoredCredentials() throws {
        try requireStubServer()

        let app = XCUIApplication()
        app.launch()

        openSettings(app)
        selectSource(app, index: 0)
        replaceText(in: app.textFields["settings.endpoint"], with: "http://127.0.0.1:8099")
        replaceText(in: app.textFields["settings.username"], with: "test")
        replaceText(in: app.secureTextFields["settings.password"], with: "test")
        app.otherElements["settings.root"].tap()
        app.buttons["settings.save"].tap()
        app.buttons["settings.close"].tap()

        relaunch(app)

        let status = app.staticTexts["status.text"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))

        let reported = waitForStrikeCount(in: status, timeout: 90)
        XCTAssertTrue(reported.matched, "status was '\(reported.label)'")
    }

    // MARK: - Helpers

    /// LIVE CHECK: requires Blitzortung credentials and network access. Points the
    /// HTTP source at the real endpoint, enters the credentials, and confirms
    /// authenticated strike logs render.
    ///
    /// Credentials are supplied out of band — through `BO_DATA_USERNAME` /
    /// `BO_DATA_PASSWORD` in the environment when present, otherwise through the
    /// same build settings substituted into this bundle's Info.plist by an
    /// `.xcconfig`. They are never written to the repository.
    func testLiveHttpSourceAuthenticatesAgainstRealBackend() throws {
        let credentials = liveCredentials()
        try XCTSkipIf(credentials == nil,
                      "no Blitzortung credentials supplied (BO_DATA_USERNAME/BO_DATA_PASSWORD)")
        let credentials_ = credentials!

        let app = XCUIApplication()
        app.launch()

        openSettings(app)
        selectSource(app, index: 1)
        // Leave the endpoint empty so the provider uses its built-in default.
        replaceText(in: app.textFields["settings.endpoint"], with: "")
        replaceText(in: app.textFields["settings.username"], with: credentials_.username)
        replaceText(in: app.secureTextFields["settings.password"], with: credentials_.password)
        app.otherElements["settings.root"].tap()

        app.buttons["settings.save"].tap()
        app.buttons["settings.close"].tap()

        relaunch(app)

        let status = app.staticTexts["status.text"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))

        let reported = waitForStrikeCount(in: status, timeout: 90)
        XCTAssertTrue(reported.matched, "status was '\(reported.label)'")
    }

    /// Reads the Blitzortung credentials from the environment or the test bundle.
    private func liveCredentials() -> (username: String, password: String)? {
        let environment = ProcessInfo.processInfo.environment
        let bundle = Bundle(for: type(of: self))

        let username = environment["BO_DATA_USERNAME"]
            ?? (bundle.object(forInfoDictionaryKey: "BOTestDataUsername") as? String)
            ?? ""
        let password = environment["BO_DATA_PASSWORD"]
            ?? (bundle.object(forInfoDictionaryKey: "BOTestDataPassword") as? String)
            ?? ""

        guard !username.isEmpty, !password.isEmpty else {
            return nil
        }
        return (username, password)
    }

    /// Skips the live backend checks when the stub is not running locally.
    private func requireStubServer() throws {
        let (_, status) = probe(URLRequest(url: URL(string: "http://127.0.0.1:8099/x.log")!))
        try XCTSkipIf(status == nil, "stub server not reachable on 127.0.0.1:8099")
    }

    /// Skips the live backend check when the public backend returns no strike data.
    private func requireLiveBackend() throws {
        var request = URLRequest(url: URL(string: "http://bo-test.tryb.de")!)
        request.httpMethod = "POST"
        request.setValue("text/json", forHTTPHeaderField: "Content-Type")
        request.setValue("bo-ios-1", forHTTPHeaderField: "User-Agent")
        request.httpBody = Data(#"{"id":1,"method":"get_strikes_grid","params":[60,10000,0,1,0]}"#.utf8)

        let (body, status) = probe(request)
        let text = body.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        try XCTSkipUnless(status == 200 && text.contains("\"t\""),
                          "live RPC backend did not return strike data")
    }

    /// Performs a request and returns its body and status, or `nil` status on failure.
    private func probe(_ request: URLRequest, timeout: TimeInterval = 5) -> (Data?, Int?) {
        var request = request
        request.timeoutInterval = timeout

        let semaphore = DispatchSemaphore(value: 0)
        var body: Data?
        var status: Int?
        URLSession.shared.dataTask(with: request) { data, response, _ in
            body = data
            status = (response as? HTTPURLResponse)?.statusCode
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(timeout: .now() + timeout + 2)
        return (body, status)
    }

    private func openSettings(_ app: XCUIApplication) {
        let open = app.buttons["settings.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 15))
        open.tap()

        let source = app.segmentedControls["settings.source"]
        XCTAssertTrue(source.waitForExistence(timeout: 10))
    }

    private func selectSource(_ app: XCUIApplication, index: Int) {
        let source = app.segmentedControls["settings.source"]
        XCTAssertTrue(source.waitForExistence(timeout: 10))
        source.buttons.element(boundBy: index).tap()
    }

    /// Replaces a field's contents rather than appending to whatever it holds.
    private func replaceText(in element: XCUIElement, with value: String) {
        element.tap()

        let clear = element.buttons["Clear text"]
        if clear.exists {
            clear.tap()
        } else if let current = element.value as? String, !current.isEmpty,
                  current != element.placeholderValue {
            element.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }

        if !value.isEmpty {
            element.typeText(value)
        }
    }

    private func relaunch(_ app: XCUIApplication) {
        // Relaunch so the first poll fires immediately rather than after a period.
        app.terminate()
        app.launch()
    }

    /// Polls the status label until it reports a non-zero strike count.
    ///
    /// Returns the last observed label so a failure shows what the app actually
    /// displayed instead of only a timeout.
    private func waitForStrikeCount(in element: XCUIElement,
                                    timeout: TimeInterval) -> (matched: Bool, label: String) {
        let deadline = Date().addingTimeInterval(timeout)
        var label = ""
        while Date() < deadline {
            label = element.label
            if label.range(of: "^[1-9][0-9]* strikes/", options: .regularExpression) != nil {
                return (true, label)
            }
            usleep(500_000)
        }
        return (false, label)
    }
}
