//
//  DetailViewController.swift
//  HobbyList
//
//  Created by Steve on 5/30/18.
//  Copyright © 2018 Steve. All rights reserved.
//

import UIKit
import Firebase

extension Dictionary where Value: Any {
    func isEqual(to otherDict: [Key: Any]) -> Bool {
        guard self.count == otherDict.count else { return false }
        for (k1,v1) in self {
            guard let v2 = otherDict[k1] else { return false }
            switch (v1, v2) {
            case (let v1 as [String], let v2 as [String]) : if !(v1==v2) { return false }
            case (let v1 as Int, let v2 as Int) : if !(v1==v2) { return false }
            case (let v1 as String, let v2 as String): if !(v1==v2) { return false }
            default: return false
            }
        }
        return true
    }
}

final class ProfileViewController: UITableViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var deleteProfileView: UIView!
    var profileReference: DatabaseReference?
    var profileDict:[String:Any]? = nil
//    var hobbies:[String] = [""]
//    var needsReload = true
    override func viewDidLoad() {
        super.viewDidLoad()
        self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.width/2
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapProfileImage))
        profileImageView.addGestureRecognizer(tapGesture)
        observeProfile()
    }
    
//    override func viewDidAppear(_ animated: Bool) {
    func observeProfile() {
        guard let profileReference = profileReference else {
            self.deleteProfileView.isHidden = true
            return
        }
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        profileReference.observe(.value, with: { snapshot in
            let oldProfileDict = self.profileDict
            guard let newProfileDict = snapshot.value as? [String:Any] else {
                self.profileDict = nil
                self.tableView.reloadData()
                self.popViewController()
                return
            }
            
            self.profileDict = newProfileDict
            if let newImagePath = newProfileDict["imagePath"] as? String{
                let oldImagePath = oldProfileDict?["imagePath"] as? String
                if oldImagePath != newImagePath {
                    downloadImage(urlString: newImagePath) { image in
                        self.profileImageView.image = image
                    }
                }
            }
            if oldProfileDict == nil || !oldProfileDict!.isEqual(to: newProfileDict) {
                self.tableView.reloadData()
            }
            
        })
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            profileImageView.layer.borderWidth = 1
            profileImageView.layer.borderColor = UIColor.green.cgColor
            profileImageView.isUserInteractionEnabled = true
        } else {
            profileImageView.layer.borderWidth = 0
            profileImageView.isUserInteractionEnabled = false
        }
    }
    
    //override func viewWillDisappear(_ animated: Bool) {
    deinit {
        profileReference?.removeAllObservers()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == 3 {
            let ct = self.tableView(tableView, numberOfRowsInSection:indexPath.section)
            if ct-1 == indexPath.row {
                return .insert
            }
            return .delete;
        }
        return .none
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return (section == 3 ? " " : nil)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        switch section {
        case 0: return "Name"
        case 1: return "Gender"
        case 2: return "Age"
        case 3: return "Hobbies"
        default: return " "
        }
    }
    
    var hobbies:[String] {
        get {
            return profileDict?["hobbies"] as? [String] ?? []
        }
        set {
            profileDict?["hobbies"] = newValue
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 {
            return hobbies.count
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 1 { return indexPath }//Only select gender section
        else { return nil }
    }
    
    func editCellForRowAt(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditCell", for: indexPath) as! EditCell
    
        switch indexPath.section {
        case 0:
            cell.textField.text = self.profileDict?["name"] as? String ?? ""
        case 1:
            cell.editingAccessoryType = .disclosureIndicator
            cell.textField.text = self.profileDict?["gender"] as? String ?? ""
            cell.textField.isUserInteractionEnabled = false
        case 2:
            cell.textField.text = self.profileDict?["age"] as? String ?? ""
            cell.textField.keyboardType = .numberPad
        case 3:
            cell.textField.text = hobbies[indexPath.row]
        //cell.textField.keyboardType = .numbersAndPunctuation
        default: break
        }
        cell.textField.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = editCellForRowAt(indexPath)
        return cell
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // some cell's text field has finished editing; which cell?
        var v : UIView = textField
        repeat { v = v.superview! } while !(v is UITableViewCell)
        // another way to say:
        //        var v : UIView
        //        for v = textField; !(v is UITableViewCell); v = v.superview! {}
        let cell = v as! EditCell
        // update data model to match
        let ip = self.tableView.indexPath(for:cell)!
        if ip.section == 0 {
            profileReference?.child("name").setValue(cell.textField.text!)
        } else if ip.section == 2 {
            profileReference?.child("age").setValue(Int(cell.textField.text!)?.description ?? "")
        } else if ip.section == 3 {
            profileReference?.child("hobbies").child(ip.row.description).setValue(cell.textField.text!)
        }
    }
    
    override func tableView(_ tv: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt ip: IndexPath) {
        tv.endEditing(true) // user can click minus/plus while still editing
        // so we must force saving to the model
        if editingStyle == .insert {
            self.hobbies += [""]
            profileReference?.child("hobbies").setValue(hobbies)
            let ct = hobbies.count
            
            tv.beginUpdates()
            tv.insertRows(at:
                [IndexPath(row:ct-1, section:3)],
                          with:.automatic)
            tv.reloadRows(at:
                [IndexPath(row:ct-2, section:3)],
                          with:.automatic)
            tv.endUpdates()
            // crucial that this next bit be *outside* the updates block
            let cell = self.tableView.cellForRow(at:
                IndexPath(row:ct-1, section:3))
            (cell as! EditCell).textField.becomeFirstResponder()
        }
        if editingStyle == .delete {
            self.hobbies.remove(at:ip.row)
            profileReference?.child("hobbies").setValue(self.hobbies)
            
            tv.beginUpdates()
            tv.deleteRows(at:
                [ip], with:.automatic)
            tv.reloadSections(
                IndexSet(integer:1), with:.automatic)
            tv.endUpdates()
        }
    }
    
    func popViewController() {
        if let navController = self.splitViewController?.viewControllers[0] as? UINavigationController {
            navController.popViewController(animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            self.navigationController?.pushScreen(screen: genderViewController()){ (gender) in
                self.profileReference?.child("gender").setValue(gender){ _,_ in
                    self.profileDict!["gender"] = gender
                    //self.tableView.reloadRows(at: [IndexPath(row:0, section:1)], with:.automatic)
                }
            }
        }
    }
    
    @IBAction func deleteProfile(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        actionSheet.addAction(UIAlertAction(title: "Delete Profile", style: .destructive, handler: { _ in
            self.profileReference?.removeValue()
            self.popViewController()
        }))
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = sender
        }
        self.present(actionSheet, animated: true)
    }
    
    
    
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        print("wat")
//        return true
//    }
    
    @objc func tapProfileImage(_ sender: UITapGestureRecognizer) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let image = selectedImageFromPicker {
            picker.dismiss(animated: true, completion: nil)
            self.profileImageView.image = image
            uploadImage(image, progressBlock: { (percentage) in
                print(percentage)
            }, completionBlock: { [weak self] (fileURL, errorMessage) in
                guard let strongSelf = self, let absoluteString = fileURL?.absoluteString else {
                    return
                }
                print(fileURL ?? "")
                print(errorMessage ?? "")
                
                strongSelf.profileReference?.child("imagePath").setValue(absoluteString)
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled picker")
        dismiss(animated: true, completion: nil)
    }
}
