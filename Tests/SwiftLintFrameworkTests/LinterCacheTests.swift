//
//  LinterCacheTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/27/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
@testable import SwiftLintFramework
import XCTest

class LinterCacheTests: XCTestCase {

    func testInitThrowsWhenUsingDifferentVersion() {
        let cache = ["version": "0.1.0"]
        checkError(LinterCacheError.differentVersion) {
            _ = try LinterCache(cache: cache, currentVersion: Version(value: "0.2.0"))
        }
    }

    func testInitThrowsWhenUsingInvalidCacheFormat() {
        let cache = [["version": "0.1.0"]]
        checkError(LinterCacheError.invalidFormat) {
            _ = try LinterCache(cache: cache, currentVersion: Version(value: "0.1.0"))
        }
    }

    func testInitThrowsWhenUsingInconsistentLastRunDate() {
        let futureLastRunDateTimeInterval = Date().timeIntervalSinceReferenceDate + 100
        let cache = ["version": "0.1.0", "last_run_date": futureLastRunDateTimeInterval] as [String : Any]
        checkError(LinterCacheError.inconsistentLastRunDate) {
            _ = try LinterCache(cache: cache, currentVersion: Version(value: "0.1.0"))
        }
    }

    func testInitThrowsWhenUsingDifferentConfiguration() {
        let cache = ["version": "0.1.0", "configuration_hash": 1] as [String : Any]
        checkError(LinterCacheError.differentConfiguration) {
            _ = try LinterCache(cache: cache, currentVersion: Version(value: "0.1.0"),
                                configurationHash: 2)
        }
    }

    func testInitSucceeds() {
        let cache = ["version": "0.2.0"]
        let linterCache = try? LinterCache(cache: cache, currentVersion: Version(value: "0.2.0"))
        XCTAssertNotNil(linterCache)
    }

    func testInitSucceedsWithLastRunDate() {
        let pastLastRunDateTimeInterval = Date().timeIntervalSinceReferenceDate - 100
        let cache = ["version": "0.2.0", "last_run_date": pastLastRunDateTimeInterval] as [String : Any]
        let linterCache = try? LinterCache(cache: cache, currentVersion: Version(value: "0.2.0"))
        XCTAssertNotNil(linterCache)
        XCTAssertEqual(linterCache?.lastRunDate?.timeIntervalSinceReferenceDate, pastLastRunDateTimeInterval)
    }

    func testInitSucceedsWithConfigurationHash() {
        let cache = ["version": "0.2.0", "configuration_hash": 1] as [String : Any]
        let linterCache = try? LinterCache(cache: cache, currentVersion: Version(value: "0.2.0"),
                                           configurationHash: 1)
        XCTAssertNotNil(linterCache)
    }

    func testLastRunDateIsNilByDefault() {
        let cache = LinterCache()
        XCTAssertNil(cache.lastRunDate)
    }

    func testSetLastRunDate() {
        let cache = LinterCache()
        let date = Date()
        cache.lastRunDate = date
        XCTAssertEqual(cache.lastRunDate?.timeIntervalSinceReferenceDate,
                       date.timeIntervalSinceReferenceDate)
    }

    func testParsesViolations() {
        let cache = LinterCache(currentVersion: Version(value: "0.2.0"))
        let file = "foo.swift"
        let ruleDescription = RuleDescription(identifier: "rule", name: "Some rule",
                                              description: "Validates stuff")
        let violations = [
            StyleViolation(ruleDescription: ruleDescription,
                           severity: .warning,
                           location: Location(file: file, line: 10, character: 2),
                           reason: "Something is not right."),
            StyleViolation(ruleDescription: ruleDescription,
                           severity: .error,
                           location: Location(file: file, line: 5, character: nil),
                           reason: "Something is wrong.")
        ]

        cache.cache(violations: violations, forFile: file)
        let cachedViolations = cache.violations(forFile: file)

        XCTAssertNotNil(cachedViolations)
        XCTAssertEqual(cachedViolations!, violations)
    }

    func testParsesViolationsWithEmptyViolations() {
        let cache = LinterCache(currentVersion: Version(value: "0.2.0"))
        let file = "foo.swift"
        let cachedViolations = cache.violations(forFile: file)

        XCTAssertNil(cachedViolations)
    }

    func testClearsViolations() {
        let cache = LinterCache(currentVersion: Version(value: "0.2.0"))
        let file = "foo.swift"
        let ruleDescription = RuleDescription(identifier: "rule", name: "Some rule",
                                              description: "Validates stuff")
        let violations = [
            StyleViolation(ruleDescription: ruleDescription,
                           severity: .warning,
                           location: Location(file: file, line: 10, character: 2),
                           reason: "Something is not right."),
            StyleViolation(ruleDescription: ruleDescription,
                           severity: .error,
                           location: Location(file: file, line: 5, character: nil),
                           reason: "Something is wrong.")
        ]

        cache.cache(violations: violations, forFile: file)
        cache.clearViolations(forFile: file)

        let cachedViolations = cache.violations(forFile: file)

        XCTAssertNil(cachedViolations)
    }
}

extension LinterCacheTests {
    static var allTests: [(String, (LinterCacheTests) -> () throws -> Void)] {
        return [
            ("testInitThrowsWhenUsingDifferentVersion", testInitThrowsWhenUsingDifferentVersion),
            ("testInitThrowsWhenUsingInvalidCacheFormat", testInitThrowsWhenUsingInvalidCacheFormat),
            ("testInitThrowsWhenUsingInconsistentLastRunDate", testInitThrowsWhenUsingInconsistentLastRunDate),
            ("testInitThrowsWhenUsingDifferentConfiguration", testInitThrowsWhenUsingDifferentConfiguration),
            ("testInitSucceeds", testInitSucceeds),
            ("testInitSucceedsWithLastRunDate", testInitSucceedsWithLastRunDate),
            ("testInitSucceedsWithConfigurationHash", testInitSucceedsWithConfigurationHash),
            ("testLastRunDateIsNilByDefault", testLastRunDateIsNilByDefault),
            ("testSetLastRunDate", testSetLastRunDate),
            ("testParsesViolations", testParsesViolations),
            ("testParsesViolationsWithEmptyViolations", testParsesViolationsWithEmptyViolations),
            ("testClearViolations", testClearsViolations)
        ]
    }
}
