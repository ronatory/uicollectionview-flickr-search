//
//  FlickrPhotosViewController.swift
//  FlickrSearch
//
//  Created by ronatory on 11.11.16.
//  Copyright © 2016 ronatory. All rights reserved.
//

import UIKit

final class FlickrPhotosViewController: UICollectionViewController {
  
  // MARK: Properties
  fileprivate let reuseIdentifier = "FlickrCell"
  fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
  fileprivate var searches = [FlickrSearchResults]()
  fileprivate let flickr = Flickr()
  fileprivate let itemsPerRow: CGFloat = 3
}

extension FlickrPhotosViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    // 1
    // adding a activity view
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    textField.addSubview(activityIndicator)
    activityIndicator.frame = textField.bounds
    activityIndicator.startAnimating()
    
    // use Flickr wrapper class to search Flickr for photos that match the given search term asynchronously
    // when search complets, the completion block will be called with the result set of FlickrPhoto objects and error (if there is one)
    flickr.searchFlickrForTerm(textField.text!) { results, error in
      
      activityIndicator.removeFromSuperview()
      
      if let error = error {
        // 2
        // log any errors to the console. In production display these errors to user
        print("Error searching: \(error)")
        return
      }
      
      if let results = results {
        // 3
        // results get logged and added to the front of the searches array
        print("Found \(results.searchResults.count) matching \(results.searchTerm)")
        self.searches.insert(results, at: 0)
        
        // 4
        // you have new data at this stage and you need to refresh the UI
        self.collectionView?.reloadData()
      }
    }
    
    textField.text = nil
    textField.resignFirstResponder()
    return true
  }
}

// MARK: Private
private extension FlickrPhotosViewController {
  // will get a specific photo related to an index path in your collection view
  func photoForIndexPath(indexPath: IndexPath) -> FlickrPhoto {
    return searches[(indexPath as NSIndexPath).section].searchResults[(indexPath as NSIndexPath).row]
  }
}

// MARK: UICollectionViewDataSource
extension FlickrPhotosViewController {
  // there's one search per section, to number of sections is the count of the searches array
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return searches.count
  }
  
  // number of items in a section is the count of the searchResults array from the relevant FlickrSearchObject
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return searches[section].searchResults.count
  }
  
  // configure cell 
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    // the cell coming back is a FlickrPhotoCell
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FlickrPhotoCell
    
    // need to get the FlickrPhoto represent the photo to display, using the convenience method from earlier
    let flickrPhoto = photoForIndexPath(indexPath: indexPath)
    cell.backgroundColor = UIColor.white
    
    // populate the image view with the thumbnail
    cell.imageView.image = flickrPhoto.thumbnail
    
    return cell
  }
}

extension FlickrPhotosViewController: UICollectionViewDelegateFlowLayout {
  // responsible for telling the layout the size of a given cell
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    // here you work out the total amount of space taken up by padding
    // there will be n + 1 evenly sized spaces, where n is the number of items in the row
    // the space size can be taken from the left section inset
    // subtracting this from the view's width and dividing by the number of items in a row gives you the width for each item
    let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / itemsPerRow
    
    // return the size as a square
    return CGSize(width: widthPerItem, height: widthPerItem)
  }
  
  // return the spacing between the cells, headers, and footers. Used a constant for that
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return sectionInsets
  }
  
  // controls the spacing between each line in the layout. this should be matched the padding at the left and right
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }
}
