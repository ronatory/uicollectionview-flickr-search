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
  // will keep track of the photos the user has selected
  fileprivate var selectedPhotos = [FlickrPhoto]()
  // will provide feedback to the user on how many photos have been selected
  fileprivate let shareTextLabel = UILabel()
  // An optional that will hold the index path of the tapped photo, if there is one
  var largePhotoIndexPath: IndexPath? {
    didSet {
      // whenever this property gets updated the collection view needs to be updated
      // a didSet property observer is the safest place to manage this. there may be two cells that need reloading if the user has tapped one cell then another
      // or just one if the user has tapped the first vell, then tapped it again to shrink
      var indexPaths = [IndexPath]()
      if let largePhotoIndexPath = largePhotoIndexPath {
        indexPaths.append(largePhotoIndexPath)
      }
      if let oldValue = oldValue {
        indexPaths.append(oldValue)
      }
      // performBatchUpdates will animate any changes to the collection view performed inside the block. you want it to reload the affected cells
      collectionView?.performBatchUpdates({ 
        self.collectionView?.reloadItems(at: indexPaths)
      }, completion: { completed in
        // once the animated update has finished, its a nice touch to scroll the enlarged cell to the middle of the screen
        if let largePhotoIndexPath = self.largePhotoIndexPath {
          self.collectionView?.scrollToItem(at: largePhotoIndexPath, at: .centeredVertically, animated: true)
        }
      })
    }
  }
  // a bool with another property observer similar to largePhotoIndexPath above
  // in this observer you toggle the multiple selection status of the collection view, clear any existing selection and empty the selected photos array
  // you also update the bar button items to include and update the shareTextLabel
  var sharing: Bool = false {
    didSet {
      collectionView?.allowsMultipleSelection = sharing
      collectionView?.selectItem(at: nil, animated: true, scrollPosition: UICollectionViewScrollPosition())
      selectedPhotos.removeAll(keepingCapacity: false)
      
      guard let shareButton = self.navigationItem.rightBarButtonItems?.first else {
        return
      }
      
      guard sharing else {
        navigationItem.setRightBarButtonItems([shareButton], animated: true)
        return
      }
      
      if let _ = largePhotoIndexPath {
        largePhotoIndexPath = nil
      }
      
      updateSharePhotoCount()
      let sharingDetailItem = UIBarButtonItem(customView: shareTextLabel)
      navigationItem.setRightBarButtonItems([shareButton, sharingDetailItem], animated: true)
    }
  }
  @IBAction func share(_ sender: UIBarButtonItem) {
    // make sure the user has actually searched for something
    guard !searches.isEmpty else {
      return
    }
    
    // make sure the user has selected photos to share
    guard !selectedPhotos.isEmpty else {
      sharing = !sharing
      return
    }
    
    // if sharing false, just return
    guard sharing else {
      return
    }
    
    // share your photos
    
    // create an array of UIImage objects from the FlickrPhotos thumbnails
    // the UIImage array is much more convenient as we can simply pass it to a UIActivityViewController
    // the UIActivityViewController will show the user any image sharing services or actions available on the device: iMessage, Mail, Print, etc
    var imageArray = [UIImage]()
    for selectedPhoto in selectedPhotos {
      if let thumbnail = selectedPhoto.thumbnail {
        imageArray.append(thumbnail)
      }
    }
    
    if !imageArray.isEmpty {
      let shareScreen = UIActivityViewController(activityItems: imageArray, applicationActivities: nil)
      shareScreen.completionWithItemsHandler = { _ in
        self.sharing = false
      }
      let popoverPresentationController = shareScreen.popoverPresentationController
      popoverPresentationController?.barButtonItem = sender
      popoverPresentationController?.permittedArrowDirections = .any
      present(shareScreen, animated: true, completion: nil)
    }
  }
}

// MARK: UITextFieldDelegate
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
  
  // will keep shareTextLabel up to date
  func updateSharePhotoCount() {
    shareTextLabel.textColor = themeColor
    shareTextLabel.text = "\(selectedPhotos.count) photos selected"
    shareTextLabel.sizeToFit()
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
  
  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    // kind parameter is supplied by the layout object and indicates which sort of supplementary view is being asked for
    switch kind {
    // UICollectionElementKindSectionHeader is a supplementary view kind belonging to the flow layout
    // by checking that box in the storyboard to add a section header, you told the flow layout that it needs to start asking for these views
    case UICollectionElementKindSectionHeader:
      // headerView is dequeued using the identifier added in the storyboard. the labels text is then set to the relevant search term
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FlickrPhotoHeaderView", for: indexPath) as! FlickrPhotoHeaderView
      headerView.label.text = searches[(indexPath as NSIndexPath).section].searchTerm
      return headerView
    default:
      // place an assert here to make clear that you're not expecting to be asked for anything other than a header view
      assert(false, "Unexpected element kind")
    }
  }
  
  // configure cell 
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    // the cell coming back is a FlickrPhotoCell
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FlickrPhotoCell
    
    // need to get the FlickrPhoto represent the photo to display, using the convenience method from earlier
    let flickrPhoto = photoForIndexPath(indexPath: indexPath)
    
    // Always stop the activity spinner - you could be reusing a cell that was previously loading an image
    cell.activityIndicator.stopAnimating()
    
    // if you are not looking at the large photo, just set the thumbnail image and return
    guard indexPath == largePhotoIndexPath else {
      cell.imageView.image = flickrPhoto.thumbnail
      return cell
    }
    
    // if the large image is already loaded, set it and return
    guard flickrPhoto.largeImage == nil else {
      cell.imageView.image = flickrPhoto.largeImage
      return cell
    }
    
    // by this point you want the large image, but it doesn't exist yet. set the thumbnail image
    // and start the spinner going. the thumbnail will stretch until the download is complete
    cell.imageView.image = flickrPhoto.thumbnail
    cell.activityIndicator.startAnimating()
    
    // ask for the large image from Flickr. this loads the image asynchronously and has a completion block
    flickrPhoto.loadLargeImage { loadedFlickrPhoto, error in
      
      // the load has finished so stop the spinner
      cell.activityIndicator.stopAnimating()
      
      // if there was an error or no photo was loaded, there's not much you can do
      guard loadedFlickrPhoto.largeImage != nil && error == nil else {
        return
      }
      
      // check the large photo index path hasn't changed while the download was happening
      // and retrieve whatever cell is currently in use for that index path (it may not be the original cell, since scrolling could have happened) and set the large image
      if let cell = collectionView.cellForItem(at: indexPath) as? FlickrPhotoCell,
        indexPath == self.largePhotoIndexPath {
        cell.imageView.image = loadedFlickrPhoto.largeImage
      }
    }
    return cell
  }
  
  // simply remove the moving item from it source place it the results array and then reinserted it into the array in its new position
  override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    // source
    var sourceResults = searches[(sourceIndexPath as NSIndexPath).section].searchResults
    let flickrPhoto = sourceResults.remove(at: (sourceIndexPath as NSIndexPath).row)
    
    // result
    var destinationResults = searches[(destinationIndexPath as NSIndexPath).section].searchResults
    destinationResults.insert(flickrPhoto, at: (destinationIndexPath as NSIndexPath).row)
  }
}

// MARK: UICollectionViewDelegate
extension FlickrPhotosViewController {
  // if tapped cell is already the large photo, set the largePhotoIndexPath property to nil, otherwise set it to the index path the user just tapped
  // this will then call the property observer you added earlier and cause the collection view to reload the affected cells
  override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    // this will allow the user to select cells now
    guard !sharing else {
      return true
    }
    
    largePhotoIndexPath = largePhotoIndexPath == indexPath ? nil : indexPath
    return false
  }
  
  // this method allows adding selected photos to the shared photos array and updates the shareTextLabel
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard sharing else {
      return
    }
    
    let photo = photoForIndexPath(indexPath: indexPath)
    selectedPhotos.append(photo)
    updateSharePhotoCount()
  }
  
  // this method removes a photo from the shared photos array and updates the shareTextLabel
  override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    guard sharing else {
      return
    }
    
    let photo = photoForIndexPath(indexPath: indexPath)
    
    if let index = selectedPhotos.index(of: photo) {
      selectedPhotos.remove(at: index)
      updateSharePhotoCount()
    }
  }
}

// MARK: UICollectionViewDelegateFlowLayout
extension FlickrPhotosViewController: UICollectionViewDelegateFlowLayout {
  // responsible for telling the layout the size of a given cell
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    // calculates the size of the cell to fill as much of the collection view as possible whilst maintaining its aspect ratio
    if indexPath == largePhotoIndexPath {
      let flickrPhoto = photoForIndexPath(indexPath: indexPath)
      var size = collectionView.bounds.size
      size.height -= topLayoutGuide.length
      size.height -= (sectionInsets.top + sectionInsets.right)
      size.width -= (sectionInsets.left + sectionInsets.right)
      return flickrPhoto.sizeToFillWidthOfSize(size)
    }
    
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
