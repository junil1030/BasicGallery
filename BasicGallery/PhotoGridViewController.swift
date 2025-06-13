//
//  PhotoGridViewController.swift
//  BasicGallery
//
//  Created by 서준일 on 6/12/25.
//

import UIKit
import Photos
import PhotosUI

class PhotoGridViewController: UIViewController {
    
    // MARK: - Types
    
    enum Section {
        case main
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<Section, PhotoItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, PhotoItem>
    
    // MARK: - Properties
    
    private var dataSource: DataSource!
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    private let imageManager = PHCachingImageManager()
    private let coreDataManager = CoreDataManager.shared
    
    private var currentColumnCount: CGFloat = 9.0
    private let possibleColumnCounts: [CGFloat] = [1.0, 3.0, 5.0, 7.0, 9.0, 11.0, 13.0, 15.0, 17.0, 19.0, 21.0, 23.0, 25.0, 27.0, 29.0, 31.0]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupDataSource()
        setupNavigationBar()
        setupGestures()
        requestPhotoLibraryPermission()
        loadPhotoAssets()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "사진"
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView.backgroundColor = .systemBackground
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupDataSource() {
        dataSource = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, photoItem in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
            cell.configure(with: photoItem, imageManager: self?.imageManager ?? PHCachingImageManager())
            return cell
        }
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
    }
    
    private func setupGestures() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        collectionView.addGestureRecognizer(pinchGesture)
    }
    
    // MARK: - Data Loading
    
    private func loadPhotoAssets() {
        let photoAssets = coreDataManager.fetchPhotoAssets()
        
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(photoAssets.map { PhotoItem(model: $0) })
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    //MARK: - Permission
    
    private func requestPhotoLibraryPermission() {
         PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
             DispatchQueue.main.async {
                 switch status {
                 case .authorized, .limited:
                     break
                 case .denied, .restricted, .notDetermined:
                     self.showPermissionRequiredAlert()
                 @unknown default:
                     break
                 }
             }
         }
     }
    
    private func showPermissionRequiredAlert() {
        let alert = UIAlertController(
            title: "사진 접근 권한 필요",
            message: "이 앱을 사용하려면 사진 라이브러리 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settingsUrl)
        })
        
        alert.addAction(UIAlertAction(title: "앱 종료", style: .destructive) { _ in
            exit(0)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    
    @objc private func addButtonTapped() {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.selectionLimit = 0
        config.filter = .any(of: [.images, .videos, .livePhotos])
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            let scale = gesture.scale
            
            if scale > 1.1 {
                decreaseColumns()
            } else if scale < 0.9 {
                increaseColumns()
            }
            
            gesture.scale = 1.0
        }
    }
    
    // MARK: - Layout Management
    
    private func decreaseColumns() {
        if let index = possibleColumnCounts.firstIndex(of: currentColumnCount),
           index > 0 {
            currentColumnCount = possibleColumnCounts[index - 1]
            animateLayoutChange()
        }
    }
    
    private func increaseColumns() {
        if let index = possibleColumnCounts.firstIndex(of: currentColumnCount),
           index < possibleColumnCounts.count - 1 {
            currentColumnCount = possibleColumnCounts[index + 1]
            animateLayoutChange()
        }
    }
    
    private func animateLayoutChange() {
        UIView.animate(withDuration: 0.3) {
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    // MARK: - Image Management
    
    private func requestImage(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension PhotoGridViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.frame.inset(by: collectionView.contentInset).width / currentColumnCount
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photoItem = dataSource.itemIdentifier(for: indexPath) else { return }

    }
}

// MARK: - PHPickerViewControllerDelegate

extension PhotoGridViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        for result in results {
            guard let assetIdentifier = result.assetIdentifier else { continue }
            
            let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
            guard let asset = assetResults.firstObject else { continue }
            
            let photoAsset = coreDataManager.createPhotoAsset(
                identifier: asset.localIdentifier,
                creationDate: asset.creationDate ?? Date(),
                mediaType: asset.mediaType
            )
            
            var snapshot = dataSource.snapshot()
            snapshot.appendItems([PhotoItem(model: photoAsset)], toSection: .main)
            dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
}
