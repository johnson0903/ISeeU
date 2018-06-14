//
//  ViewController.swift
//  ISeeYou
//
//  Created by 李嘉晟 on 2018/6/12.
//  Copyright © 2018 李嘉晟. All rights reserved.
//

import UIKit
import TwilioVideo
import MapKit

class ShortDistanceViewController: UIViewController {

    var currentMode = Mode.none
    var safeDistance: Int {
        get {
            switch currentMode {
            case .home:
                return 10
            case .indoor:
                return 5
            case .outdoor:
                return 15
            default:
                return 20
            }
        }
    }
    var dropDownButton = DropDownButton(title: "請選擇符合您的情境")
    
    var accessToken = "TWILIO_ACCESS_TOKEN"
    // Configure remote URL to fetch token from
    var tokenUrl = "http://fast-reaches-35245.herokuapp.com/token"
    
    
    // Video SDK components
    var room: TVIRoom?
    var camera: TVICameraCapturer?
    var localVideoTrack: TVILocalVideoTrack?
    var localAudioTrack: TVILocalAudioTrack?
    var remoteParticipant: TVIRemoteParticipant?
    var remoteView: TVIVideoView?
    
    // TVIVideoView created from a storyboard
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var distanceRangeView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRemoteVideoView()
        
        // Disconnect and mic button will be displayed when the Client is connected to a Room.
        self.disconnectButton.isHidden = true
        self.micButton.isHidden = true
        
        self.distanceLabel.text = String(self.safeDistance)
        self.distanceLabel.layer.cornerRadius = 10
        self.distanceLabel.clipsToBounds = true
        
        // 模式下拉選單UI設定
        dropDownButton.dropDownView.delegate = self
        self.view.addSubview(dropDownButton)
        dropDownButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        dropDownButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 50).isActive = true
        dropDownButton.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 80).isActive = true
        dropDownButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -80).isActive = true
        dropDownButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        // 地圖UI設定, 一開始隱藏
        self.mapView.isHidden = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        mapView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: self.remoteView!.topAnchor, constant: 10).isActive = true
        
        // 顯示距離方塊UI設定
        distanceRangeView.layer.cornerRadius = distanceRangeView.frame.width / 2
        distanceRangeView.backgroundColor = UIColor.init(red: 34, green: 98, blue: 98, alpha: 0.3)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    // 隨著目前使用模式顯示或隱藏mapview
    func updateModeUI() {
        switch self.currentMode {
        case .home,
             .indoor,
             .dontDisturb,
             .none:
            self.mapView.isHidden = true
            
        case .outdoor:
            self.mapView.isHidden = false
        }
        
        self.distanceLabel.text = String(self.safeDistance)
    }
    
    // remoteView設定
    func setupRemoteVideoView() {
        
        // Creating `TVIVideoView` programmatically
        self.remoteView = TVIVideoView.init(frame: CGRect.zero, delegate:self)
        self.remoteView!.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(remoteView!, at: 2)

        // `TVIVideoView` supports scaleToFill, scaleAspectFill and scaleAspectFit
        // scaleAspectFit is the default mode when you create `TVIVideoView` programmatically.
        self.remoteView!.contentMode = .scaleAspectFill;

        self.remoteView?.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.remoteView?.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.remoteView?.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        let height: CGFloat = self.view.frame.height * (2.0 / 5.0)
        self.remoteView?.heightAnchor.constraint(equalToConstant: height).isActive = true
        self.remoteView?.layer.cornerRadius = 12
        self.remoteView?.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]

    }

    // MARK: Twilo IBActions
    @IBAction func connect(sender: AnyObject) {
        // Configure access token either from server or manually.
        // If the default wasn't changed, try fetching from server.
        if (accessToken == "TWILIO_ACCESS_TOKEN") {
            do {
                accessToken = try TokenUtils.fetchToken(url: tokenUrl)
                print(accessToken)
            } catch {
                let message = "Failed to fetch access token"
                logMessage(messageText: message)
                return
            }
        }

        // Prepare local media which we will share with Room Participants.
        self.prepareLocalMedia()

        // Preparing the connect options with the access token that we fetched (or hardcoded).
        let connectOptions = TVIConnectOptions.init(token: accessToken) { (builder) in
            // Use the local media that we prepared earlier.
            builder.audioTracks = self.localAudioTrack != nil ? [self.localAudioTrack!] : [TVILocalAudioTrack]()
            builder.videoTracks = self.localVideoTrack != nil ? [self.localVideoTrack!] : [TVILocalVideoTrack]()

            // Use the preferred audio codec
            if let preferredAudioCodec = Settings.shared.audioCodec {
                builder.preferredAudioCodecs = [preferredAudioCodec]
            }

            // Use the preferred video codec
            if let preferredVideoCodec = Settings.shared.videoCodec {
                builder.preferredVideoCodecs = [preferredVideoCodec]
            }

            // Use the preferred encoding parameters
            if let encodingParameters = Settings.shared.getEncodingParameters() {
                builder.encodingParameters = encodingParameters
            }

            // The name of the Room where the Client will attempt to connect to. Please note that if you pass an empty
            // Room `name`, the Client will create one for you. You can get the name or sid from any connected Room.
            builder.roomName = "iseeyou"
        }
        // Connect to the Room using the options we provided.
        room = TwilioVideo.connect(with: connectOptions, delegate: self)

        logMessage(messageText: "Attempting to connect to room \(room!.name)")

        self.showRoomUI(inRoom: true)
    }

    @IBAction func disconnect(sender: AnyObject) {
        self.room!.disconnect()
        logMessage(messageText: "Attempting to disconnect from room \(room!.name)")
    }

    @IBAction func toggleMic(sender: AnyObject) {
        if (self.localAudioTrack != nil) {
            self.localAudioTrack?.isEnabled = !(self.localAudioTrack?.isEnabled)!

            // Update the button title
            if (self.localAudioTrack?.isEnabled == true) {
                self.micButton.setTitle("靜音", for: .normal)
            } else {
                self.micButton.setTitle("開啟聲音", for: .normal)
            }
        }
    }

    // MARK: Private
    func prepareLocalMedia() {

        // We will share local audio and video when we connect to the Room.

        // Create an audio track.
        if (localAudioTrack == nil) {
            localAudioTrack = TVILocalAudioTrack.init(options: nil, enabled: true, name: "Microphone")

            if (localAudioTrack == nil) {
                logMessage(messageText: "Failed to create audio track")
            }
        }
    }

    // Update our UI based upon if we are in a Room or not
    func showRoomUI(inRoom: Bool) {
        self.connectButton.isHidden = inRoom
        self.micButton.isHidden = !inRoom
        self.disconnectButton.isHidden = !inRoom
        self.navigationController?.setNavigationBarHidden(inRoom, animated: true)
        UIApplication.shared.isIdleTimerDisabled = inRoom
    }

    func cleanupRemoteParticipant() {
        if ((self.remoteParticipant) != nil) {
            if ((self.remoteParticipant?.videoTracks.count)! > 0) {
                let remoteVideoTrack = self.remoteParticipant?.remoteVideoTracks[0].remoteTrack
                remoteVideoTrack?.removeRenderer(self.remoteView!)
                self.remoteView?.removeFromSuperview()
                self.remoteView = nil
            }
        }
        self.remoteParticipant = nil
    }

    func logMessage(messageText: String) {
        messageLabel.text = messageText
    }
}

// MARK: TVIRoomDelegate
extension ShortDistanceViewController : TVIRoomDelegate {
    func didConnect(to room: TVIRoom) {

        // At the moment, this example only supports rendering one Participant at a time.

        logMessage(messageText: "Connected to room \(room.name) as \(String(describing: room.localParticipant?.identity))")

        if (room.remoteParticipants.count > 0) {
            self.remoteParticipant = room.remoteParticipants[0]
            self.remoteParticipant?.delegate = self
        }
    }

    func room(_ room: TVIRoom, didDisconnectWithError error: Error?) {
        logMessage(messageText: "Disconncted from room \(room.name), error = \(String(describing: error))")

        self.cleanupRemoteParticipant()
        self.room = nil

        self.showRoomUI(inRoom: false)
    }

    func room(_ room: TVIRoom, didFailToConnectWithError error: Error) {
        print(error)
        logMessage(messageText: "Failed to connect to room with error")
        self.room = nil

        self.showRoomUI(inRoom: false)
    }

    func room(_ room: TVIRoom, participantDidConnect participant: TVIRemoteParticipant) {
        if (self.remoteParticipant == nil) {
            self.remoteParticipant = participant
            self.remoteParticipant?.delegate = self
        }
        logMessage(messageText: "Participant \(participant.identity) connected with \(participant.remoteAudioTracks.count) audio and \(participant.remoteVideoTracks.count) video tracks")
    }

    func room(_ room: TVIRoom, participantDidDisconnect participant: TVIRemoteParticipant) {
        if (self.remoteParticipant == participant) {
            cleanupRemoteParticipant()
        }
        logMessage(messageText: "Room \(room.name), Participant \(participant.identity) disconnected")
    }
}

// MARK: TVIRemoteParticipantDelegate
extension ShortDistanceViewController : TVIRemoteParticipantDelegate {

    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           publishedVideoTrack publication: TVIRemoteVideoTrackPublication) {

        // Remote Participant has offered to share the video Track.

        logMessage(messageText: "Participant \(participant.identity) published \(publication.trackName) video track")
    }

    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           unpublishedVideoTrack publication: TVIRemoteVideoTrackPublication) {

        // Remote Participant has stopped sharing the video Track.

        logMessage(messageText: "Participant \(participant.identity) unpublished \(publication.trackName) video track")
    }

    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           publishedAudioTrack publication: TVIRemoteAudioTrackPublication) {

        // Remote Participant has offered to share the audio Track.

        logMessage(messageText: "Participant \(participant.identity) published \(publication.trackName) audio track")
    }

    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           unpublishedAudioTrack publication: TVIRemoteAudioTrackPublication) {

        // Remote Participant has stopped sharing the audio Track.

        logMessage(messageText: "Participant \(participant.identity) unpublished \(publication.trackName) audio track")
    }

    func subscribed(to videoTrack: TVIRemoteVideoTrack,
                    publication: TVIRemoteVideoTrackPublication,
                    for participant: TVIRemoteParticipant) {

        // We are subscribed to the remote Participant's audio Track. We will start receiving the
        // remote Participant's video frames now.

        logMessage(messageText: "Subscribed to \(publication.trackName) video track for Participant \(participant.identity)")

        if (self.remoteParticipant == participant) {
            setupRemoteVideoView()
            videoTrack.addRenderer(self.remoteView!)
        }
    }

    func unsubscribed(from videoTrack: TVIRemoteVideoTrack,
                      publication: TVIRemoteVideoTrackPublication,
                      for participant: TVIRemoteParticipant) {

        // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
        // remote Participant's video.

        logMessage(messageText: "Unsubscribed from \(publication.trackName) video track for Participant \(participant.identity)")

        if (self.remoteParticipant == participant) {
            videoTrack.removeRenderer(self.remoteView!)
            self.remoteView?.removeFromSuperview()
            self.remoteView = nil
        }
    }

    func subscribed(to audioTrack: TVIRemoteAudioTrack,
                    publication: TVIRemoteAudioTrackPublication,
                    for participant: TVIRemoteParticipant) {

        // We are subscribed to the remote Participant's audio Track. We will start receiving the
        // remote Participant's audio now.

        logMessage(messageText: "Subscribed to \(publication.trackName) audio track for Participant \(participant.identity)")
    }

    func unsubscribed(from audioTrack: TVIRemoteAudioTrack,
                      publication: TVIRemoteAudioTrackPublication,
                      for participant: TVIRemoteParticipant) {

        // We are unsubscribed from the remote Participant's audio Track. We will no longer receive the
        // remote Participant's audio.

        logMessage(messageText: "Unsubscribed from \(publication.trackName) audio track for Participant \(participant.identity)")
    }

    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           enabledVideoTrack publication: TVIRemoteVideoTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) enabled \(publication.trackName) video track")
    }

    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           disabledVideoTrack publication: TVIRemoteVideoTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) disabled \(publication.trackName) video track")
    }

    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           enabledAudioTrack publication: TVIRemoteAudioTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) enabled \(publication.trackName) audio track")
    }

    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           disabledAudioTrack publication: TVIRemoteAudioTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) disabled \(publication.trackName) audio track")
    }

    func failedToSubscribe(toAudioTrack publication: TVIRemoteAudioTrackPublication,
                           error: Error,
                           for participant: TVIRemoteParticipant) {
        logMessage(messageText: "FailedToSubscribe \(publication.trackName) audio track, error = \(String(describing: error))")
    }

    func failedToSubscribe(toVideoTrack publication: TVIRemoteVideoTrackPublication,
                           error: Error,
                           for participant: TVIRemoteParticipant) {
        logMessage(messageText: "FailedToSubscribe \(publication.trackName) video track, error = \(String(describing: error))")
    }
}

// MARK: TVIVideoViewDelegate
extension ShortDistanceViewController : TVIVideoViewDelegate {
    func videoView(_ view: TVIVideoView, videoDimensionsDidChange dimensions: CMVideoDimensions) {
        self.view.setNeedsLayout()
    }
}

extension ShortDistanceViewController: dropDownProtocol {
    func dropDownPressed(mode: Mode) {
        self.dropDownButton.setTitle(mode.rawValue, for: .normal)
        self.currentMode = mode
        self.updateModeUI()
        self.dropDownButton.dismissDropDown()
    }
}

enum Mode: String{
    case home = "家中"
    case indoor = "室內"
    case outdoor = "戶外"
    case dontDisturb = "勿擾"
    case none = "請選擇符合您的情境"
}
