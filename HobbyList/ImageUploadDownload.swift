//
//  ImageUploader.swift
//  HobbyList
//
//  Created by Steve on 6/3/18.
//  Copyright © 2018 Steve. All rights reserved.
//

import FirebaseStorage

func downloadImage(urlString:String, completion:@escaping (UIImage)->()) {
    guard let url = URL(string: urlString) else { return }
    
    URLSession.shared.dataTask(with: url) {
        (data, response, error) in
        guard error == nil else {
            print(error.debugDescription)
            return
        }
        DispatchQueue.main.async {
            if let downloadedImage = UIImage(data:data!) {
                completion(downloadedImage)
            }
        }
    }.resume()
}

func uploadImage(_ image: UIImage, progressBlock: @escaping (_ percentage: Double) -> Void, completionBlock: @escaping (_ url: URL?, _ errorMessage: String?) -> Void) {
    let imageName = NSUUID().uuidString
    let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).png")
    
    if let imageData = UIImageJPEGRepresentation(image, 0.8) {
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = storageRef.putData(imageData, metadata: metadata, completion: { (metadata, error) in
            storageRef.downloadURL { url, error in
                if let error = error {
                    completionBlock(nil, error.localizedDescription)
                } else {
                    completionBlock(url?.absoluteURL, nil)
                }
            }
        })
        uploadTask.observe(.progress, handler: { (snapshot) in
            guard let progress = snapshot.progress else {
                return
            }
            
            let percentage = (Double(progress.completedUnitCount) / Double(progress.totalUnitCount)) * 100
            progressBlock(percentage)
        })
    } else {
        completionBlock(nil, "Image couldn't be converted to Data.")
    }
}
