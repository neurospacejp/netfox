//
//  NFXAddition.swift
//  20190805_123448
//
//  Created by TAKESHI SHIMADA on 2019/08/06.
//  Copyright © 2019 TAKESHI SHIMADA. All rights reserved.
//

import UIKit

extension UIWindow {
  override open func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
  {
    if (event!.type == .motion && event!.subtype == .motionShake) {
        
        let storyboard = UIStoryboard.init(name: "SelectSessionLogViewController", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SelectSessionLogViewController") as? SelectSessionLogViewController {
            self.rootViewController?.present(viewController, animated: true, completion: nil)
        }
    }
  }
}


@objc open class NFXAdditions: NSObject {
   
    let fileManager = FileManager.default
    let documentsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    
    private var sessionLogPathString: String {
        get {
            return documentsDir + "/" + "session.log"
        }
    }
    
    private var storedLogDirString: String {
        get {
            return documentsDir + "/" + "storedLog"
        }
    }
    
    var concatLogPath: String {
        get {
            return documentsDir + "/" + "session_bundle.log"
        }
    }
   
    @objc open func showSendLogView(parentVC: UIViewController) {
        let storyboard = UIStoryboard.init(name: "SelectSessionLogViewController", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SelectSessionLogViewController") as? SelectSessionLogViewController {
            parentVC.present(viewController, animated: true, completion: nil)
        }
    }
}

extension NFXAdditions {

    // 起動時にsession.log を storedLog/sessionlog_yyyyMMddhhmm.log にコピーする
    func storeLogFile() {
        makeDistDirIfNeeded(storedLogDirString)
        let date = Date()
        let dateString = stringDate(data: date)
        let fileName = "session_" + dateString + ".log"
        try? fileManager.copyItem(atPath: sessionLogPathString, toPath: storedLogDirString + "/" + fileName)
    }
    
    func deleteOldLogFile() {
        let files = getSessionLogFileNames()

        let fullpaths = files
            .filter { $0.contains("session_") }
            .map { storedLogDirString + "/" + $0 }
        
        let removableFiles = fullpaths
            .filter {
                guard let attr = try? fileManager.attributesOfItem(atPath: $0) as NSDictionary?,
                    let fileCreationDate = attr.fileCreationDate() else { return false }
                    
                let diff = fileCreationDate.timeIntervalSinceNow
                return diff < -1 * 60 * 60 * 24 * 30 * 6
            }

        removableFiles.forEach {
            try? fileManager.removeItem(atPath: $0)
        }
    }

    private func makeDistDirIfNeeded(_ distDir: String) {
        if !fileManager.fileExists(atPath: distDir) {
            do {
                try fileManager.createDirectory(atPath: distDir, withIntermediateDirectories: false, attributes: nil)
            } catch {
                //print(error)
            }
        }
    }
    
    // 新しいファイル名を作る
    func stringDate(data: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd_HHmmss"
        let nowString = df.string(from: data)
        return nowString
    }
    
    // for table view
    func getSessionLogFileNames() -> [String] {
        let files = ((try? fileManager.contentsOfDirectory(atPath: storedLogDirString)) ?? [])
            .filter { $0.contains("session_") }
        return files
    }
    
    // for mail
    func attachData(files: [String]) -> Data? {

        // output file
        if !fileManager.fileExists(atPath: concatLogPath) {
            try? fileManager.removeItem(atPath: concatLogPath)
        }
        let _ = fileManager.createFile(atPath: concatLogPath, contents: nil, attributes: nil)
       
        // concat log
        files.forEach { file in
            if file.contains("session_") {
                concatFile(filePath: file)
            }
        }

        // file to data
        let targetFilePath = URL(fileURLWithPath: concatLogPath)
        let data = try? Data(contentsOf: targetFilePath)
        return data
    }

    private func concatFile(filePath: String) {
        
        let logFullPath = storedLogDirString + "/" + filePath
        
        let fileUrl = URL(fileURLWithPath: logFullPath)
        if let data = self.dataFromFileUrl(fileUrl) {
            
            let delims = "\n------ \(filePath) ---------\n"
            let delimsData = delims.data(using: .utf8)!
            
            var data2 = delimsData
            data2.append(data)
            
            if let filehandle = FileHandle.init(forWritingAtPath: concatLogPath) {
                filehandle.seekToEndOfFile()
                filehandle.write(data2)
                filehandle.closeFile()
                // try? fileManager.removeItem(atPath: logFullPath)
            }
        }
    }
    
    private func dataFromFileUrl(_ fileUrl: URL?) -> Data? {
        guard let fileUrl = fileUrl else { return nil }
        return try? Data(contentsOf: fileUrl)
    }
}
