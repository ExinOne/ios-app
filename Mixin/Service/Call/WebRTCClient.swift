import Foundation
import WebRTC
import MixinServices

protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: WebRTCClient, didGenerateLocalCandidate candidate: RTCIceCandidate)
    func webRTCClientDidConnected(_ client: WebRTCClient)
    func webRTCClientDidDisconnected(_ client: WebRTCClient)
    func webRTCClient(_ client: WebRTCClient, didChangeIceConnectionStateTo newState: RTCIceConnectionState)
    func webRTCClient(_ client: WebRTCClient, senderPublicKeyForUserWith userId: String, sessionId: String) -> Data?
    func webRTCClient(_ client: WebRTCClient, didAddReceiverWith userId: String)
}

class WebRTCClient: NSObject {
    
    weak var delegate: WebRTCClientDelegate?
    
    private unowned let queue: DispatchQueue
    
    private let audioId = "audio0"
    private let streamId = "stream0"
    private let factory = RTCPeerConnectionFactory(encoderFactory: RTCDefaultVideoEncoderFactory(),
                                                   decoderFactory: RTCDefaultVideoDecoderFactory())
    
    private(set) var audioTrack: RTCAudioTrack?
    
    private var isClosed = false
    private var peerConnection: RTCPeerConnection?
    private var rtpSender: RTCRtpSender?
    private var rtpReceivers = [String : RTCRtpReceiver]()
    private var tracksUserId: [String: String] = [:] // Key is track id, value is user id
    
    var canAddRemoteCandidate: Bool {
        peerConnection != nil
    }
    
    var iceConnectionState: RTCIceConnectionState {
        return peerConnection?.iceConnectionState ?? .closed
    }
    
    init(delegateQueue: DispatchQueue) {
        self.queue = delegateQueue
        super.init()
    }
    
    func offer(key: Data?, withIceRestartConstraint: Bool, completion: @escaping (Result<String, CallError>) -> Void) {
        makePeerConnectionIfNeeded(key: key) { connection in
            let mandatoryConstraints: [String: String]
            if withIceRestartConstraint {
                mandatoryConstraints = [kRTCMediaConstraintsIceRestart: kRTCMediaConstraintsValueTrue]
            } else {
                mandatoryConstraints = [:]
            }
            let constraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
            connection.offer(for: constraints) { (sdp, error) in
                if let sdp = sdp, let json = sdp.jsonString {
                    self.peerConnection?.setLocalDescription(sdp, completionHandler: { (_) in
                        self.queue.async {
                            completion(.success(json))
                        }
                    })
                } else {
                    self.queue.async {
                        completion(.failure(.offerConstruction(error)))
                    }
                }
            }
        }
    }
    
    func answer(completion: @escaping (Result<String, CallError>) -> Void) {
        makePeerConnectionIfNeeded(key: nil) { connection in
            let constraints = RTCMediaConstraints(mandatoryConstraints: [:], optionalConstraints: nil)
            connection.answer(for: constraints) { (sdp, error) in
                if let sdp = sdp, let json = sdp.jsonString {
                    self.peerConnection?.setLocalDescription(sdp, completionHandler: { (_) in
                        self.queue.async {
                            completion(.success(json))
                        }
                    })
                } else {
                    self.queue.async {
                        completion(.failure(.answerConstruction(error)))
                    }
                }
            }
        }
    }
    
    func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> Void) {
        makePeerConnectionIfNeeded(key: nil) { connection in
            connection.setRemoteDescription(remoteSdp, completionHandler: { error in
                self.queue.async {
                    completion(error)
                }
            })
        }
    }
    
    func add(remoteCandidate: RTCIceCandidate) {
        peerConnection?.add(remoteCandidate)
    }
    
    func setFrameEncryptorKey(_ key: Data?) {
        guard let key = key else {
            return
        }
        rtpSender?.setFrameEncryptorKey(key)
    }
    
    func setFrameDecryptorKey(_ key: Data?, forReceiverWith userId: String, sessionId: String) {
        let streamId = StreamId(userId: userId, sessionId: sessionId).rawValue
        if let receiver = rtpReceivers[streamId], let key = key {
            receiver.setFrameDecryptorKey(key)
        }
    }
    
    func audioLevels(completion: @escaping ([String: Double]) -> Void) {
        queue.async {
            let isAudioTrackEnabled = self.audioTrack?.isEnabled ?? false
            self.peerConnection?.statistics(completionHandler: { report in
                let audioLevels: [String: Double] = report.statistics.reduce(into: [:]) { result, pair in
                    if pair.key.hasPrefix("RTCMediaStreamTrack_sender_") {
                        if isAudioTrackEnabled {
                            guard
                                let mediaSourceId = pair.value.values["mediaSourceId"] as? String,
                                let source = report.statistics[mediaSourceId],
                                let level = source.values["audioLevel"] as? Double
                            else {
                                return
                            }
                            result[myUserId] = level
                        } else {
                            result[myUserId] = 0
                        }
                    } else if pair.key.hasPrefix("RTCMediaStreamTrack_receiver_") {
                        guard
                            let trackId = pair.value.values["trackIdentifier"] as? String,
                            let userId = self.tracksUserId[trackId],
                            let level = pair.value.values["audioLevel"] as? Double
                        else {
                            return
                        }
                        result[userId] = level
                    }
                }
                DispatchQueue.main.async {
                    completion(audioLevels)
                }
            })
        }
    }
    
    func close() {
        isClosed = true
        peerConnection?.close()
        peerConnection = nil
        audioTrack = nil
        rtpSender = nil
        rtpReceivers = [:]
    }
    
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
        if newState == .connected {
            queue.async {
                self.delegate?.webRTCClientDidConnected(self)
            }
        } else if newState == .disconnected {
            queue.async {
                self.delegate?.webRTCClientDidDisconnected(self)
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        queue.async {
            self.delegate?.webRTCClient(self, didChangeIceConnectionStateTo: newState)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams mediaStreams: [RTCMediaStream]) {
        let streamIds = mediaStreams
            .map(\.streamId)
            .compactMap(StreamId.init(rawValue:))
            .filter({ $0.userId != myUserId })
        for id in streamIds {
            let frameKey = delegate?.webRTCClient(self,
                                                  senderPublicKeyForUserWith: id.userId,
                                                  sessionId: id.sessionId)
            if let frameKey = frameKey {
                rtpReceivers[id.rawValue] = rtpReceiver
                rtpReceiver.setFrameDecryptorKey(frameKey)
            }
            if let trackId = rtpReceiver.track?.trackId {
                self.tracksUserId[trackId] = id.userId
            }
            queue.async {
                self.delegate?.webRTCClient(self, didAddReceiverWith: id.userId)
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        queue.async {
            self.delegate?.webRTCClient(self, didGenerateLocalCandidate: candidate)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
    
}

extension WebRTCClient {
    
    private func loadIceServers(completion: @escaping ([RTCIceServer]) -> Void) {
        CallAPI.turn(queue: queue) { [weak self] result in
            switch result {
            case let .success(servers):
                let iceServers = servers.map {
                    RTCIceServer(urlStrings: [$0.url], username: $0.username, credential: $0.credential)
                }
                completion(iceServers)
            case let .failure(error):
                Logger.call.error(category: "WebRTCClient", message: "ICE Server fetching fails: \(error)")
                self?.queue.asyncAfter(deadline: .now() + 2) {
                    guard let self = self, !self.isClosed else {
                        return
                    }
                    self.loadIceServers(completion: completion)
                }
            }
        }
    }
    
    private func makeRTCConfiguration(iceServers: [RTCIceServer]) -> RTCConfiguration {
        let config = RTCConfiguration()
        config.tcpCandidatePolicy = .enabled
        config.iceTransportPolicy = .relay
        config.bundlePolicy = .maxBundle
        config.rtcpMuxPolicy = .require
        config.sdpSemantics = .unifiedPlan
        config.iceServers = iceServers
        config.continualGatheringPolicy = .gatherOnce
        return config
    }
    
    private func makePeerConnectionIfNeeded(key: Data?, completion: @escaping (RTCPeerConnection) -> Void) {
        if let connection = peerConnection {
            completion(connection)
        } else {
            loadIceServers { [weak self] servers in
                guard let self = self, !self.isClosed else {
                    return
                }
                RTCAudioSession.sharedInstance().useManualAudio = true
                let config = self.makeRTCConfiguration(iceServers: servers)
                let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: [:])
                let peerConnection = self.factory.peerConnection(with: config,
                                                                 constraints: constraints,
                                                                 delegate: nil)
                peerConnection.delegate = self
                let audioTrack: RTCAudioTrack = {
                    let audioConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
                    let audioSource = self.factory.audioSource(with: audioConstraints)
                    return self.factory.audioTrack(with: audioSource, trackId: self.audioId)
                }()
                self.rtpSender = peerConnection.add(audioTrack, streamIds: [self.streamId])
                self.setFrameEncryptorKey(key)
                self.peerConnection = peerConnection
                self.audioTrack = audioTrack
                completion(peerConnection)
            }
        }
    }
    
}
