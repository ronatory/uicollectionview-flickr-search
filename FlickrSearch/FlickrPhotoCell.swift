//
//  FlickrPhotoCell.swift
//  FlickrSearch
//
//  Created by ronatory on 12.11.16.
//  Copyright © 2016 ronatory. All rights reserved.
//

import UIKit

class FlickrPhotoCell: UICollectionViewCell {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  // MARK: Properties
  override var isSelected: Bool {
    didSet {
      imageView.layer.borderWidth = isSelected ? 10 : 0
    }
  }
  
  // MARK: View Life Cycle
  override func awakeFromNib() {
    super.awakeFromNib()
    imageView.layer.borderColor = themeColor.cgColor
    isSelected = false
  }
}
