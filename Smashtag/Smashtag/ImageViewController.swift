//
//  ViewController.swift
//  Cassini
//
//  Created by Ömer Yetik on 27/11/2017.
//  Copyright © 2017 Ömer Yetik. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {

    // MARK: Model
    
    var imageURL: URL? {
        didSet {
            image = nil
            if view.window != nil {
                fetchImage()
            }
        }
    }

    // MARK: Private implementation
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    private func fetchImage() {
        if let url = imageURL {
            spinner.startAnimating()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let urlContents = try? Data(contentsOf: url)
                if let imageData = urlContents, url == self?.imageURL {
                    DispatchQueue.main.async {
                        self?.image = UIImage(data: imageData)
                    }
                }
            }

        }
    }
    
    
    // MARK: View Controller Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if image == nil {
            fetchImage()
        }
    }
    
    // MARK: User interface
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.minimumZoomScale = 0.03
            scrollView.maximumZoomScale = 100.0
            scrollView.contentSize = imageView.frame.size
            scrollView.addSubview(imageView)
        }
    }
    
    fileprivate var imageView = UIImageView()
    
    fileprivate var canAutoZoom: Bool = true
    
    private var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            imageView.sizeToFit()
            // During prepare scrollView is nil. To overcome a crash due to this fact, make the call an optional one
            scrollView?.contentSize = imageView.frame.size
            canAutoZoom = true
            autoZoomToFit()
            spinner?.stopAnimating()
        }
    }
    
    private func autoZoomToFit() {
        guard canAutoZoom == true else { return }
        guard let imageSize = imageView.image?.size else { return }
        guard let visibleRect = scrollView?.frame.size else { return }
        
        let widthRatio = visibleRect.width / imageSize.width
        let heightRatio = visibleRect.height / imageSize.height
        
        let zoomScale = max(widthRatio, heightRatio)
        
        scrollView.zoomScale = zoomScale
        
        scrollView.contentOffset = CGPoint(x: 0.0, y: 0.0 - (navigationController?.navigationBar.frame.size.height)!)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        autoZoomToFit()
    }
}

// MAR: UIScrollViewDelegate

extension ImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        canAutoZoom = false
    }
    
}

