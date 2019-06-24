/**
    Converts 16-bit 8:8 Fixed Point numbers to swift Doubles.

    Fixed Point mathematical functions:
    <https://courses.cit.cornell.edu/ee476/Math/>

    Compare the results from these calls to the Examples from the "Fixed Point mathematical functions" paper.

    Double.from88FixedPoint(0, 0)
    Double.from88FixedPoint(1, 0)
    Double.from88FixedPoint(1, 128)
    Double.from88FixedPoint(1, 192)
    Double.from88FixedPoint(1, 1)
    Double.from88FixedPoint(255, 0)
    Double.from88FixedPoint(254, 128)
    Double.from88FixedPoint(254, 0)
    Double.from88FixedPoint(129, 0)
    Double.from88FixedPoint(255, 128)
    Double.from88FixedPoint(255, 192)
    Double.from88FixedPoint(0, 128)
    Double.from88FixedPoint(128, 0)
    Double.from88FixedPoint(127, 0)
    Double.from88FixedPoint(2, 64)
    Double.from88FixedPoint(253, 192)

    <https://gist.github.com/24030969dacc6d9b4885.git>
*/

extension Double {
    static func from88FixedPoint(_ byte1: UInt8, _ byte2: UInt8) -> Double {
        var double: Double = 0
        
        var integer = Double(byte1)
        let fraction = Double(byte2)
        
        if integer >= 256 / 2 {
            integer -= 256
        }
        
        double += Double(integer)
        double += (1 / 256) * Double(fraction)
        
        return double
    }
}
