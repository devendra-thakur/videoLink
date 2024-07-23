//
//  ViewController.swift
//  Sensonic2Testing
//
//  Created by Devendra Thakur on 15/05/24.
//

import UIKit
import Sensonic
import DVCUtility
import Office
import Combine
class ViewController: UIViewController {
    let viewModel = OfficeViewModel()
    var cancellables = Set<AnyCancellable>()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if Sensonic.shared.userInfo.isUserSignedIn {
            if let requestId = SensonicUser().requestUserId {
                viewModel.getEmployeeDetailById(employeeId: requestId)
                viewModel.$employeeDetail.sink { data in
                    DVLogger.log(message: "test:\(data)", event: .debug)
                }.store(in: &self.cancellables)
            }
        }
    }
}

