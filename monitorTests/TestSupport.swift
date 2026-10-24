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

import CoreLocation
import Foundation
@testable import monitor

/// Transport that returns canned bodies per URL and records what it was asked for.
final class StubTransport: HttpTransport {

    /// Response bodies keyed by URL. A miss stands in for a 404 and is tolerated.
    var responses: [URL: String] = [:]

    private(set) var requestedURLs: [URL] = []
    private(set) var receivedCredentials: [Credentials?] = []
    private(set) var receivedUserAgents: [UserAgent] = []

    func get(url: URL, credentials: Credentials?, userAgent: UserAgent, completion: @escaping (Data?, Error?) -> Void) {
        requestedURLs.append(url)
        receivedCredentials.append(credentials)
        receivedUserAgents.append(userAgent)

        if let body = responses[url] {
            completion(Data(body.utf8), nil)
        } else {
            completion(nil, nil)
        }
    }

    /// Forgets recorded requests while keeping the canned responses.
    func resetRequests() {
        requestedURLs.removeAll()
        receivedCredentials.removeAll()
        receivedUserAgents.removeAll()
    }
}

/// Provider that records requests and returns a preset result or error.
final class RecordingProvider: DataProvider {
    let type: DataProviderType
    var result: Result?
    var error: Error?
    private(set) var requestCount = 0

    init(type: DataProviderType = .rpc, result: Result? = nil, error: Error? = nil) {
        self.type = type
        self.result = result
        self.error = error
    }

    func fetchData(parameters: Parameters, completion: @escaping (Result?, Error?) -> Void) {
        requestCount += 1
        completion(result, error)
    }
}

/// URL protocol that captures requests and returns an empty successful response.
final class StubURLProtocol: URLProtocol {

    static var capturedRequests: [URLRequest] = []
    static var responseBody = Data("{}".utf8)

    static func reset() {
        capturedRequests = []
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        StubURLProtocol.capturedRequests.append(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: StubURLProtocol.responseBody)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
    }
}

/// A `URLSession` whose traffic is served by ``StubURLProtocol``.
func makeStubbedSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    return URLSession(configuration: configuration)
}

/// A location manager that hands out positions and records what it was asked to do.
///
/// Stands in for the device: no permission prompt, no device, and every request
/// and report under the test's control.
final class StubLocationManager: LocationManaging {

    var authorizationStatus: CLAuthorizationStatus
    var desiredAccuracy: CLLocationAccuracy = 0
    weak var delegate: LocationManagerDelegate?

    /// The last position reported through ``report(_:)``.
    private(set) var location: Location?

    private(set) var whenInUseRequests = 0
    private(set) var alwaysRequests = 0
    private(set) var startedUpdates = 0
    private(set) var stoppedUpdates = 0
    private(set) var startedSignificantChanges = 0
    private(set) var stoppedSignificantChanges = 0

    init(authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse) {
        self.authorizationStatus = authorizationStatus
    }

    func requestWhenInUseAuthorization() {
        whenInUseRequests += 1
    }

    func requestAlwaysAuthorization() {
        alwaysRequests += 1
    }

    func startUpdatingLocation() {
        startedUpdates += 1
    }

    func stopUpdatingLocation() {
        stoppedUpdates += 1
    }

    func startMonitoringSignificantLocationChanges() {
        startedSignificantChanges += 1
    }

    func stopMonitoringSignificantLocationChanges() {
        stoppedSignificantChanges += 1
    }

    /// Reports a position from the device.
    func report(_ location: Location) {
        self.location = location
        delegate?.manager(self, didUpdate: location)
    }

    /// Grants the permission and tells the delegate, as the device would.
    func grant(_ status: CLAuthorizationStatus = .authorizedWhenInUse) {
        authorizationStatus = status
        delegate?.managerDidChangeAuthorization(self)
    }
}
