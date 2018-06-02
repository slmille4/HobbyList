//
//  GenderViewController.swift
//  HobbyList
//
//  Created by Steve on 6/2/18.
//  Copyright © 2018 Steve. All rights reserved.
//

import UIKit

func genderViewController() -> Screen<(String)> {
    return Screen { callback in
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GenderViewController") as! GenderViewController
        vc.callback = callback
        return vc
    }
}

class GenderViewController: UITableViewController {
    var callback:((String)->())?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        let label = cell.textLabel?.text ?? ""
        callback?(label)
    }
}
