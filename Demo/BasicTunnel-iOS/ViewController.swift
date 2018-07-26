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

    static let CIPHER: PIATunnelProvider.Cipher = .aes256cbc

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
            uM92Txg11uLAoMV4P3NaU8rzcRP+bkhtFTWzCzw=
            -----END CERTIFICATE-----
            """
            builder.key = """
            -----BEGIN PRIVATE KEY-----
            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
            94T4HiQemtOnW1LkelRmB9xp5EpEXA==
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

