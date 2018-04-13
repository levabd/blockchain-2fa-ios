//
//  ViewController.swift
//  a2fa
//
//  Created by Allatrack on 3/21/18.
//  Copyright © 2018 Allatrack. All rights reserved.
//

import UIKit
import KeychainSwift
import Firebase

class RegistrationViewController: UIViewController {
    
    @IBOutlet weak var baseNavigation: UINavigationItem!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var phoneInput: UITextField!
    @IBOutlet weak var PINInput: UITextField!
    @IBOutlet weak var PINLabel: UILabel!
    @IBOutlet weak var SMSInput: UITextField!
    @IBOutlet weak var SMSLabel: UILabel!
    @IBOutlet weak var SMSNotRespondingLabel: UILabel!
    @IBOutlet weak var SMSNotRespondingButton: UIButton!
    
    var step:Int = 1
    var isRegister:Bool = false
    
    var phone:String = ""
    var pin:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        baseNavigation.title = isRegister ? "Зарегистрировать" : "Восстановить код"
        PINInput.placeholder = isRegister ? "PIN код" : "Новый PIN код"
        
        let keychain = KeychainSwift()
        phoneInput.text = keychain.get("2fa-phone")
        
        SMSInput.isHidden = true
        SMSLabel.isHidden = true
        SMSNotRespondingLabel.isHidden = true
        SMSNotRespondingButton.isHidden = true
    }
    
    func showSpinner(){
        let alert = UIAlertController(title: nil, message: "Подождите...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
    func validateInputs() -> Bool{
        if phone.count < 1 {
            
            let alert = UIAlertController(title: "Некорректные данные", message: "Телефон обязателен для заполнения.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in
                NSLog("The \"OK\" alert occured.")
            }))
            present(alert, animated: true, completion: nil)
            
            return false
            
        } else if (!phone.isPhoneNumber) {
            
            let alert = UIAlertController(title: "Некорректные данные", message: "Формат телефона не корректньй.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in
                NSLog("The \"OK\" alert occured.")
            }))
            present(alert, animated: true, completion: nil)
            
            return false
            
        } else if pin.count < 1 {
            
            let alert = UIAlertController(title: "Некорректные данные", message: "Код допуска обязателен для заполнения.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in
                NSLog("The \"OK\" alert occured.")
            }))
            present(alert, animated: true, completion: nil)
            
            return false
            
        } else if ((pin.count != 4) || (!pin.isNumber)) {
            
            let alert = UIAlertController(title: "Некорректные данные", message: "PIN-код должен состоять из 4-х цифр.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in
                NSLog("The \"OK\" alert occured.")
            }))
            present(alert, animated: true, completion: nil)
            
            return false
        } else {
            
            return true
            
        }
    }
    
    @objc func showResend(timer: Timer!) {
        SMSNotRespondingLabel.isHidden = false
        SMSNotRespondingButton.isHidden = false
    }
    
    func go2HomeView(alert: UIAlertAction!) {
        let targetVCID = storyboard?.instantiateViewController(withIdentifier: "HomeViewController")
        // in iOS 10, the crossDissolve transtion is wired
        // loginVC?.modalTransitionStyle = .crossDissolve
        targetVCID?.modalPresentationStyle = .overCurrentContext
        navigationController!.pushViewController(targetVCID!, animated: true)
    }
    
    @objc func register(timer: Timer!) {
        dismiss(animated: false, completion: nil)
        
        let info = UIAlertController(title: "Операция успешна", message: "Не забывайте свой код допуска", preferredStyle: .alert)
        info.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: go2HomeView))
        present(info, animated: true, completion: nil)
    }
    
    @objc func showSMS(timer: Timer!) {
        let info = timer.userInfo as Any
        print(info)
        
        step = 2
        
        PINInput.isHidden = true
        PINLabel.isHidden = true
        
        SMSInput.isHidden = false
        SMSLabel.isHidden = false
        
        _ = Timer.scheduledTimer(timeInterval: 60.0,
                                 target: self,
                                 selector: #selector(showResend(timer:)),
                                 userInfo: nil,
                                 repeats: false)
        
        dismiss(animated: false, completion: nil)
    }
    
    @objc func reshowSMS(timer: Timer!) {
        let info = timer.userInfo as Any
        print(info)
        
        step = 2
        
        PINInput.isHidden = true
        PINLabel.isHidden = true
        
        SMSInput.isHidden = false
        SMSLabel.isHidden = false
        
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func resendTouch(_ sender: UIButton) {
        phone = phoneInput.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if validateInputs() {
            
            showSpinner()
            
            _ = Timer.scheduledTimer(timeInterval: 2.0,
                                     target: self,
                                     selector: #selector(reshowSMS(timer:)),
                                     userInfo: nil,
                                     repeats: false)
            
        }
    }
    
    @IBAction func nextButtonClick(_ sender: UIButton) {
        if (step == 1) {
            phone = phoneInput.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            pin = PINInput.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if validateInputs() {
                
                showSpinner()
                
                _ = Timer.scheduledTimer(timeInterval: 2.0,
                                         target: self,
                                         selector: #selector(showSMS(timer:)),
                                         userInfo: [ "foo" : "bar" ],
                                         repeats: false)
                
            }
        } else if (step == 2) {
            let token = Messaging.messaging().fcmToken
            print("FCM token: \(token ?? "")")
            phone = phoneInput.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let sms = SMSInput.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if sms.count < 1 {
                
                let alert = UIAlertController(title: "Некорректные данные", message: "SMS обязателен для регистрации.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in
                    NSLog("The \"OK\" alert occured.")
                }))
                present(alert, animated: true, completion: nil)
                
            } else if validateInputs() {
                
                showSpinner()
                
                let keychain = KeychainSwift()
                keychain.delete("2fa-phone")
                keychain.set(phone, forKey: "2fa-phone")
                keychain.delete("2fa-pin")
                keychain.set(pin, forKey: "2fa-pin")
                
                _ = Timer.scheduledTimer(timeInterval: 1.0,
                                         target: self,
                                         selector: #selector(register(timer:)),
                                         userInfo: nil,
                                         repeats: false)
                
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

