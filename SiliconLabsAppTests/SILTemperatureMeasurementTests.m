//
//  SILTemperatureMeasurementTests.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/19/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SILTemperatureMeasurement.h"

@interface SILTemperatureMeasurementTests : XCTestCase

@property (strong, nonatomic) NSMutableData *inputData;
@property (strong, nonatomic) SILTemperatureMeasurement *sut;

@end

@implementation SILTemperatureMeasurementTests

- (void)setUp {
    [super setUp];

    self.inputData = [NSMutableData data];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testIsFahrenheit {
    //given
    char bytes[6] = { 0x04, 0x00, 0x00, 0x00, 0x00, 0x00 };
    [self.inputData appendBytes:bytes length:6];

    //when
    self.sut = [SILTemperatureMeasurement decodeTemperatureMeasurementWithData:self.inputData];

    //then
    XCTAssertNotNil(self.sut);
    XCTAssertFalse(self.sut.isFahrenheit);
}

- (void)testMeasurementDate {
    //given
    char bytes[6] = { 0x04, 0x00, 0x00, 0x00, 0x00, 0x00 };
    [self.inputData appendBytes:bytes length:6];

    //when
    self.sut = [SILTemperatureMeasurement decodeTemperatureMeasurementWithData:self.inputData];

    //then
    XCTAssertNotNil(self.sut);
    XCTAssertNotNil(self.sut.measurementDate);
}

- (void)testTemperatureType {
    //given
    char bytes[6] = { 0x04, 0x00, 0x00, 0x00, 0x00, 0x09 };
    [self.inputData appendBytes:bytes length:6];

    //when
    self.sut = [SILTemperatureMeasurement decodeTemperatureMeasurementWithData:self.inputData];

    //then
    XCTAssertNotNil(self.sut);
    XCTAssertEqual(SILTemperatureTypeTypanum, self.sut.temperatureType);
}

- (void)testPositiveNumber {
    //given
    char bytes[6] = { 0x04, 0x1b, 0x0e, 0x00, 0xfe, 0x09 };
    [self.inputData appendBytes:bytes length:6];

    //when
    self.sut = [SILTemperatureMeasurement decodeTemperatureMeasurementWithData:self.inputData];

    //then
    XCTAssertNotNil(self.sut);
    XCTAssertEqualWithAccuracy(36.11, self.sut.value, 0.1);
}

- (void)testNegativeNumber {
    //given
    char bytes[6] = { 0x04, 0x7b, 0xef, 0xff, 0xff, 0x09 };
    [self.inputData appendBytes:bytes length:6];

    //when
    self.sut = [SILTemperatureMeasurement decodeTemperatureMeasurementWithData:self.inputData];

    //then
    XCTAssertNotNil(self.sut);
    XCTAssertEqualWithAccuracy(-422.9, self.sut.value, 0.1);
}

- (void)testAnotherNegativeNumber {
    //given
    char bytes[6] = { 0x04, 0x7b, 0xef, 0xff, 0xfd, 0x09 };
    [self.inputData appendBytes:bytes length:6];

    //when
    self.sut = [SILTemperatureMeasurement decodeTemperatureMeasurementWithData:self.inputData];

    //then
    XCTAssertNotNil(self.sut);
    XCTAssertEqualWithAccuracy(-4.229, self.sut.value, 0.0001);
}

@end
