//
//  ViewController.swift
//  BasicTunnel-iOS
//
//  Created by Davide De Rosa on 2/11/17.
//  Copyright © 2018 London Trust Media. All rights reserved.
//

import UIKit
import NetworkExtension
import PIATunnel

class ViewController: UIViewController, URLSessionDataDelegate {
    static let APP_GROUP = "group.net.tuxed.vpn.BasicTunnel"
    
    static let VPN_BUNDLE = "net.tuxed.vpn.BasicTunnel.BasicTunnelExtension"

    static let CIPHER: PIATunnelProvider.Cipher = .aes256gcm

    static let DIGEST: PIATunnelProvider.Digest = .sha256

    static let HANDSHAKE: PIATunnelProvider.Handshake = .rsa2048
    
    static let RENEG: Int? = nil
    
    static let DOWNLOAD_COUNT = 5
    
    @IBOutlet var textUsername: UITextField!
    
    @IBOutlet var textPassword: UITextField!
    
    @IBOutlet var textServer: UITextField!
    
    @IBOutlet var textDomain: UITextField!
    
    @IBOutlet var textPort: UITextField!
    
    @IBOutlet var switchTCP: UISwitch!
    
    @IBOutlet var buttonConnection: UIButton!

    @IBOutlet var textLog: UITextView!

    //
    
    @IBOutlet var buttonDownload: UIButton!

    @IBOutlet var labelDownload: UILabel!
    
    var currentManager: NETunnelProviderManager?
    
    var status = NEVPNStatus.invalid
    
    var downloadTask: URLSessionDataTask!
    
    var downloadCount = 0

    var downloadTimes = [TimeInterval]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        textServer.text = "vpn.tuxed.net"
        textDomain.text = ""
//        textServer.text = "159.122.133.238"
//        textDomain.text = ""
        textPort.text = "1197"
        switchTCP.isOn = false
        textUsername.text = "myusername"
        textPassword.text = "mypassword"
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(VPNStatusDidChange(notification:)),
                                               name: .NEVPNStatusDidChange,
                                               object: nil)
        
        reloadCurrentManager(nil)

        //
        
        testFetchRef()
    }
    
    @IBAction func connectionClicked(_ sender: Any) {
        let block = {
            switch (self.status) {
            case .invalid, .disconnected:
                self.connect()
                
            case .connected, .connecting:
                self.disconnect()
                
            default:
                break
            }
        }
        
        if (status == .invalid) {
            reloadCurrentManager({ (error) in
                block()
            })
        }
        else {
            block()
        }
    }
    
    @IBAction func tcpClicked(_ sender: Any) {
        if switchTCP.isOn {
            textPort.text = "443"
        } else {
            textPort.text = "8080"
        }
    }
    
    func connect() {
        let server = textServer.text!
        let domain = textDomain.text!
        
        let hostname = ((domain == "") ? server : [server, domain].joined(separator: "."))
        let port = UInt16(textPort.text!)!
        let username = textUsername.text!
        let password = textPassword.text!

        configureVPN({ (manager) in
//            manager.isOnDemandEnabled = true
//            manager.onDemandRules = [NEOnDemandRuleConnect()]
            
            let endpoint = PIATunnelProvider.AuthenticatedEndpoint(
                hostname: hostname,
                username: username,
                password: password
            )

            var builder = PIATunnelProvider.ConfigurationBuilder(appGroup: ViewController.APP_GROUP)
            let socketType: PIATunnelProvider.SocketType = (self.switchTCP.isOn ? .tcp : .udp)
            builder.endpointProtocols = [PIATunnelProvider.EndpointProtocol(socketType, port, .vanilla)]
            builder.cipher = ViewController.CIPHER
            builder.digest = ViewController.DIGEST
            builder.handshake = .custom
            builder.mtu = 1500
            builder.ca = """
            -----BEGIN CERTIFICATE-----
            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
            XxuPeGGMYTQP3MPveijYdFJbp3MMb996
            -----END CERTIFICATE-----
            """
            builder.cert = """
            -----BEGIN CERTIFICATE-----
            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
            -----END CERTIFICATE-----
            """
            builder.key = """
            -----BEGIN PRIVATE KEY-----
            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
            GNZluZdHdZlBe9Ep1djSO6Q4Uvnb6g==
            -----END PRIVATE KEY-----
            """
            builder.renegotiatesAfterSeconds = ViewController.RENEG
            builder.shouldDebug = true
            builder.debugLogKey = "Log"
            
            let configuration = builder.build()
            return try! configuration.generatedTunnelProtocol(withBundleIdentifier: ViewController.VPN_BUNDLE, endpoint: endpoint)
        }, completionHandler: { (error) in
            if let error = error {
                print("configure error: \(error)")
                return
            }
            let session = self.currentManager?.connection as! NETunnelProviderSession
            do {
                try session.startTunnel()
            } catch let e {
                print("error starting tunnel: \(e)")
            }
        })
    }
    
    func disconnect() {
        configureVPN({ (manager) in
//            manager.isOnDemandEnabled = false
            return nil
        }, completionHandler: { (error) in
            self.currentManager?.connection.stopVPNTunnel()
        })
    }

    @IBAction func displayLog() {
        guard let vpn = currentManager?.connection as? NETunnelProviderSession else {
            return
        }
        try? vpn.sendProviderMessage(PIATunnelProvider.Message.requestLog.data) { (data) in
            guard let log = String(data: data!, encoding: .utf8) else {
                return
            }
            self.textLog.text = log
        }
    }

    @IBAction func download() {
        downloadCount = ViewController.DOWNLOAD_COUNT
        downloadTimes.removeAll()
        buttonDownload.isEnabled = false
        labelDownload.text = ""

        doDownload()
    }
    
    func doDownload() {
        let url = URL(string: "https://example.bogus/test/100mb")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let cfg = URLSessionConfiguration.ephemeral
        let sess = URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
        
        let start = Date()
        downloadTask = sess.dataTask(with: req) { (data, response, error) in
            if let error = error {
                print("error downloading: \(error)")
                return
            }
            
            let elapsed = -start.timeIntervalSinceNow
            print("download finished: \(elapsed) seconds")
            self.downloadTimes.append(elapsed)
            
            DispatchQueue.main.async {
                self.downloadCount -= 1
                if (self.downloadCount > 0) {
                    self.labelDownload.text = "\(self.labelDownload.text!)\(elapsed) seconds\n"
                    self.doDownload()
                } else {
                    var avg = 0.0
                    for n in self.downloadTimes {
                        avg += n
                    }
                    avg /= Double(ViewController.DOWNLOAD_COUNT)
                    
                    self.labelDownload.text = "\(avg) seconds"
                    self.buttonDownload.isEnabled = true
                }
            }
        }
        downloadTask.resume()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("received \(data.count) bytes")
    }
    
    func configureVPN(_ configure: @escaping (NETunnelProviderManager) -> NETunnelProviderProtocol?, completionHandler: @escaping (Error?) -> Void) {
        reloadCurrentManager { (error) in
            if let error = error {
                print("error reloading preferences: \(error)")
                completionHandler(error)
                return
            }
            
            let manager = self.currentManager!
            if let protocolConfiguration = configure(manager) {
                manager.protocolConfiguration = protocolConfiguration
            }
            manager.isEnabled = true
            
            manager.saveToPreferences { (error) in
                if let error = error {
                    print("error saving preferences: \(error)")
                    completionHandler(error)
                    return
                }
                print("saved preferences")
                self.reloadCurrentManager(completionHandler)
            }
        }
    }
    
    func reloadCurrentManager(_ completionHandler: ((Error?) -> Void)?) {
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if let error = error {
                completionHandler?(error)
                return
            }
            
            var manager: NETunnelProviderManager?
            
            for m in managers! {
                if let p = m.protocolConfiguration as? NETunnelProviderProtocol {
                    if (p.providerBundleIdentifier == ViewController.VPN_BUNDLE) {
                        manager = m
                        break
                    }
                }
            }
            
            if (manager == nil) {
                manager = NETunnelProviderManager()
            }
            
            self.currentManager = manager
            self.status = manager!.connection.status
            self.updateButton()
            completionHandler?(nil)
        }
    }
    
    func updateButton() {
        switch status {
        case .connected, .connecting:
            buttonConnection.setTitle("Disconnect", for: .normal)
            
        case .disconnected:
            buttonConnection.setTitle("Connect", for: .normal)
            
        case .disconnecting:
            buttonConnection.setTitle("Disconnecting", for: .normal)
            
        default:
            break
        }
    }
    
    @objc private func VPNStatusDidChange(notification: NSNotification) {
        guard let status = currentManager?.connection.status else {
            print("VPNStatusDidChange")
            return
        }
        print("VPNStatusDidChange: \(status.rawValue)")
        self.status = status
        updateButton()
    }
    
    private func testFetchRef() {
//        let keychain = Keychain(group: ViewController.APP_GROUP)
//        let username = "foo"
//        let password = "bar"
//        
//        guard let _ = try? keychain.set(password: password, for: username) else {
//            print("Couldn't set password")
//            return
//        }
//        guard let passwordReference = try? keychain.passwordReference(for: username) else {
//            print("Couldn't get password reference")
//            return
//        }
//        guard let fetchedPassword = try? Keychain.password(for: username, reference: passwordReference) else {
//            print("Couldn't fetch password")
//            return
//        }
//
//        print("\(username) -> \(password)")
//        print("\(username) -> \(fetchedPassword)")
    }
}
