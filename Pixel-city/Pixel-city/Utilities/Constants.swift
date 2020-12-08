//
//  Constants.swift
//  Pixel-city
//
//  Created by Jacob Duell on 12/7/20.
//

import Foundation

let apiKey = "382061582d8e68811e431794cd28abec"

func flickrUrl(forApiKey key: String, withAnnotation annotation: DroppablePin, andNumberOfPhotos number: Int) -> String {
    return "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
}
