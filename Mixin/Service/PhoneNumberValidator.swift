import Foundation
import PhoneNumberKit

final class PhoneNumberValidator {
    
    let phoneNumberKit = PhoneNumberKit()
    
    func isValid(callingCode: String, number: String) -> Bool {
        if (try? phoneNumberKit.parse("+" + callingCode + number)) != nil {
            return true
        } else if callingCode == "225" {
            // Côte d'Ivoire
            let possiblePrefixes = ["07", "05", "01", "27", "25", "21"]
            return possiblePrefixes.contains(where: { prefix in
                let possibleNumber = "+" + callingCode + prefix + number
                return (try? phoneNumberKit.parse(possibleNumber)) != nil
            })
        } else {
            return false
        }
    }
    
    func isValid(_ number: String) -> Bool {
        if (try? phoneNumberKit.parse(number)) != nil {
            return true
        } else if number.hasPrefix("+225"), number.count == 12 {
            // Côte d'Ivoire
            let possiblePrefixes = ["07", "05", "01", "27", "25", "21"]
            return possiblePrefixes.contains(where: { prefix in
                let mobileNumberStart = number.index(number.startIndex, offsetBy: 4)
                let mobileNumberEnd = number.endIndex
                let possibleNumber = "+225" + prefix + number[mobileNumberStart..<mobileNumberEnd]
                return (try? phoneNumberKit.parse(possibleNumber)) != nil
            })
        } else {
            return false
        }
    }
    
}
