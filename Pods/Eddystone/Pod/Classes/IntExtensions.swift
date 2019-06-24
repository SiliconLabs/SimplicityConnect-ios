/**
    IntExtensions.swift

    Convert an arbitrary length byte array into a Swift Int

    <https://gist.github.com/e720877bf7700138eb99.git>
*/

extension Int {
    static func fromByteArray(_ bytes: [UInt8]) -> Int {
        var int = 0
        
        for (offset, byte) in bytes.enumerated() {
            let factor: Double = Double(bytes.count) - (Double(offset) + 1);
            let size: Double = 256
            
            int += Int(byte) * Int(pow(size, factor))
        }
        
        return int
    }
}
