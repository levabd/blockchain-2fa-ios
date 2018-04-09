import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var descriptionView: UIStackView!
    @IBOutlet weak var requestView: UIStackView!
    @IBOutlet weak var requestTitle: UILabel!
    @IBOutlet weak var requestBody: UILabel!
    @IBOutlet weak var verifyRequestButton: UIButton!
    @IBOutlet weak var dismissRequestButton: UIButton!
    @IBOutlet weak var buttonsView: UIStackView!
    
    func showSpinner(){
        let alert = UIAlertController(title: nil, message: "Подождите...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Обновить", style: .plain, target: self, action: #selector(refreshTapped))
        
        showSpinner()
        
        _ = Timer.scheduledTimer(timeInterval: 2.0,
                                 target: self,
                                 selector: #selector(showRequest(timer:)),
                                 userInfo: nil,
                                 repeats: false)
    }
    
    @objc func refreshTapped(_ sender: AnyObject){
        showSpinner()
        
        _ = Timer.scheduledTimer(timeInterval: 2.0,
                                 target: self,
                                 selector: #selector(showRequest(timer:)),
                                 userInfo: nil,
                                 repeats: false)
    }
    
    @objc func showRequest(timer: Timer!){
        
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
