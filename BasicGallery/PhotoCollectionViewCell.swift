//
//  PhotoCollectionViewCell.swift
//  BasicGallery
//
//  Created by 서준일 on 6/12/25.
//

import UIKit
import Photos

class PhotoCollectionViewCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private let videoIndicator: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "video.fill"))
        imageView.tintColor = .white
        imageView.isHidden = true
        return imageView
    }()
    
    private let livePhotoIndicator: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "livephoto"))
        imageView.tintColor = .white
        imageView.isHidden = true
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(imageView)
        contentView.addSubview(videoIndicator)
        contentView.addSubview(livePhotoIndicator)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        videoIndicator.translatesAutoresizingMaskIntoConstraints = false
        livePhotoIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            videoIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            videoIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            
            livePhotoIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            livePhotoIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5)
        ])
    }
    
    func configure(with photoAsset: PhotoItem, imageManager: PHImageManager) {
        if let thumbnail = photoAsset.thumbnail {
            self.imageView.image = thumbnail
        } else {
            let asset = PHAsset.fetchAssets(withLocalIdentifiers: [photoAsset.model.identifier!], options: nil).firstObject
            
            if let asset = asset {
                let size = CGSize(width: self.bounds.width, height: self.bounds.width)
                    .applying(.init(scaleX: UIScreen.main.scale, y: UIScreen.main.scale))
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isSynchronous = false
                options.isNetworkAccessAllowed = true
                
                Task {
                    let image = await withCheckedContinuation { continuation in
                        PHCachingImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
                            continuation.resume(returning: image)
                        }
                    }
                    self.imageView.image = image
                    photoAsset.thumbnail = image
                }
                
                
                let mediaType = PHAssetMediaType(rawValue: Int(photoAsset.model.mediaType)) ?? .unknown
                switch mediaType {
                case .video:
                    videoIndicator.isHidden = false
                case .image:
                    if asset.mediaSubtypes.contains(.photoLive) {
                        livePhotoIndicator.isHidden = false
                    }
                default:
                    break
                }
            }
        }
    }
}
