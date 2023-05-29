import Foundation

struct TIPIdentity {
    
    let seed: Data
    
}

extension TIPIdentity: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case seed = "seed_base64"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let encoded = try container.decode(String.self, forKey: .seed)
        if let decoded = Data(base64URLEncoded: encoded) {
            self.seed = decoded
        } else {
            let context = DecodingError.Context(codingPath: [CodingKeys.seed], debugDescription: "Base64url decoding failed")
            throw DecodingError.dataCorrupted(context)
        }
    }
    
}
