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
import Alamofire

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
        phoneInput.text = keychain.get("2fa-phone") ?? ""
        
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
    
    func showRequestError(msg: String){
        let alert = UIAlertController(title: "Ошибка", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in
            NSLog("The \"OK\" alert occured.")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func register(tkn: String?) {
        let keychain = KeychainSwift()
        keychain.delete("2fa-pushToken")
        keychain.set(tkn ?? "", forKey: "2fa-pushToken")
        keychain.delete("2fa-phone")
        keychain.set(phone, forKey: "2fa-phone")
        keychain.delete("2fa-pin")
        keychain.set(pin, forKey: "2fa-pin")
        
        dismiss(animated: false, completion: nil)
        
        let info = UIAlertController(title: "Операция успешна", message: "Не забывайте свой код допуска", preferredStyle: .alert)
        info.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: go2HomeView))
        present(info, animated: true, completion: nil)
    }
    
    @objc func showSMS(reshow: Bool) {
        step = 2
        
        PINInput.isHidden = true
        PINLabel.isHidden = true
        
        SMSInput.isHidden = false
        SMSLabel.isHidden = false
        
        if !reshow {
            _ = Timer.scheduledTimer(timeInterval: 60.0,
                                 target: self,
                                 selector: #selector(showResend(timer:)),
                                 userInfo: nil,
                                 repeats: false)
        }
        
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func resendTouch(_ sender: UIButton) {
        phone = phoneInput.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if validateInputs() {
            
            showSpinner()
            
            let timestamp = Int(NSDate().timeIntervalSince1970)
            let key = CryptoUtils.calculateApiKey(
                path: "/v1/api/users/verify-number",
                body: "client_timestamp:\(timestamp);phone_number:\(phone);",
                phoneNumber: phone
            )
            let requestHeaders: HTTPHeaders = [
                "accept" : "application/json",
                "api-key": key
            ]
            
            let params: [String: Any] = [
                "phone_number": phone,
                "client_timestamp": timestamp
            ]
                        
            Alamofire.request(
                "\(Constants.baseApiURL)/v1/api/users/verify-number",
                method: .get,
                parameters: params,
                encoding: URLEncoding.default,
                headers: requestHeaders)
                .responseJSON { responseJSON in
                    var errorMsg = ""
                    guard let statusCode = responseJSON.response?.statusCode else {
                        errorMsg = "Проблемы с сетевым соединением. Попробуйте чуть позже."
                        self.dismiss(animated: false, completion: nil)
                        self.showRequestError(msg: errorMsg)
                        return
                    }
                    if statusCode == 404 {
                        errorMsg = "Пользователь с таким номером не зарегистрирован в системе";
                    } else if statusCode != 200 {
                        errorMsg = "Не удалось совершить запрос. Проверьте параметры и попробуйте позже.";
                    }
                    
                    if statusCode != 200 {
                        self.dismiss(animated: false, completion: nil)
                        self.showRequestError(msg: errorMsg)
                    } else {
                        self.showSMS(reshow: true)
                    }
            }
            
        }
    }
    
    @IBAction func nextButtonClick(_ sender: UIButton) {
        if (step == 1) {
            phone = phoneInput.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            pin = PINInput.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if validateInputs() {
                
                showSpinner()
                
                let timestamp = Int(NSDate().timeIntervalSince1970)
                let key = CryptoUtils.calculateApiKey(
                    path: "/v1/api/users/verify-number",
                    body: "client_timestamp:\(timestamp);phone_number:\(phone);",
                    phoneNumber: phone
                )
                let requestHeaders: HTTPHeaders = [
                    "accept" : "application/json",
                    "api-key": key
                ]
                
                let params: [String: Any] = [
                    "phone_number": phone,
                    "client_timestamp": timestamp
                ]
                
                /*Alamofire.request("https://httpbin.org/get").debugLog().responseJSON { response in
                    print("Request: \(String(describing: response.request))")   // original url request
                    print("Response: \(String(describing: response.response))") // http url response
                    print("Result: \(response.result)")                         // response serialization result
                    
                    guard let statusCode = response.response?.statusCode else {
                        return
                    }
                    
                    if let json = response.result.value {
                        print("JSON: \(json)") // serialized json response
                    }
                    
                    if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                        print("Data: \(utf8Text)") // original server data as UTF8 string
                    }
                }*/
                
                Alamofire.request(
                    "\(Constants.baseApiURL)/v1/api/users/verify-number",
                    method: .get,
                    parameters: params,
                    encoding: URLEncoding.default,
                    headers: requestHeaders)
                    .responseJSON { responseJSON in
                        var errorMsg = ""
                        guard let statusCode = responseJSON.response?.statusCode else {
                            errorMsg = "Проблемы с сетевым соединением. Попробуйте чуть позже."
                            self.dismiss(animated: false, completion: nil)
                            self.showRequestError(msg: errorMsg)
                            return
                        }
                        if statusCode == 404 {
                            errorMsg = "Пользователь с таким номером не зарегистрирован в системе";
                        } else if statusCode != 200 {
                            errorMsg = "Не удалось совершить запрос. Проверьте параметры и попробуйте позже.";
                        }
                        
                        if statusCode != 200 {
                            self.dismiss(animated: false, completion: nil)
                            self.showRequestError(msg: errorMsg)
                        } else {
                            self.showSMS(reshow: true)
                        }
                    }
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
                
                let key = CryptoUtils.calculateApiKey(
                    path: "/v1/api/users/verify-number",
                    body: "code:\(sms);phone_number:\(phone);push_token:\(token ?? "");",
                    phoneNumber: phone
                )
                let requestHeaders: HTTPHeaders = [
                    "accept" : "application/json",
                    "Content-Type" : "application/json",
                    "api-key": key
                ]
                let params: [String: Any] = [
                    "phone_number": phone,
                    "push_token": token ?? "",
                    "code": Int(sms) ?? 0
                ]
                
                Alamofire.request(
                    "\(Constants.baseApiURL)/v1/api/users/verify-number",
                    method: .post,
                    parameters: params,
                    encoding: JSONEncoding.default,
                    headers: requestHeaders)
                    .responseJSON { responseJSON in
                        var errorMsg = ""
                        guard let statusCode = responseJSON.response?.statusCode else {
                            errorMsg = "Проблемы с сетевым соединением. Попробуйте чуть позже."
                            self.dismiss(animated: false, completion: nil)
                            self.showRequestError(msg: errorMsg)
                            return
                        }
                        
                        if statusCode == 422 {
                            errorMsg = "Код подтверждения устарел или неверен"
                        } else if statusCode == 404 {
                            errorMsg = "Пользователь с таким номером не зарегистрирован в системе"
                        } else if statusCode != 200 {
                            errorMsg = "Не удалось совершить запрос. Проверьте параметры и попробуйте позже."
                        }
                        
                        if statusCode != 200 {
                            self.dismiss(animated: false, completion: nil)
                            self.showRequestError(msg: errorMsg)
                        } else {
                            self.register(tkn: token)
                        }
                }
                
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension Request {
    public func debugLog() -> Self {
        #if DEBUG
        debugPrint("=======================================")
        debugPrint(self)
        debugPrint("=======================================")
        #endif
        return self
    }
}
