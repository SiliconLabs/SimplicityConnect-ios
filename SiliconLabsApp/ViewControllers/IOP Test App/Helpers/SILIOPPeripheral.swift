//
//  SILIOPPeripheral.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

/*
 Contains all of custom services/characteristic that have IOP Test peripheral
 */
struct SILIOPPeripheral {
    struct SILIOPTest {
        static let uuid = "6A2857FE-9092-4E97-8AAE-C028E5B361A8"
        static let cbUUID = CBUUID(string: uuid)

        struct IOPTestVersion {
            static let uuid = "9E453FB5-42EE-4ED0-AAA4-74E11FC2C79F"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTestFeaturesRFU {
            static let uuid = "6CB60323-2D62-473D-8815-B73DF2EE3517"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTestControlRFU {
            static let uuid = "A432D31F-9022-4045-96FF-32258FFE7192"
            static let cbUUID = CBUUID(string: uuid)
        }
    }
    
    struct SILIOPTestProperties {
        static let uuid = "75247986-DB67-4E19-B0E3-DF8E8170BE68"
        static let cbUUID = CBUUID(string: uuid)
        
        struct IOPTest_ROLen1 {
            static let uuid = "B3319040-A720-44CE-84EC-D1A69420BBFB"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTest_ROLen255 {
            static let uuid = "B3319040-A720-44CE-84EC-D1A69420BBFC"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTest_WRLen1 {
            static let uuid = "38333E40-1D8F-47DF-A850-9CED9508BE27"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTest_WRLen255 {
            static let uuid = "38333E40-1D8F-47DF-A850-9CED9508BE28"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTest_WRNoResLen1 {
            static let uuid = "B8C15871-F456-40BC-9785-C144AF510FA6"
            static let cbUUID = CBUUID(string: uuid)
        }
         
        struct IOPTest_WRNoResLen255 {
            static let uuid = "B8C15871-F456-40BC-9785-C144AF510FA7"
            static let cbUUID = CBUUID(string: uuid)
        }

        struct IOPTest_NotifyLen1 {
            static let uuid = "14D56543-42E5-4771-A7F3-526DC92463A2"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTest_NotifyLen255 {
            static let uuid = "14D56543-42E5-4771-A7F3-526DC92463A3"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTest_IndicateLen1 {
            static let uuid = "2F1A964E-22F4-4E03-9EDF-751C74F5793C"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTest_IndicateLen255 {
            static let uuid = "2F1A964E-22F4-4E03-9EDF-751C74F5793D"
            static let cbUUID = CBUUID(string: uuid)
        }
    }
    
    struct SILIOPTestCharacteristicTypes {
        static let uuid = "3976265F-098C-4253-A2CD-99C16EB13F5C"
        static let cbUUID = CBUUID(string: uuid)
        
        struct IOPTestChar_RWLen1 {
            static let uuid = "999EF454-A850-427F-A87F-E72BC00471FF"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTestChar_RWLen255 {
            static let uuid = "D4138F32-397D-407C-8275-A5DAD47E4DE6"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTestChar_RWVariableLen4 {
            static let uuid = "DF8FF726-2022-4F9C-8B4D-96FD4ACD3C71"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTestChar_RWConstLen1 {
            static let uuid = "D4138F32-397D-407C-8275-A5DAD47E4DE7"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTestChar_RWConstLen255 {
            static let uuid = "D4138F32-397D-407C-8275-A5DAD47E4DE8"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTestChar_RWUserLen1 {
            static let uuid = "BB250D1B-154A-4AED-BFDE-0C5E8D577064"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTestChar_RWUserLen255 {
            static let uuid = "BB250D1B-154A-4AED-BFDE-0C5E8D57705E"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTestChar_RWUserLen4 {
            static let uuid = "BB250D1B-154A-4AED-BFDE-0C5E8D57705F"
            static let cbUUID = CBUUID(string: uuid)
        }
    }
    
    struct SILIOPTestPhase3 {
        static let uuid = "0B282FF4-5347-472B-93DA-F579103420FA"
        static let cbUUID = CBUUID(string: uuid)
        
        struct IOPTest_Phase3_Control {
            static let uuid = "148FD3C4-A00F-3905-D743-E94268E757E3"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTest_Security_Pairing {
            static let uuid = "8824E363-7392-4BFC-81B6-3E58104CB2B0"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTest_Security_Authen {
            static let uuid = "D14A264F-CDAC-C2A4-DCE5-9B9CA2073ABA"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTest_Security_Bonding {
            static let uuid = "6A978442-F37B-A07C-1A5F-0E6F15A5FC83"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTest_Throughput_GATT {
            static let uuid = "47B73DD6-DEE3-4DA1-9BE0-F5C539A9A4BE"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTest_GATT_Caching_7_5Test {
            static let uuid = "B5178061-69CE-46A9-3740-7B3C580953B0"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct IOPTest_GATT_Caching_7_6Test {
            static let uuid = "A6ABF2EB-B18D-E60F-5667-A9CD9E2971F1"
            static let cbUUID = CBUUID(string: uuid)
        }
    }

    struct SILIOPTestAttr {
        static let uuid = "0x1801"
        static let cbUUID = CBUUID(string: uuid)
    }
    
    struct Unknown {
        static let uuid = ""
        static let cbUUID = CBUUID(string: uuid)
    }
}
