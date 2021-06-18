//
//  SILTemperatureMeasurementSpec.m
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 24/02/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

@import Quick;
@import Nimble;
#import <Foundation/Foundation.h>
#import "SILTemperatureMeasurement.h"

QuickSpecBegin(SILTemperatureMeasurementSpec)

__block NSMutableData *inputData;
__block SILTemperatureMeasurement *sut;
beforeEach(^{
    inputData = [NSMutableData data];
});

context(@"basic properties", ^{
    beforeEach(^{
        char bytes[6] = { 0x04, 0x00, 0x00, 0x00, 0x00, 0x00 };
        [inputData appendBytes:bytes length:6];
        sut = [SILTemperatureMeasurement decodeTemperatureMeasurementWithData:inputData];
    });
    
    it(@"should not be nil", ^{
        expect(sut).toNot(beNil());
    });
    
    it(@"should not be in Fahrenheit", ^{
        expect(sut.isFahrenheit).to(beFalse());
    });
    
    it(@"should has measurement date", ^{
        expect(sut.measurementDate).toNot(beNil());
    });
});

context(@"temperature type", ^{
    beforeEach(^{
        char bytes[6] = { 0x04, 0x00, 0x00, 0x00, 0x00, 0x09 };
        [inputData appendBytes:bytes length:6];
        sut = [SILTemperatureMeasurement decodeTemperatureMeasurementWithData:inputData];
    });
    
    it(@"should be typanum for 0x09", ^{
        expect(sut).toNot(beNil());
        expect(@(sut.temperatureType)).to(equal(SILTemperatureTypeTypanum));
    });
});

context(@"for positive number", ^{
    beforeEach(^{
        char bytes[6] = { 0x04, 0x1b, 0x0e, 0x00, 0xfe, 0x09 };
        [inputData appendBytes:bytes length:6];
        sut = [SILTemperatureMeasurement decodeTemperatureMeasurementWithData:inputData];
    });
    
    it(@"should has proper value with accuracy", ^{
        expect(sut).toNot(beNil());
        expect(sut.value).to(beCloseTo(36.11).within(0.1));
    });
});

context(@"for negative number", ^{
    it(@"should has proper value with accuracy - first number", ^{
        char bytes[6] = { 0x04, 0x7b, 0xef, 0xff, 0xff, 0x09 };
        [inputData appendBytes:bytes length:6];
        sut = [SILTemperatureMeasurement decodeTemperatureMeasurementWithData:inputData];
        expect(sut).toNot(beNil());
        expect(sut.value).to(beCloseTo(-422.9).within(0.1));
    });
    
    it(@"should has proper value with accuracy - second number", ^{
        char bytes[6] = { 0x04, 0x7b, 0xef, 0xff, 0xfd, 0x09 };
        [inputData appendBytes:bytes length:6];
        sut = [SILTemperatureMeasurement decodeTemperatureMeasurementWithData:inputData];
        expect(sut).toNot(beNil());
        expect(sut.value).to(beCloseTo(-4.229).within(0.0001));
    });
});

QuickSpecEnd
