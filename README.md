# SiliconLabsDemo

## Overview:

* [Project Overview](#project-overview) - A general overview of the purpose of this project.
* [Project Setup](#project-setup) - How to get set up with the Blue Gecko iOS project.
* [Architecture](#architecture) - A general overview of the app's architecture.

## Project Overview

The Silicon Labs Blue Gecko App displays temperature measurements from the Silicon Labs Wireless Starter Kit (SLWSK). The app can also indicate proximity to the SLWSTK using Find Me Profile (FMP) & Proximity Profiles (PXP). Finally, the SLWSK can be configured as a Retail Beacon to send advertisement data to the App.

The current retail version can be found on the [US AppStore](https://itunes.apple.com/us/app/silicon-labs-blue-gecko-wstk/id1030932759?mt=8).

## Project Setup

In order to load firmware to the device, get set up with [Simplicity Studio](https://docs.google.com/a/intrepid.io/document/d/1Bk4Izx3yseiEIXx4PCqBxumd60vG6_SCHd7GhqOeQsE/edit?usp=sharing).

For Blue Gecko specific Simplicity Studio tutorial, check out this [video](https://drive.google.com/open?id=0B6c_wNPk_qCbNnQyc1pyMExBWFU).

The SiliconLabs iOS Application is built to support iOS 7.0 and higher, and utilizes [CocoaPods](https://cocoapods.org/#install) for library dependency management.

The application also contains a "hidden" debug button to the immediate right of the navigation bar that becomes visible on TouchDownInside, and contains a local Bluetooth device explorer.

## Architecture

#### Health Thermometer

To test the Health Thermometer, load the `SOC - Thermometer` firmware in [Simplicity Studio](https://drive.google.com/open?id=0B6c_wNPk_qCbd0ZBUU9hcXV6RTA). Open the app and select the Health Thermometer cell. You will be presented with a popover. You are able to select Blue Gecko devices or Other devices. Blue Geckos is selected by default. Select Other. You should see a thermometer called Thermometer Example in the list. You should be able to select that thermometer and be brought to a temperature readout screen.

#### Bluetooth Beaconing

##### iBeacons

When you enter the Bluetooth Beaconing portion of the app, the app begins to look for several types of "beacons". The app uses this method on CLLocationManager to look for official iBeacons (iBeacons):
```
- (void)startRangingBeaconsInRegion:(CLBeaconRegion *)region
```
These beacons conform to the iBeacon [protocol](https://developer.apple.com/ibeacon/Getting-Started-with-iBeacon.pdf). In order to search for iBeacons, you must know the UUID of the beacons in question. There is a hardcoded UUID in the app for just this purpose. If you load the `SOC - Smart Phone App` firmware to the Blue Gecko hardware, you can configure the hardware as an iBeacon by pressing the PB0 button beneath the LCD display.

**Note**: You will not be able to see multiple iBeacons using the `SOC - Smart Phone App` firmware! This firmware assigns the same UUID, major number and minor number to each device. The app will not be able to differentiate between these devices. If you want to test multiple iBeacons we suggest using a retail beacon such as an [Estimote](http://estimote.com/). You can configure the Estimote using its accompanying iOS or Android app. You will then have to update the UUID listed in the app. Also, use a `CLBeaconRegion` that does not use major and minor numbers. Also, the current iOS app design only shows ONE beacon at a time! If you are using multiple iBeacons, the app will display the metadata for whichever iBeacon is CLOSER to the phone. There is currently a [task](https://intrepid.atlassian.net/browse/SLMAIN-32) to display a list of beacons, the same way the Android app does.

##### AltBeacons, BGBeacons, Eddystone Beacons

For all other beacon types, the app simply scans for Bluetooth _peripherals_ using:
```
- (void)scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options;
```

Then, when peripherals are discovered, the app filters them based on other metadata. It classifies them as either an `AltBeacon` or a `BGBeacon`.

**\*\*At the time of this writing, I am unable to see any AltBeacons, BGBeacons or Eddystone Beacons in the app.\*\***

#### Key Fobs

In order to test the Key Fob mode, make sure that the `SOC - Smart Phone App` firmware is loaded. Open the app and select Key Fobs. Make sure that the hardware is displaying "HTM/KEYFOB MODE" on its LCD display. If it isn't, press the PB0 button. Then press the FIND button in the app. notice that the two small LEDs between the LCD display and the Blue Gecko board are now flashing! If you back out of the Key Fob screen you will see that the app is disconnecting and the LEDs will stop flashing.

#### Bluetooth Browser

The Bluetooth browser searches for all Bluetooth peripherals in the surrounding area.
