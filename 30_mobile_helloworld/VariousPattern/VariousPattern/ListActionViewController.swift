//
//  ListActionViewController.swift
//  VariousPattern
//
//  Created by Kota Saito on 2020/03/22.
//  Copyright © 2020 ktst79. All rights reserved.
//

import UIKit

class ListActionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func handleCustomAttribute(_ sender: Any) {
        print("handleCustomAttribute")
    }
    
    @IBAction func handleCustomEvent(_ sender: Any) {
        print("handleCustomEvent")
    }
    
    @IBAction func handleLongInteraction(_ sender: Any) {
        print("handleLongInteraction")
    }
    
    @IBAction func handleServerRequest(_ sender: Any) {
        print("handleServerRequest")
    }
    
    @IBAction func hanldeSettings(_ sender: Any) {
        performSegue(withIdentifier: "goListSetting", sender: nil)
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
