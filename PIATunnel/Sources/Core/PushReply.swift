//
//  PushReply.swift
//  PIATunnel
//
//  Created by Davide De Rosa on 25/07/2018.
//  Copyright © 2018 London Trust Media. All rights reserved.
//

import Foundation

struct PushReply {
    private static let ifconfigRegexp = try! NSRegularExpression(pattern: "ifconfig [\\d\\.]+ [\\d\\.]+", options: [])

    private static let ifconfig6Regexp = try! NSRegularExpression(pattern: "ifconfig-ipv6 [a-fA-F0-9:/]+ [a-fA-F0-9:/]+", options: [])

    private static let dnsRegexp = try! NSRegularExpression(pattern: "dhcp-option DNS [\\d\\.]+", options: [])

    private static let authTokenRegexp = try! NSRegularExpression(pattern: "auth-token [a-zA-Z0-9/=+]+", options: [])

    private static let peerIdRegexp = try! NSRegularExpression(pattern: "peer-id [0-9]+", options: [])
    
    let address: String

    let address6: String
    
    let address6Prefix: NSNumber
    
    let gatewayAddress: String
    
    let gateway6Address: String
    
    let dnsServers: [String]
    
    let authToken: String?
    
    let peerId: UInt32?
    
    init?(message: String) throws {
        guard message.hasPrefix("PUSH_REPLY") else {
            return nil
        }
        
        var ifconfigComponents: [String]?
        var ifconfig6Components: [String]?
        var dnsServers = [String]()
        var authToken: String?
        var peerId: UInt32?

        PushReply.ifconfigRegexp.enumerateMatches(in: message, options: [], range: NSMakeRange(0, message.count)) { (result, flags, _) in
            guard let range = result?.range else { return }
            
            let match = (message as NSString).substring(with: range)
            ifconfigComponents = match.components(separatedBy: " ")
        }
        
        guard let addresses = ifconfigComponents, addresses.count >= 2 else {
            throw SessionError.malformedPushReply
        }

        PushReply.ifconfig6Regexp.enumerateMatches(in: message, options: [], range: NSMakeRange(0, message.count)) { (result, flags, _) in
            guard let range = result?.range else { return }
            
            let match = (message as NSString).substring(with: range)
            ifconfig6Components = match.components(separatedBy: " ")
        }
        
        guard let addresses6 = ifconfig6Components, addresses6.count >= 2 else {
            throw SessionError.malformedPushReply
        }
        
        PushReply.dnsRegexp.enumerateMatches(in: message, options: [], range: NSMakeRange(0, message.count)) { (result, flags, _) in
            guard let range = result?.range else { return }
            
            let match = (message as NSString).substring(with: range)
            let dnsEntryComponents = match.components(separatedBy: " ")
            
            dnsServers.append(dnsEntryComponents[2])
        }
        
        PushReply.authTokenRegexp.enumerateMatches(in: message, options: [], range: NSMakeRange(0, message.count)) { (result, flags, _) in
            guard let range = result?.range else { return }
            
            let match = (message as NSString).substring(with: range)
            let tokenComponents = match.components(separatedBy: " ")
            
            if (tokenComponents.count > 1) {
                authToken = tokenComponents[1]
            }
        }
        
        PushReply.peerIdRegexp.enumerateMatches(in: message, options: [], range: NSMakeRange(0, message.count)) { (result, flags, _) in
            guard let range = result?.range else { return }
            
            let match = (message as NSString).substring(with: range)
            let tokenComponents = match.components(separatedBy: " ")
            
            if (tokenComponents.count > 1) {
                peerId = UInt32(tokenComponents[1])
            }
        }

        address = addresses[1]
        address6 = String(addresses6[1].split(separator: "/")[0])
        address6Prefix = NSNumber.init(value: Int32(addresses6[1].split(separator: "/")[1])!)
        gatewayAddress = addresses[2]
        gateway6Address = addresses6[2]
        self.dnsServers = dnsServers
        self.authToken = authToken
        self.peerId = peerId
    }
}
