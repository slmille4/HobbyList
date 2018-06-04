//
//  Profile.swift
//  HobbyList
//
//  Created by Steve on 5/30/18.
//  Copyright © 2018 Steve. All rights reserved.
//

import Foundation
import Firebase

struct Profile:Codable {
    let id:String
    var age:String
    var gender:String
    var hobbies:[String]?
    var imagePath:String
    var name:String
}

extension Profile {
    static func parse(index:String, element:Any) -> Profile? {
        let id = index
        if let profileDict = element as? [String:Any],
            let age = profileDict["age"] as? String,
            let gender = profileDict["gender"] as? String,
            let imagePath = profileDict["imagePath"] as? String,
            let name = profileDict["name"] as? String {
            let hobbies = profileDict["hobbies"] as? [String]
            return Profile(id: id, age: age, gender: gender, hobbies: hobbies, imagePath: imagePath, name: name)
        }
        return nil
    }
}
