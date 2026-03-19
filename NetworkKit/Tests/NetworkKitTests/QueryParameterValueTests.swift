//
//  QueryParameterValueTests.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import XCTest
@testable import NetworkKit

final class QueryParameterValueTests: XCTestCase {

    // MARK: - intArray

    func test_intArray_toURLQueryItems_repeatsKey() {
        let items = QueryParameterValue.intArray([1, 2, 3]).toURLQueryItems(name: "ids")

        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0], URLQueryItem(name: "ids", value: "1"))
        XCTAssertEqual(items[1], URLQueryItem(name: "ids", value: "2"))
        XCTAssertEqual(items[2], URLQueryItem(name: "ids", value: "3"))
    }

    func test_intArray_empty_producesNoItems() {
        let items = QueryParameterValue.intArray([]).toURLQueryItems(name: "ids")

        XCTAssertTrue(items.isEmpty)
    }

    // MARK: - date

    func test_date_usesCustomFormat() {
        var components = DateComponents()
        components.year = 2026; components.month = 3; components.day = 19
        components.hour = 0; components.minute = 0; components.second = 0
        let date = Calendar(identifier: .gregorian).date(from: components)!

        let items = QueryParameterValue.date(date, format: "yyyy-MM-dd").toURLQueryItems(name: "from")

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].value, "2026-03-19")
    }

    func test_date_defaultFormat_isISO8601() {
        let items = QueryParameterValue.date(Date(timeIntervalSince1970: 0)).toURLQueryItems(name: "ts")

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].value, "1970-01-01T00:00:00+0000")
    }
}
