//
//  CameraController.swift
//  FishSnap
//
//  Created by Dulio Denis on 2/10/18.
//  Copyright © 2018 ddApps. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class CameraController: UIViewController {

    // base URL
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary //.camera
        imagePicker.allowsEditing = false
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FishClassifier().model) else {
            fatalError("Loading Core ML Model Failed.")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Model failed to process image.")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(fishName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    func requestInfo(fishName: String) {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : fishName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                let fishJSON : JSON = JSON(response.result.value!)
                let pageID = fishJSON["query"]["pageids"][0].stringValue
                let fishDescription = fishJSON["query"]["pages"][pageID]["extract"].stringValue
                let fishImageURL = fishJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: fishImageURL))
                self.descriptionLabel.text = fishDescription
            }
        }
    }
    
}


extension CameraController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let userPickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            guard let ciImage = CIImage(image: userPickedImage) else {
                // we could not convert the UIImage to a CIImage
                fatalError("Error converting image to a Core Image.")
            }
            
            detect(image: ciImage)
        }
        
        imagePicker.dismiss(animated: true)
    }
    
}
