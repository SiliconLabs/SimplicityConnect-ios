//
//  SILGattConfigurationModelMatchers.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 19/04/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

@testable import BlueGecko
import Foundation
import Quick
import Nimble

public func hasTheSameBluetoothFields<T: SILGattConfigurationCharacteristicEntity> (_ expectedValue: T?) -> Predicate<T> {
    return Predicate.define("equal <\(stringify(expectedValue))>") { actualExpression, msg in
        let actualValue = try actualExpression.evaluate()
        switch (expectedValue, actualValue) {
        case (nil, _?):
            return PredicateResult(status: .fail, message: msg.appendedBeNilHint())
        case (nil, nil), (_, nil):
            return PredicateResult(status: .fail, message: msg)
        case (let expected?, let actual?):
            var matches = expected.name == actual.name
            if !matches {
                return PredicateResult(bool: false, message: ExpectationMessage.expectedCustomValueTo("characteristic name: \(expected.name ?? "")", "characteristic name: \(actual.name ?? "")"))
            }
            matches = matches && expected.cbuuidString == actual.cbuuidString
            if !matches {
                return PredicateResult(bool: false, message: ExpectationMessage.expectedCustomValueTo("characteristic cbuuidString: \(expected.cbuuidString)", "characteristic cbuuidString: \(actual.cbuuidString)"))
            }
            matches = matches && expected.properties.count == actual.properties.count
            for property in expected.properties {
                matches = matches && actual.properties.contains(property)
            }
            if !matches {
                return PredicateResult(bool: false, message: ExpectationMessage.expectedCustomValueTo("characteristic properties: \(expected.properties)", "characteristic properties: \(actual.properties)"))
            }
            matches = matches && expected.initialValueType == actual.initialValueType
            if !matches {
                return PredicateResult(bool: false, message: ExpectationMessage.expectedCustomValueTo("characteristic initial value type: \(expected.initialValueType)", "characteristic initial value type: \(actual.initialValueType)"))
            }
            matches = matches && expected.initialValue == actual.initialValue
            if !matches {
                return PredicateResult(bool: false, message: ExpectationMessage.expectedCustomValueTo("characteristic initial value: \(expected.initialValue ?? "")", "characteristic initial value: \(actual.initialValue ?? "")"))
            }
            matches = matches && expected.descriptors.count == actual.descriptors.count
            if !matches {
                return PredicateResult(bool: false, message: ExpectationMessage.expectedCustomValueTo("descriptors number \(expected.descriptors.count)", "descriptors number \(actual.descriptors.count)"))
            }
            return PredicateResult(bool: matches, message: msg)
        }
    }
}

public func hasTheSameBluetoothFields<T: SILGattConfigurationDescriptorEntity> (_ expectedValue: T?) -> Predicate<T> {
    return Predicate.define("equal <\(stringify(expectedValue))>") { actualExpression, msg in
        let actualValue = try actualExpression.evaluate()
        switch (expectedValue, actualValue) {
        case (nil, _?):
            return PredicateResult(status: .fail, message: msg.appendedBeNilHint())
        case (nil, nil), (_, nil):
            return PredicateResult(status: .fail, message: msg)
        case (let expected?, let actual?):
            var matches = expected.name == actual.name
            if !matches {
                return PredicateResult(bool: false, message: ExpectationMessage.expectedCustomValueTo("descriptor name: \(expected.name ?? "")", "descriptor name: \(actual.name ?? "")"))
            }
            matches = matches && expected.cbuuidString == actual.cbuuidString
            if !matches {
                return PredicateResult(bool: false, message: ExpectationMessage.expectedCustomValueTo("descriptor cbuuidString: \(expected.cbuuidString)", "descriptor cbuuidString: \(actual.cbuuidString)"))
            }
            matches = matches && expected.properties.count == actual.properties.count
            for property in expected.properties {
                matches = matches && actual.properties.contains(property)
            }
            if !matches {
                return PredicateResult(bool: false, message: ExpectationMessage.expectedCustomValueTo("descriptor properties: \(expected.properties)", "descriptor properties: \(actual.properties)"))
            }
            matches = matches && expected.initialValueType == actual.initialValueType
            if !matches {
                return PredicateResult(bool: false, message: ExpectationMessage.expectedCustomValueTo("descriptor initial value type: \(expected.initialValueType)", "descriptor initial value type: \(actual.initialValueType)"))
            }
            matches = matches && expected.initialValue == actual.initialValue
            if !matches {
                return PredicateResult(bool: false, message: ExpectationMessage.expectedCustomValueTo("descriptor initial value: \(expected.initialValue ?? "")", "descriptor initial value: \(actual.initialValue ?? "")"))
            }
            return PredicateResult(bool: matches, message: msg)
        }
    }
}
