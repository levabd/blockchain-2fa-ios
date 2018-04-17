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
    var postCode:PostCodeDTO?
    
    func showSpinner(){
        let alert = UIAlertController(title: nil, message: "Подождите...", preferredStyle: .alert)
        
        print("Wait Alert showed")
        
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
    
    @objc func refreshRequest(timer: Timer!) {
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
            .responseObject { (response: DataResponse<PostCodeDTO>) in
            // .responseJSON { responseJSON in
                var errorMsg = ""
                guard let statusCode = response.response?.statusCode else {
                    errorMsg = "Проблемы с сетевым соединением. Попробуйте чуть позже."
                    self.showRequest(error: true, errorMessage: errorMsg)
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
                    self.showRequest(error: true, errorMessage: errorMsg)
                } else {
                    if let _postCode = response.result.value {
                        self.postCode = _postCode
                        self.showRequest(error: false, errorMessage: "")
                        print("Post Code: \(String(describing: self.postCode?.code))") // serialized json response
                    } else {
                        self.showRequest(error: true, errorMessage: "Не удалось совершить запрос. Проверьте параметры и попробуйте позже.")
                    }
                }
        }
    }
    
    func verifyRequest(reject: Bool) {
        let timestamp = Int(NSDate().timeIntervalSince1970)
        let satus = reject ? "REJECT" : "VERIFY"
        let key = CryptoUtils.calculateApiKey(
            path: "/v1/api/users/verify",
            body: "service:\(postCode?.service ?? "");cert:\(postCode?.cert ?? "");status:\(satus);code:\(postCode?.code ?? 0);client_timestamp:\(timestamp);embeded:\(postCode?.embeded ?? false);event:\(postCode?.event ?? "");phone_number:\(phone);",
            phoneNumber: phone
        )
        let requestHeaders: HTTPHeaders = [
            "accept" : "application/json",
            "Content-Type" : "application/json",
            "api-key": key
        ]
        
        let params: [String: Any] = [
            "phone_number": phone,
            "event": postCode?.event ?? "",
            "service": postCode?.service ?? "",
            "embeded": postCode?.embeded ?? false,
            "cert": postCode?.cert ?? "",
            "code": postCode?.code ?? 0,
            "status": satus,
            "client_timestamp": timestamp
        ]
        
        Alamofire.request(
            "\(Constants.baseApiURL)/v1/api/users/verify",
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
                
                if statusCode == 440 {
                    errorMsg = "Запрос просрочен. Попробуйте авторизоваться снова.";
                } else if statusCode == 400 {
                    errorMsg = "Не удалось подтвердить запрос. Попробуйте позже.";
                } else if statusCode != 200 {
                    errorMsg = "Не удалось совершить запрос. Проверьте параметры и попробуйте позже.";
                }
                
                if statusCode != 200 {
                    self.dismiss(animated: false, completion: nil)
                    self.showRequestError(msg: errorMsg)
                } else {
                    self.verifyRequest(rejected: reject)
                }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let keychain = KeychainSwift()
        phone = keychain.get("2fa-phone") ?? ""
        token = keychain.get("2fa-pushToken") ?? ""
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Обновить", style: .plain, target: self, action: #selector(refreshTapped))
        
        showSpinner()
        
        // Timer for the spinner to has time to initialize
        _ = Timer.scheduledTimer(timeInterval: 0.3,
                                 target: self,
                                 selector: #selector(refreshRequest(timer:)),
                                 userInfo: nil,
                                 repeats: false)
    }
    
    @objc func refreshTapped(_ sender: AnyObject){
        showSpinner()
        
        refreshRequest(timer: nil)
    }
    
    @objc func showRequest(error: Bool, errorMessage: String){
        
        if (error){
            requestTitle.text = errorMessage
            requestBody.text = ""
            buttonsView.isHidden = true
        } else {
            requestTitle.text = "\(postCode?.Service() ?? "Неизвестно") запрашивает разрешение"
            requestBody.text = "Сервис «\(postCode?.Service() ?? "Неизвестно")» запрашивает разрешение на событие «\(postCode?.Event() ?? "Неопределено")»."
            buttonsView.isHidden = false
        }
        
        descriptionView.isHidden = true
        requestView.isHidden = false
        requestBody.isHidden = false
        
        print("Wait Alert try closing")
        dismiss(animated: false, completion: nil)
    }
    
    @objc func verifyRequest(rejected: Bool){
        
        requestTitle.text = rejected ? "Запрос успешно отклонен" : "Запрос успешно верифицирован"
        requestBody.isHidden = true
        buttonsView.isHidden = true
        
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func verifyTouch(_ sender: UIButton) {
        showSpinner()
        
        verifyRequest(reject: false)
    }
    
    @IBAction func rejectTouch(_ sender: UIButton) {
        showSpinner()
        
        verifyRequest(reject: true)
    }
}

enum BackendError: Error {
    case network(error: Error) // Capture any underlying Error from the URLSession API
    case dataSerialization(error: Error)
    case jsonSerialization(error: Error)
    case xmlSerialization(error: Error)
    case objectSerialization(reason: String)
}

protocol ResponseObjectSerializable {
    init?(response: HTTPURLResponse, representation: Any)
}

extension DataRequest {
    func responseObject<T: ResponseObjectSerializable>(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (DataResponse<T>) -> Void)
        -> Self
    {
        let responseSerializer = DataResponseSerializer<T> { request, response, data, error in
            guard error == nil else { return .failure(BackendError.network(error: error!)) }
            
            let jsonResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonResponseSerializer.serializeResponse(request, response, data, nil)
            
            guard case let .success(jsonObject) = result else {
                return .failure(BackendError.jsonSerialization(error: result.error!))
            }
            
            guard let response = response, let responseObject = T(response: response, representation: jsonObject) else {
                return .failure(BackendError.objectSerialization(reason: "JSON could not be serialized: \(jsonObject)"))
            }
            
            return .success(responseObject)
        }
        
        return response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}

struct PostCodeDTO: ResponseObjectSerializable, CustomStringConvertible {

    
    let services: [String: String] = ["kaztel": "Казахтелеком"]
    let events: [String: String] = ["login": "Авторизация"]
    
    let cert: String
    let code: Int
    let embeded: Bool
    let event: String
    let service: String
    
    var description: String {
        return "PostCode: { cert: \(cert), code: \(code) , embeded: \(embeded) , event: \(event) , service: \(service) }"
    }
    
    func Service() -> String {
        if let _ = services[service] {
            return services[service]!
        } else {
            return ""
        }
    }
    
    func Event() -> String {
        if let _ = events[event] {
            return events[event]!
        } else {
            return ""
        }
    }
    
    init?(response: HTTPURLResponse, representation: Any) {
        guard
            let representation = representation as? [String: Any],
            let cert = representation["cert"] as? String,
            let code = representation["code"] as? Int,
            let embeded = representation["embeded"] as? Bool,
            let event = representation["event"] as? String,
            let service = representation["service"] as? String
        else { return nil }
        
        self.cert = cert
        self.code = code
        self.embeded = embeded
        self.event = event
        self.service = service
    }
}
