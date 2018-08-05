//
//  PushReply.swift
//  PIATunnel
//
//  Created by Davide De Rosa on 25/07/2018.
//  Copyright © 2018 London Trust Media. All rights reserved.
//

import Foundation

struct PushReply {
    // depending on the topology we have to interprete the parameters of "ifconfig" differently. In
    // case the topology is subnet, the second compononent is the netmask instead of the gateway
    private static let topologyRegexp = try! NSRegularExpression(pattern: "topology (net30|p2p|subnet)", options: [])
    
    // if the topology is subnet, we also have a "route-gateway" indicating the default gateway
    private static let routeGatewayRegexp = try! NSRegularExpression(pattern: "route-gateway [\\d\\.]+", options: [])
    
    private static let ifconfigRegexp = try! NSRegularExpression(pattern: "ifconfig [\\d\\.]+ [\\d\\.]+", options: [])
 
    private static let dnsRegexp = try! NSRegularExpression(pattern: "dhcp-option DNS [\\d\\.]+", options: [])

    private static let ifconfigRegexp = try! NSRegularExpression(pattern: "ifconfig [\\d\\.]+ [\\d\\.]+", options: [])

    private static let dnsRegexp = try! NSRegularExpression(pattern: "dhcp-option DNS [\\d\\.]+", options: [])

    private static let authTokenRegexp = try! NSRegularExpression(pattern: "auth-token [a-zA-Z0-9/=+]+", options: [])

    private static let peerIdRegexp = try! NSRegularExpression(pattern: "peer-id [0-9]+", options: [])
    
    let address: String

    let addressMask: String
    
    let gatewayAddress: String
    
    let dnsServers: [String]
    
    let authToken: String?
    
    let peerId: UInt32?
    
    init?(message: String) throws {
        guard message.hasPrefix("PUSH_REPLY") else {
            return nil
        }
        
        var ifconfigComponents: [String]?
        var dnsServers = [String]()
        var authToken: String?
        var peerId: UInt32?
        var topologyType: String?
        var routeGateway: String?
        
        PushReply.topologyRegexp.enumerateMatches(in: message, options: [], range: NSMakeRange(0, message.count)) { (result, flags, _) in
            guard let range = result?.range else { return }
            
            let match = (message as NSString).substring(with: range)
            let tokenComponents = match.components(separatedBy: " ")
            
            if (tokenComponents.count > 1) {
                topologyType = tokenComponents[1]
            }
        }
        
        PushReply.routeGatewayRegexp.enumerateMatches(in: message, options: [], range: NSMakeRange(0, message.count)) { (result, flags, _) in
            guard let range = result?.range else { return }
            
            let match = (message as NSString).substring(with: range)
            let tokenComponents = match.components(separatedBy: " ")
            
            if (tokenComponents.count > 1) {
                routeGateway = tokenComponents[1]
            }
        }
        
        PushReply.ifconfigRegexp.enumerateMatches(in: message, options: [], range: NSMakeRange(0, message.count)) { (result, flags, _) in
            guard let range = result?.range else { return }
            
            let match = (message as NSString).substring(with: range)
            ifconfigComponents = match.components(separatedBy: " ")
        }
        
        guard let addresses = ifconfigComponents, addresses.count >= 2 else {
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
        // XXX what if the topologyType is not set? I guess it won't match!
        if("subnet" == topologyType) {
            addressMask = addresses[2]
            // XXX the routeGateway could be "nil" I guess, then what?
            // Most likely we don't want to set the gateway at all then...
            gatewayAddress = routeGateway!
        } else {
            addressMask = "255.255.255.255"
            gatewayAddress = addresses[2]
        }
        self.dnsServers = dnsServers
        self.authToken = authToken
        self.peerId = peerId
    }
}
