//
//  Constants.swift
//  Dev-pixel-city
//
//  Created by Mac User on 5/15/19.
//  Copyright © 2019 Hammerhead96. All rights reserved.
//
//  API_KEY_FLICKR = "323ba3dfc5a8dad5c53109976a13a6ae"
//  https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=323ba3dfc5a8dad5c53109976a13a6ae&lat=47.99&lon=-122.12&radius=1&radius_units=mi&per_page=40&format=json&nojsoncallback=1

import Foundation

func flickrUrl(withAnnotation annotation: DroppablePin, andNumberOfPhotos number: Int) -> String {
    let URL = "\(BASE_URL)\(API_URL)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)\(RAD_URL)\(number)\(END_URL)"
    print(URL)
    return URL
}
// Gakkie
let BASE_URL = "https://api.flickr.com/services/rest/?method=flickr.photos.search"
let API_URL = "&api_key=323ba3dfc5a8dad5c53109976a13a6ae"
let RAD_URL = "&radius=1&radius_units=mi&per_page="
let END_URL = "&format=json&nojsoncallback=1"

