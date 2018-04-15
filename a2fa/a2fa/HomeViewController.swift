import UIKit
import KeychainSwift
import Alamofire

class HomeViewController: UIViewController {
    
    @IBOutlet weak var descriptionView: UIStackView!
    @IBOutlet weak var requestView: UIStackView!
    @IBOutlet weak var requestTitle: UILabel!
    @IBOutlet weak var requestBody: UILabel!
    @IBOutlet weak var verifyRequestButton: UIButton!
    @IBOutlet weak var dismissRequestButton: UIButton!
    @IBOutlet weak var buttonsView: UIStackView!
    
    var phone:String = ""
    var token:String = ""
    
    func showSpinner(){
        let alert = UIAlertController(title: nil, message: "Подождите...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
    func showRequestError(msg: String){
        let alert = UIAlertController(title: "Ошибка", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in
            NSLog("The \"OK\" alert occured.")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func refreshRequest() {
        let timestamp = Int(NSDate().timeIntervalSince1970)
        let key = CryptoUtils.calculateApiKey(
            path: "/v1/api/users/code",
            body: "client_timestamp:\(timestamp);phone_number:\(phone);push_token:\(token);",
            phoneNumber: phone
        )
        let requestHeaders: HTTPHeaders = [
            "accept" : "application/json",
            "api-key": key
        ]
        
        let params: [String: Any] = [
            "phone_number": phone,
            "push_token": token,
            "client_timestamp": timestamp
        ]
        
        Alamofire.request(
            "\(Constants.baseApiURL)/v1/api/users/code",
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
                } else if statusCode == 422 {
                    errorMsg = "Нет новых запросов на авторизацию";
                } else if statusCode != 200 {
                    errorMsg = "Не удалось совершить запрос. Проверьте параметры и попробуйте позже.";
                }
                
                if statusCode != 200 {
                    self.dismiss(animated: false, completion: nil)
                    self.showRequestError(msg: errorMsg)
                } else {
                    self.showRequest()
                }
        }
    }
    
    func verifyRequest(reject: Bool) {
        let timestamp = Int(NSDate().timeIntervalSince1970)
        let key = CryptoUtils.calculateApiKey(
            path: "/v1/api/users/code",
            body: "client_timestamp:\(timestamp);phone_number:\(phone);push_token:\(token);",
            phoneNumber: phone
        )
        let requestHeaders: HTTPHeaders = [
            "accept" : "application/json",
            "Content-Type" : "application/json",
            "api-key": key
        ]
        
        Alamofire.request(
            "\(Constants.baseApiURL)/v1/api/users/verify",
            method: .get,
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
                
                if statusCode == 404 {
                    errorMsg = "Пользователь с таким номером не зарегистрирован в системе";
                } else if statusCode == 422 {
                    errorMsg = "Нет новых запросов на авторизацию";
                } else if statusCode != 200 {
                    errorMsg = "Не удалось совершить запрос. Проверьте параметры и попробуйте позже.";
                }
                
                if statusCode != 200 {
                    self.dismiss(animated: false, completion: nil)
                    self.showRequestError(msg: errorMsg)
                } else {
                    self.showRequest()
                }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let keychain = KeychainSwift()
        phone = keychain.get("2fa-phone")!
        token = keychain.get("2fa-pushToken")!
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Обновить", style: .plain, target: self, action: #selector(refreshTapped))
        
        showSpinner()
        
        refreshRequest()
    }
    
    @objc func refreshTapped(_ sender: AnyObject){
        showSpinner()
        
        refreshRequest()
    }
    
    @objc func showRequest(){
        
        requestTitle.text = "Казахтелеком запрашивает разрешение"
        requestBody.text = "Сервис «Казахтелеком» запрашивает разрешение на событие «Авторизация»."
        
        descriptionView.isHidden = true
        requestView.isHidden = false
        requestBody.isHidden = false
        buttonsView.isHidden = false
        
        dismiss(animated: false, completion: nil)
    }
    
    @objc func verifyRequest(timer: Timer!){
        
        requestTitle.text = "Запрос успешно верифицирован"
        requestBody.isHidden = true
        buttonsView.isHidden = true
        
        dismiss(animated: false, completion: nil)
    }
    
    @objc func rejectRequest(timer: Timer!){
        
        requestTitle.text = "Запрос успешно отклонен"
        requestBody.isHidden = true
        buttonsView.isHidden = true
        
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func verifyTouch(_ sender: UIButton) {
        showSpinner()
        
        _ = Timer.scheduledTimer(timeInterval: 2.0,
                                 target: self,
                                 selector: #selector(verifyRequest(timer:)),
                                 userInfo: nil,
                                 repeats: false)
    }
    
    @IBAction func rejectTouch(_ sender: UIButton) {
        showSpinner()
        
        _ = Timer.scheduledTimer(timeInterval: 2.0,
                                 target: self,
                                 selector: #selector(rejectRequest(timer:)),
                                 userInfo: nil,
                                 repeats: false)
    }
}
