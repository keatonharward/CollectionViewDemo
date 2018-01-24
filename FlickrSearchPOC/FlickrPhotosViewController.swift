//
//  FlickrPhotosViewController.swift
//  FlickrSearchPOC
//
//  Created by Keaton Harward on 1/23/18.
//  Copyright © 2018 Keaton Harward. All rights reserved.
//

import UIKit

private let reuseIdentifier = "FlickrCell"
private let headerReuseIdentifier = "FlickrPhotoHeader"

class FlickrPhotosViewController: UICollectionViewController {

    // MARK: - Properties
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate var searches = [FlickrSearchResults]()
    fileprivate let flickr = Flickr()
    fileprivate let itemsPerRow: CGFloat = 3
    
    var largePhotoIndexPath: IndexPath? {
        didSet {
            var indexPaths = [IndexPath]()
            if let largePhotoIndexPath = largePhotoIndexPath {
                indexPaths.append(largePhotoIndexPath)
            }
            if let oldValue = oldValue {
                indexPaths.append(oldValue)
            }
            collectionView?.performBatchUpdates({
                self.collectionView?.reloadItems(at: indexPaths)
            }, completion: { (completed) in
                if let largePhotoIndexPath = self.largePhotoIndexPath {
                    self.collectionView?.scrollToItem(at: largePhotoIndexPath, at: .centeredVertically, animated: true)
                }
            })
        }
    }
}

// MARK: - UICollectionViewDataSource
extension FlickrPhotosViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return searches.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searches[section].searchResults.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FlickrPhotoCell
        var photo = photoForIndexPath(indexPath: indexPath)
        
        cell.activityIndicator.stopAnimating()
        
        guard indexPath == largePhotoIndexPath else {
            cell.imageView.image = photo.thumbnail
            return cell
        }
        
        guard photo.largeImage == nil else {
            cell.imageView.image = photo.largeImage
            return cell
        }
        
        cell.imageView.image = photo.thumbnail
        cell.activityIndicator.startAnimating()
        
        photo.loadLargeImage { (loadedPhoto, error) in
            cell.activityIndicator.stopAnimating()
            guard loadedPhoto.largeImage != nil && error == nil else {
                return
            }
            
            if let cell = collectionView.cellForItem(at: indexPath) as? FlickrPhotoCell, indexPath == self.largePhotoIndexPath {
                cell.imageView.image = loadedPhoto.largeImage
            }
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! FlickrPhotoHeaderView
            headerView.label.text = searches[indexPath.section].searchTerm
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
}

// MARK: - UICollectionViewDelegate
extension FlickrPhotosViewController {
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        largePhotoIndexPath = largePhotoIndexPath == indexPath ? nil : indexPath
        return false
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FlickrPhotosViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath == largePhotoIndexPath {
            let flickrPhoto = photoForIndexPath(indexPath: indexPath)
            var size = collectionView.bounds.size
            size.height -= topLayoutGuide.length
            size.height -= (sectionInsets.top + sectionInsets.right)
            size.width -= (sectionInsets.left + sectionInsets.right)
            return flickrPhoto.sizeToFillWidthOfSize(size)
        }
        let padding = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - padding
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

// MARK: - Search field
extension FlickrPhotosViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        activityIndicator.startAnimating()
        
        flickr.searchFlickrForTerm(textField.text!) { (results, error) in
            activityIndicator.removeFromSuperview()
            
            if let error = error {
                print("Error searching: \(error)")
                return
            }
            
            if let results = results {
                print("Found \(results.searchResults.count) results matching \(results.searchTerm)")
                self.searches.insert(results, at: 0)
            }
            
            self.collectionView?.reloadData()
        }
        textField.text = nil
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Private (elper functions)
private extension FlickrPhotosViewController {
    func photoForIndexPath(indexPath: IndexPath) -> FlickrPhoto {
        return searches[indexPath.section].searchResults[indexPath.row]
    }
}
