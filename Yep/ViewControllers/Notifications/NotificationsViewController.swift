//
//  NotificationsViewController.swift
//  Yep
//
//  Created by NIX on 15/8/3.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

struct DoNotDisturbPeriod {
    var isOn: Bool = false

    var fromHour: Int = 22
    var fromMinute: Int = 0

    var toHour: Int = 7
    var toMinute: Int = 30

    var fromString: String {
        return String(format: "%02d:%02d", fromHour, fromMinute)
    }
    var toString: String {
        return String(format: "%02d:%02d", toHour, toMinute)
    }
}

class NotificationsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var doNotDisturbPeriod = DoNotDisturbPeriod()

    let DoNotDisturbSwitchCellID = "DoNotDisturbSwitchCell"
    let DoNotDisturbPeriodCellID = "DoNotDisturbPeriodCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Notifications", comment: "")

        tableView.registerNib(UINib(nibName: DoNotDisturbSwitchCellID, bundle: nil), forCellReuseIdentifier: DoNotDisturbSwitchCellID)
        tableView.registerNib(UINib(nibName: DoNotDisturbPeriodCellID, bundle: nil), forCellReuseIdentifier: DoNotDisturbPeriodCellID)
    }

    // MARK: Actions

    func enableDoNotDisturb(#failed: () -> Void) {

        let realm = Realm()

        if let
            myUserID = YepUserDefaults.userID.value,
            me = userWithUserID(myUserID, inRealm: realm) {

                var userDoNotDisturb = me.doNotDisturb

                if userDoNotDisturb == nil {
                    let _userDoNotDisturb = UserDoNotDisturb()

                    realm.write {
                        me.doNotDisturb = _userDoNotDisturb
                    }

                    userDoNotDisturb = _userDoNotDisturb
                }

                if let userDoNotDisturb = me.doNotDisturb {

                    let info: JSONDictionary = [
                        "mute_started_at_string": userDoNotDisturb.fromString,
                        "mute_ended_at_string": userDoNotDisturb.toString,
                    ]

                    updateMyselfWithInfo(info, failureHandler: { [weak self] (reason, errorMessage) in
                        defaultFailureHandler(reason, errorMessage)

                        dispatch_async(dispatch_get_main_queue()) {
                            YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("Set Do Not Disturb failed!", comment: ""), inViewController: self)
                        }

                        failed()

                    }, completion: { success in

                        dispatch_async(dispatch_get_main_queue()) {

                            let realm = Realm()

                            if let
                                myUserID = YepUserDefaults.userID.value,
                                me = userWithUserID(myUserID, inRealm: realm) {

                                    realm.write {
                                        me.doNotDisturb?.isOn = true
                                    }
                            }
                        }
                    })
                }
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {

    enum DoNotDisturbPeriodRow: Int {
        case Switch
        case Period
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return doNotDisturbPeriod.isOn ? 2 : 1
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        switch indexPath.row {

        case DoNotDisturbPeriodRow.Switch.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(DoNotDisturbSwitchCellID) as! DoNotDisturbSwitchCell
            cell.promptLabel.text = NSLocalizedString("Do Not Disturb", comment: "")
            cell.toggleSwitch.on = doNotDisturbPeriod.isOn

            cell.toggleAction = { [weak self] isOn in

                self?.doNotDisturbPeriod.isOn = isOn

                let indexPath = NSIndexPath(forRow: DoNotDisturbPeriodRow.Period.rawValue, inSection: 0)

                if isOn {
                    self?.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                } else {
                    self?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }

                if isOn {
                    self?.enableDoNotDisturb(failed: {
                        dispatch_async(dispatch_get_main_queue()) {
                            self?.doNotDisturbPeriod.isOn = false
                            self?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                        }
                    })
                }
            }

            return cell

        case DoNotDisturbPeriodRow.Period.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(DoNotDisturbPeriodCellID) as! DoNotDisturbPeriodCell
            cell.fromPromptLabel.text = NSLocalizedString("From", comment: "")
            cell.toPromptLabel.text = NSLocalizedString("To", comment: "")

            cell.fromLabel.text = doNotDisturbPeriod.fromString
            cell.toLabel.text = doNotDisturbPeriod.toString

            return cell

        default:
            return UITableViewCell()
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        switch indexPath.row {

        case DoNotDisturbPeriodRow.Switch.rawValue:
            return 44

        case DoNotDisturbPeriodRow.Period.rawValue:
            return 60

        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        if indexPath.row == DoNotDisturbPeriodRow.Period.rawValue {
            performSegueWithIdentifier("showDoNotDisturbPeriod", sender: nil)
        }
    }
}

