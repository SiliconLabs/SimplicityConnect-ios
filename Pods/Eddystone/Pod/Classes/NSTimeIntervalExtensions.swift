/**
    NSTimeIntervalExtensions.swift

    Return human readable string for any NSTimeInterval

    <https://gist.github.com/e5d2e0bab5a58b938b08.git>
*/

import Foundation

public extension TimeInterval {
    var readable: String {
        get {
            let second = 1
            let minute = second * 60
            let hour = minute * 60
            let day = hour * 24
            
            var num: Int = Int(abs(self))
            var unit = "day"
            
            if num >= day {
                num /= day
            } else if num >= hour {
                num /= hour
                unit = "hour"
            } else if num >= minute {
                num /= minute
                unit = "minute"
            } else if num >= second {
                num /= second
                unit = "second"
            } else {
                num = 0
            }
            
            if num > 1 {
                unit += "s"
            }
            
            if num == 0 {
                return "now"
            } else {
                return "\(num) \(unit)"
            }
        }
    }
}
