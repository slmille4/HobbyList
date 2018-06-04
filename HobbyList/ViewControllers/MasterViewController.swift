//
//  MasterViewController.swift
//  HobbyList
//
//  Created by Steve on 5/30/18.
//  Copyright © 2018 Steve. All rights reserved.
//

import UIKit
import Firebase

final class MasterViewController: UITableViewController {
    @IBOutlet var maleButton: UIBarButtonItem!
    @IBOutlet var femaleButton: UIBarButtonItem!
    
    let rootReference: DatabaseReference = Database.database().reference()
    var selectedProfileReference:DatabaseReference?
    var profiles:[Profile]? = nil {
        didSet {
            self.view.backgroundColor = profiles == nil ? UIColor.lightGray : UIColor.white
            self.filteredProfiles = profiles
        }
    }
    var filteredProfiles:[Profile]? = nil {
        didSet {
            self.tableView.reloadData()
        }
    }
    var sortAgeAscending = true
    var sortNameAscending = true

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        var reloaded = false
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        
        rootReference.child("profiles").observe(.value, with: { snapshot in
            if let values = snapshot.value as? [String:Any] {
                self.profiles = values.compactMap(Profile.parse)
                self.profiles?.sort(by: {$0.id < $1.id})
                if self.selectedProfileReference == nil && self.profiles?.isEmpty == false {
                    self.reloadMaybeSegue()
                    reloaded = true
                }
            } else {
                self.profiles = nil
            }
            if !reloaded {
                self.tableView.reloadData()
            }
        })
    }
    
    func reloadMaybeSegue() {
        //just do nothing if this is an iPhone
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            self.tableView.reloadData()
            return
        }
        
        //To select the first item after the table finishes loading
        CATransaction.begin()
        CATransaction.setCompletionBlock({
            let initialIndexPath = IndexPath(row: 0, section: 0)
            self.tableView.selectRow(at: initialIndexPath, animated: true, scrollPosition:UITableViewScrollPosition.none)
            self.tableView(self.tableView, didSelectRowAt: initialIndexPath)
        })
        self.tableView.reloadData()
        CATransaction.commit()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        rootReference.child("profiles").removeAllObservers()
    }
    
    @IBAction func toggleFilterMale(_ sender: UIBarButtonItem) {
        if maleButton.tintColor == nil {
            maleButton.tintColor = UIColor.red
            femaleButton.tintColor = nil
            filteredProfiles = profiles?.filter({$0.gender == "Male"})
        } else {
            maleButton.tintColor = nil
            filteredProfiles = profiles
        }
    }
    
    @IBAction func toggleFilterFemale(_ sender: UIBarButtonItem) {
        if femaleButton.tintColor == nil {
            maleButton.tintColor = nil
            femaleButton.tintColor = UIColor.red
            filteredProfiles = profiles?.filter({$0.gender == "Female"})
        } else {
            femaleButton.tintColor = nil
            filteredProfiles = profiles
        }
    }
    
    @IBAction func insertNewObject(_ sender: Any) {
        rootReference.child("profiles").childByAutoId().setValue(["age": "", "gender": "", "hobbies": [""], "imagePath": "", "name": ""]){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("Data could not be saved: \(error).")
            } else {
                self.selectedProfileReference = ref
                self.performSegue(withIdentifier: "showDetail" , sender: nil)
            }
        }
    }

    @IBAction func sortAction(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        var title = "Sort by Age - " + (sortAgeAscending ? "Descending" : "Ascending")
        actionSheet.addAction(UIAlertAction(title: title, style: .default, handler: sortAge))
        title = "Sort by Name - " + (sortNameAscending ? "Descending" : "Ascending")
        actionSheet.addAction(UIAlertAction(title: title, style: .default, handler: sortName))
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        self.present(actionSheet, animated: true)
    }
    
    func sortAge(_ action:UIAlertAction) {
        sortAgeAscending = !sortAgeAscending
        profiles?.sort(by: {($0.age < $1.age) == sortAgeAscending})
        tableView.reloadData()
    }
    
    func sortName(_ action:UIAlertAction) {
        sortNameAscending = !sortNameAscending
        profiles?.sort(by: {($0.name < $1.name) == sortNameAscending})
        tableView.reloadData()
    }
    
    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let controller = (segue.destination as! UINavigationController).topViewController as! ProfileViewController
            controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            
            controller.profileReference = selectedProfileReference
        }
    }

    // MARK: - Table View
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedIndexPath = tableView.indexPathForSelectedRow else { return }
        let selectedProfile = filteredProfiles![selectedIndexPath.row]
        
        selectedProfileReference = rootReference.child("profiles").child(selectedProfile.id.description)
        self.performSegue(withIdentifier: "showDetail" , sender: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredProfiles?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let profile = filteredProfiles![indexPath.row]
        cell.textLabel?.text = profile.name
        if profile.gender=="Male" {
            cell.backgroundColor = UIColor.init(red: 135/255, green: 206/255, blue: 250/255, alpha: 0.5)
        } else if profile.gender=="Female" {
            cell.backgroundColor = UIColor.init(red: 255/255, green: 182/255, blue: 193/255, alpha: 0.5)
        } else {
            cell.backgroundColor = nil
        }
        return cell
    }
}

