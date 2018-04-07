import UIKit
import SmileLock
import KeychainSwift

class PasswordLoginViewController: UIViewController {

    @IBOutlet weak var passwordStackView: UIStackView!
    @IBOutlet weak var registerStackView: UIStackView!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    
    //MARK: Property
    var passwordContainerView: PasswordContainerView!
    let kPasswordDigit = 4
    var targetVCID: String!
    
    var isRegistration = false
    
    func present(_ id: String) {
        
        let targetVCID = storyboard?.instantiateViewController(withIdentifier: id)
        // in iOS 10, the crossDissolve transtion is wired
        // loginVC?.modalTransitionStyle = .crossDissolve
        targetVCID?.modalPresentationStyle = .overCurrentContext
        navigationController!.pushViewController(targetVCID!, animated: true)
        // present(loginVCID!, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let keychain = KeychainSwift()
        let pin = keychain.get("2fa-pin")
        
        if (pin != nil){
            // Hide Register
            registerStackView.alpha = 0.0
            registerStackView.isUserInteractionEnabled = false
            registerStackView.isHidden = true
            
            //create PasswordContainerView
            passwordContainerView = PasswordContainerView.create(in: passwordStackView, digit: kPasswordDigit)
            passwordContainerView.delegate = self
            passwordContainerView.deleteButtonLocalizedTitle = "smilelock_delete"
            
            //customize password UI
            passwordContainerView.tintColor = UIColor.color(.textColor)
            passwordContainerView.highlightedColor = UIColor.color(.blue)
            
            isRegistration = false
        } else {
            // Hide Password
            passwordStackView.alpha = 0.0
            passwordStackView.isUserInteractionEnabled = false
            passwordStackView.isHidden = true
            
            restoreButton.alpha = 0.0
            restoreButton.isUserInteractionEnabled = false
            restoreButton.isHidden = true
            
            isRegistration = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let registrationVC: RegistrationViewController = segue.destination as! RegistrationViewController
        
        registrationVC.isRegister = isRegistration
    }
}

extension PasswordLoginViewController: PasswordInputCompleteProtocol {
    func passwordInputComplete(_ passwordContainerView: PasswordContainerView, input: String) {
        if validation(input) {
            validationSuccess()
        } else {
            validationFail()
        }
    }
    
    func touchAuthenticationComplete(_ passwordContainerView: PasswordContainerView, success: Bool, error: Error?) {
        if success {
            print("*️⃣ Подтвержден отпечаток!")
            self.validationSuccess()
        } else {
            passwordContainerView.clearInput()
        }
    }
}

private extension PasswordLoginViewController {
    
    func validation(_ input: String) -> Bool {
        let keychain = KeychainSwift()
        return input == keychain.get("2fa-pin")
    }
    
    func validationSuccess() {
        print("*️⃣ Подтверждено вход!")
        present("HomeViewController")
        // dismiss(animated: true, completion: nil)
    }
    
    func validationFail() {
        print("*️⃣ Отклонено!")
        passwordContainerView.wrongPassword()
    }
}
