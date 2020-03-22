//
//  ListActionViewController.swift
//  VariousPattern
//
//  Created by Kota Saito on 2020/03/22.
//  Copyright © 2020 ktst79. All rights reserved.
//

import UIKit

class ListActionViewController: UIViewController {
    
    static var count = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()

        // Do any additional setup after loading the view.
    }
    
    func initView() {
        let settings = UserDefaults.standard
        settings.register(defaults: ["requestUrl": "http://www.google.com"])
    }
    
    func getUrl() -> String? {
        let settings = UserDefaults.standard
        let urlStr = settings.string( forKey: "requestUrl")
        
        return urlStr
    }
    
    @IBAction func handleCustomAttribute(_ sender: Any) {
        NewRelic.setAttribute("customAttrName", value: "customAttrValue")
        updateLabel(message: "Custom attribute has been set")
    }
    
    @IBAction func handleCustomEvent(_ sender: Any) {
        ListActionViewController.count = ListActionViewController.count + 1
        NewRelic.recordCustomEvent("MobileCustom", name: "Custom Mobile Event", attributes: ["attr1": "value1", "attr2": "value2", "count": ListActionViewController.count])
        updateLabel(message: "Custom event (MobileCustom) has been created")
    }
    
    @IBAction func handleLongInteraction(_ sender: Any) {
        updateLabel(message: "Long interaction started")
        Thread.sleep(forTimeInterval: 5)
        updateLabel(message: "Long interaction is done")
    }
    
    @IBAction func handleServerRequest(_ sender: Any) {
        updateLabel(message: "Handle server request")
        let urlStr = getUrl()
        let weburl = URL(string: urlStr!)
        if weburl != nil {
            let request = URLRequest(url: weburl!)
            let session = URLSession.shared
            session.dataTask(with: request) { (data, response, error) in
                DispatchQueue.main.async {
                    if error == nil {
                        self.updateLabel(message: "Got response successfully")
                    } else {
                        self.updateLabel(message: "Http request failed")
                    }
                }
            }.resume()
        }
    }
    
    @IBAction func hanldeSettings(_ sender: Any) {
        performSegue(withIdentifier: "goListSetting", sender: nil)
    }
    
    @IBAction func handleCrash(_ sender: Any) {
        updateLabel(message: "I'm crashing in two seconds...")
        Thread.sleep(forTimeInterval: 2)
        NewRelic.crashNow("I'm about to be crashed by program")
    }
    
    
    @IBAction func handleRaiseError(_ sender: Any) throws {
        updateLabel(message: "Error raised")
        //do {
            try throwError()
        //} catch {
            //NewRelic.error
            //NewRelic.
        //}
    }
    
    func throwError() throws {
        throw NSError(domain: "This is intended error", code: -1, userInfo: nil)
    }
    
    func updateLabel(message: String) {
        messageLabel.text = message
    }
    
    @IBOutlet weak var messageLabel: UILabel!
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
