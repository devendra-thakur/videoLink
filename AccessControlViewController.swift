//
//  AccessControlViewController.swift
//  BrandedResidence
//
//  Created by Devendra Thakur on 02/02/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit
import UIKITExtension
import DVCUtility
import AppManagement
import Combine
// MARK: - Enum
enum AccessControlRow: Hashable {
    case controlRow(day: Feature)
    case waiting
}
enum AccessControlSection {
    case main
    case waiting
}

class AccessControlViewController: BaseViewController {
    @IBOutlet weak var collectionViewAccessControl: UICollectionView!
    @IBOutlet weak var labelHeader: UILabel!
    typealias DataSource = UICollectionViewDiffableDataSource<AccessControlSection, AccessControlRow>
    typealias Snapshot   = NSDiffableDataSourceSnapshot<AccessControlSection, AccessControlRow>
    internal lazy var dataSource = configDataSource()
    internal var cancellables = [AnyCancellable]()
    override func viewDidLoad() {
        super.viewDidLoad()
        labelHeader.text = currentFeature?.displayName ?? "Access Control"
        // Do any additional setup after loading the view.
        collectionViewAccessControl.collectionViewLayout = createLayout()
        collectionViewAccessControl.delegate = self
        collectionViewAccessControl.dataSource = dataSource
        collectionViewAccessControl.register(nib: AccessControlCollectionViewCell.self)
        collectionViewAccessControl.register(nib: AccessControlTimeCell.self)
        collectionViewAccessControl.contentInset = .init(top: 0, left: 0, bottom: 100, right: 0)
        applySnapshot()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        if !appdelegate.acsManager.bleSetupStarted {
            appdelegate.acsManager.validateSDKStatus()
        } else if appdelegate.acsManager.bleSetupStarted {
            appdelegate.acsManager.checkSetupStatus()
        }
        sendFirebaseLog(moduleName: .accessControl, scrnName: currentFeature?.displayName)
    }
    @objc func applicationDidEnterBackground() {
        locationService()
    }
    @objc func applicationWillEnterForeground() {
        locationService(start: true)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let parent = parent as? RootPageViewController {
            parent.navigationDelegate = self
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkBluetoothPermission()
        locationService(start: true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationService()
    }
    func configDataSource() -> DataSource {
        let dataSource = DataSource(collectionView: collectionViewAccessControl,
                                    cellProvider: { collection, indexPath, rowType in
            switch rowType {
            case .controlRow(let feature):
                let cell = collection.dequeueReusableCell(ofType: AccessControlCollectionViewCell.self,
                                                          forIndexPath: indexPath)
                cell.accesscontrol = feature
                cell.alpha = 1.0
                if !appdelegate.acsManager.userIsSyncedInCSV() {
                    cell.alpha = 0.3
                }
                return cell
            case .waiting:
                let cell = collection.dequeueReusableCell(ofType: AccessControlTimeCell.self,
                                                          forIndexPath: indexPath)
                cell.parentView = self
                return cell
            }
        })
        return dataSource
    }
    func applySnapshot() {
        if let content = subFeatures?.compactMap({$0}), !content.isEmpty {
            var snapshot = Snapshot()
            if UserDefaults.standard.value(forKey: Key.userAccessDeined.rawValue) is Date {
                if !appdelegate.acsManager.userIsSyncedInCSV() {
                    snapshot.appendSections([.waiting])
                    snapshot.appendItems([AccessControlRow.waiting], toSection: .waiting)
                }
            }
            snapshot.appendSections([.main])
            _ = content.map { item in
                snapshot.appendItems([AccessControlRow.controlRow(day: item)])
            }
            dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
    deinit {
      cancellables.removeAll()
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification,
                                                  object: nil)
    }
}
