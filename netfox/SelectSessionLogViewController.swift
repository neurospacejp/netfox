//
//  SelectSessionLogViewController.swift
//  20190805_123448
//
//  Created by TAKESHI SHIMADA on 2019/08/07.
//  Copyright © 2019 TAKESHI SHIMADA. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class SelectSessionLogViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!

    private var sessionLogFileNames = [String]()
    private var selectedIndexs = [Int]()
    private let LableTag = 10001
    
    private let nfxAdditions = NFXAdditions()

    let mailViewController = MFMailComposeViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.sessionLogFileNames = nfxAdditions.getSessionLogFileNames().sorted(by: >)
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessionLogFileNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SessionLogFileInfoCell") ?? UITableViewCell()
        if let label = getView(view: cell, tag: LableTag) as? UILabel {
            label.text = sessionLogFileNames[indexPath.row]
        }
        cell.accessoryType = selectedIndexs.contains(indexPath.row) ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let isSelected = selectedIndexs.contains(indexPath.row)
        if isSelected {
            selectedIndexs = selectedIndexs.filter { $0 != indexPath.row }
        } else {
            selectedIndexs.append(indexPath.row)
        }
        tableView.reloadData()
    }
    
    private func getView(view: UIView, tag: Int) -> UIView? {
        for v in view.subviews {
            if v.tag == tag {
                return v
            }
            return getView(view: v, tag: tag)
        }
        return nil
    }
  
  @IBAction func close() {
    dismiss(animated: true, completion: nil)
  }

}

// mail
extension SelectSessionLogViewController: MFMailComposeViewControllerDelegate {
    
    // メール起動
    @IBAction func showMailer() {
        
      if MFMailComposeViewController.canSendMail() {
        
        mailViewController.mailComposeDelegate = self
        mailViewController.setSubject("session.log")
        //let toRecipients = ["aaaaaaaa@gmail.com"]
        //mailViewController.setToRecipients(toRecipients)
        mailViewController.setMessageBody("", isHTML: false)
        
        let dateString = nfxAdditions.stringDate(data: Date())
        let files = selectedIndexs.map { sessionLogFileNames[$0] }
        if let data = nfxAdditions.attachData(files: files) {
          mailViewController.addAttachmentData(data, mimeType: "text/plane", fileName: "session_bundle_log_\(dateString).log")
        }
        
        self.present(mailViewController, animated: true, completion: nil)
      } else {
        print("メーラーが起動できません")
      }
  }
  
    // delegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        switch result {
        case .cancelled:
            print("Email Send Cancelled")
            break
        case .saved:
            print("Email Saved as a Draft")
            break
        case .sent:
            print("Email Sent Successfully")
            break
        case .failed:
            print("Email Send Failed")
            break
        default:
            break
        }
        
      mailViewController.dismiss(animated: true, completion: { [weak self] in
        self?.selectedIndexs = []
        self?.tableView.reloadData()
      })
    }
    
}

