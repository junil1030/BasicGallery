//
//  PhotoItem.swift
//  BasicGallery
//
//  Created by 서준일 on 6/12/25.
//

import UIKit

class PhotoItem: NSObject {
    var model: PhotoAsset
    var thumbnail: UIImage?
    
    init(model: PhotoAsset, thumbnail: UIImage? = nil) {
        self.model = model
        self.thumbnail = thumbnail
    }
}
