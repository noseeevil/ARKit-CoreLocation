//
//  JSONStruct.swift
//  ARKit+CoreLocation
//
//  Created by noseeevil on 29/11/2018.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import Foundation

struct FirstLevel: Codable
{
    var result: ResultStruct?
}

struct ResultStruct: Codable
{
    var items: [ItemStruct?]
}

struct ItemStruct: Codable
{
    var id: Int?
    var rooms: Int?
    var area: Float?
    var floor: Int?
    var floors: Int?
    var price: Float64?
    var location: LocationStruct?
    //var photo: [String?]
}

struct LocationStruct: Codable
{
    var lon: Double?
    var lat: Double?
}
