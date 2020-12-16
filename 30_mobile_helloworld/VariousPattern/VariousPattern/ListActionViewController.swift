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
        //let timer = NRTimer();
        //NewRelic.startTracingMethod(#selector(ListActionViewController.handleCustomAttribute), object: self, timer: timer, category: NRTraceTypeNone)
        let iid = NewRelic.startInteraction(withName: "HandleCustomAttributeInteraction")
        NewRelic.setAttribute("customAttrName", value: "customAttrValue")
        NewRelic.recordBreadcrumb("Custom Attribute Clicked")
        updateLabel(message: "Custom attribute has been set")
        //NewRelic.endTracingMethod(with: timer)
        NewRelic.stopCurrentInteraction(iid)
    }
    
    @IBAction func handleCustomEvent(_ sender: Any) {
        let iid = NewRelic.startInteraction(withName: "HandleCustomEventInteraction")
        ListActionViewController.count = ListActionViewController.count + 1
        NewRelic.recordCustomEvent("MobileCustom", name: "Custom Mobile Event", attributes: ["attr1": "value1", "attr2": "value2", "count": ListActionViewController.count])
        NewRelic.recordBreadcrumb("Custom Event Clicked")
        updateLabel(message: "Custom event (MobileCustom) has been created")
        NewRelic.stopCurrentInteraction(iid)
    }
    
    @IBAction func handleLongInteraction(_ sender: Any) {
        let iid = NewRelic.startInteraction(withName: "HandleLongInteraction")
        updateLabel(message: "Long interaction started")
        NewRelic.recordBreadcrumb("Long Interaction Clicked")
        Thread.sleep(forTimeInterval: 5)
        updateLabel(message: "Long interaction is done")
        NewRelic.stopCurrentInteraction(iid)
    }
    
    @IBAction func handleServerRequest(_ sender: Any) {
        let iid = NewRelic.startInteraction(withName: "HandleServerRequestInteraction")
        updateLabel(message: "Handle server request")
        NewRelic.recordBreadcrumb("Server Request Clicked")
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
        NewRelic.stopCurrentInteraction(iid)
    }
    
    @IBAction func hanldeSettings(_ sender: Any) {
        performSegue(withIdentifier: "goListSetting", sender: nil)
    }
    
    @IBAction func handleCrash(_ sender: Any) {
        let iid = NewRelic.startInteraction(withName: "HandleCrashtInteraction")
        updateLabel(message: "I'm crashing in two seconds...")
        NewRelic.recordBreadcrumb("Crash Clicked")
        Thread.sleep(forTimeInterval: 2)
        NewRelic.crashNow("I'm about to be crashed by program")
        NewRelic.stopCurrentInteraction(iid)
    }
    
    
    @IBAction func handleRaiseError(_ sender: Any) {
        let iid = NewRelic.startInteraction(withName: "HandleRaiseErrorInteraction")
        print("1. -------------------------------")
        updateLabel(message: "Error raised")
        print("2. -------------------------------")
        NewRelic.recordBreadcrumb("Raise Error Clicked")
        print("3. -------------------------------")
        Thread.sleep(forTimeInterval: 5)
        print("4. -------------------------------")
        do {
            print("5. -------------------------------")
            try throwError()
        } catch {
            print("6. -------------------------------")
            //NewRelic.recordError(error, attributes: [ "int" : 1, "Test Group" : "A | B" ])
            print("7. -------------------------------")
            //NewRelic.recordError()
        }
        NewRelic.stopCurrentInteraction(iid)
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
