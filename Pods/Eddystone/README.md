# Eddystone CocoaPod

[![CI Status](http://img.shields.io/travis/BlueBiteLLC/Eddystone.svg?style=flat)](https://travis-ci.org/Tanner Nelson/Eddystone)
[![Version](https://img.shields.io/cocoapods/v/Eddystone.svg?style=flat)](http://cocoapods.org/pods/Eddystone)
[![License](https://img.shields.io/cocoapods/l/Eddystone.svg?style=flat)](http://cocoapods.org/pods/Eddystone)
[![Platform](https://img.shields.io/cocoapods/p/Eddystone.svg?style=flat)](http://cocoapods.org/pods/Eddystone)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

### Nearby

To fetch nearby Eddystone objects, simply start the scanner

```swift
Eddystone.Scanner.start(self)
```

Then get an array of the nearby objects

```swift
Eddystone.Scanner.nearby
```

To start the scanner, you will need to provide an `Eddystone.ScannerDelegate` delegate that will be notified to changes in the nearby objects

```swift
public protocol ScannerDelegate {
    func eddystoneNearbyDidChange()
}
```

Objects of the `Eddystone.Generic` class returned by `Eddystone.Scanner.nearby` have several properties gathered from the three Eddystone frame types and basic beacon information.

### Beacon
```swift
public var signalStrength: Beacon.SignalStrength
public var identifier: String
```

### Eddystone-URL
```swift
public var url: NSURL?
```

### Eddystone-UID
```swift
public var namespace: String?
public var instance: String?
public var uid: String?
```

### Eddystone-TLM
```swift
public var battery: Double?
public var temperature: Double?
public var advertisementCount: Int?
public var onTime: NSTimeInterval?
```

## URL or UID Specific Applications

Since Eddystone beacons may broadcast one or more of the frame types, most of the properties on the `Eddystone.Generic` class are optionals. If your application is dealing exlusively with Eddystone-URL or Eddystone-UID frame types, you may use the following `Eddystone.Scanner` properties instead.

Notice the objects returned by these methods have properties that are not optionals.

### Url
Get an array of `Eddystone.Url` objects with

```swift
Eddystone.Scanner.nearbyUrls
```

`Eddystone.Url` objects have the following properties

```swift
public var signalStrength: Beacon.SignalStrength
public var identifier: String
public var url: NSURL
```

### Uid
Get an array of `Eddystone.Uid` objects with

```swift
Eddystone.Scanner.nearbyUids
```

`Eddystone.Uid` objects have the following properties

```swift
public var signalStrength: Beacon.SignalStrength
public var identifier: String
public var namespace: String
public var instance: String
public var uid: String
```

##Debugging

Logs from the Eddystone module may be helpful while debugging your application. To enable logs, use the following line.

```swift
Eddystone.logging = true
```

## Additional Resources

### UITableViewExtensions.swift

As Eddystone beacons become closer or farther away from the device, they will need to be re-arranged on screen. The following gist makes re-arranging the data source for your `UITableView` much easier.

```swift
ExampleViewController: UIViewController, Eddystone.ScannerDelegate {
    var urls = Eddystone.Scanner.nearbyUrls
    var previousUrls: [Eddystone.Url] = []

    func eddystoneNearbyDidChange() {
        self.previousUrls = self.urls
        self.urls = Eddystone.Scanner.nearbyUrls

        self.mainTableView.switchDataSourceFrom(self.previousUrls, to: self.urls, withAnimation: .Top)
    }    
}
```

<https://gist.github.com/tannernelson/6d140c5ce2a701e4b710>

### SignalStrength

Showing the relative signal strength for an Eddystone object helps the user understand how close they are to the beacon. This cocoapod provides you with an iOS 7 style Signal Strength view that you can put anywhere in your application.

<https://cocoapods.org/pods/SignalStrength>

## Requirements

Eddystone uses CoreBluetooth

## Installation

Eddystone is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Eddystone"
```

## Examples

The Eddystone cocoapod comes with an example iOS project that shows how the various method calls work in a real application. The example application also includes the aforementioned Additional Resources.

## Author

Maintained by: Sam Krantz, sam@bluebite.com (@sekrantz)

Original by: Tanner Nelson, tanner@bluebite.com

## License

Eddystone is available under the MIT license. See the LICENSE file for more info.
