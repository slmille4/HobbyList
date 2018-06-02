//
//  DetailViewController.swift
//  HobbyList
//
//  Created by Steve on 5/30/18.
//  Copyright © 2018 Steve. All rights reserved.
//

import UIKit
import Firebase

final class ProfileViewController: UITableViewController, UITextFieldDelegate {
    var profileReference: DatabaseReference?
    var profileDict:[String:Any]?
    var hobbies:[String] = [""]
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        profileReference?.observe(.value, with: { snapshot in
            self.profileDict = snapshot.value as? [String:Any]
            if let hobbies = self.profileDict?["hobbies"] as? [String] {
                self.hobbies = hobbies
            }
            if !self.isEditing {
                self.tableView.reloadData()
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 {
            return hobbies.count
        } else {
            return 1
        }
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
            cell.textField.text = "\(self.profileDict?["age"] ?? "")"
        case 3:
            cell.textField.text = self.hobbies[indexPath.row]
        //cell.textField.keyboardType = .numbersAndPunctuation
        default: break
        }
        cell.textField.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell = editCellForRowAt(indexPath)
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
            profileReference?.child("age").setValue(Int(cell.textField.text!))
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
                [IndexPath(row:ct-1, section:1)],
                          with:.automatic)
            tv.reloadRows(at:
                [IndexPath(row:ct-2, section:1)],
                          with:.automatic)
            tv.endUpdates()
            // crucial that this next bit be *outside* the updates block
            let cell = self.tableView.cellForRow(at:
                IndexPath(row:ct-1, section:1))
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            self.navigationController?.pushScreen(screen: genderViewController()){ (gender) in
                self.profileReference?.child("gender").setValue(gender){ _,_ in
                    self.profileDict!["gender"] = gender
                    self.tableView.reloadRows(at: [IndexPath(row:0, section:1)], with:.automatic)
                }
            }
        }
    }
    
    @IBAction func deleteProfile(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        actionSheet.addAction(UIAlertAction(title: "Delete Profile", style: .destructive, handler: { _ in
            self.profileReference?.removeValue()
            if let navController = self.splitViewController?.viewControllers[0] as? UINavigationController {
                navController.popViewController(animated: true)
            }
        }))
        self.present(actionSheet, animated: true)
    }
}
