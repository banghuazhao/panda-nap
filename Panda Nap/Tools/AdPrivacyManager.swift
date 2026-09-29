#if !targetEnvironment(macCatalyst)
import AppTrackingTransparency
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

extension Notification.Name {
    static let adPrivacyDidChange = Notification.Name("adPrivacyDidChange")
}

/// The only place that combines UMP and ATT before an ad request is made.
final class AdPrivacyManager {
    static let shared = AdPrivacyManager()

    private enum AdServingMode {
        case blocked
        case nonPersonalized
        case personalized
    }

    private let advertisingOptOutKey = "PANDA_ADVERTISING_OPT_OUT"
    private let consent = ConsentInformation.shared
    private var updateStarted = false
    private var consentResolved = false
    private var consentUpdateSucceeded = false
    private var adsStarted = false
    private var lastNotifiedMode: AdServingMode?
    private var applicationActiveObserver: NSObjectProtocol?
    private(set) var revision = 0

    private init() {}

    var canRequestAds: Bool {
        adServingMode != .blocked
    }

    var advertisingOptedOut: Bool {
        UserDefaults.standard.bool(forKey: advertisingOptOutKey)
    }

    var privacyOptionsRequired: Bool {
        consent.privacyOptionsRequirementStatus == .required
    }

    var canPresentPrivacyOptions: Bool {
        privacyOptionsRequired && !trackingPermissionDenied
    }

    var trackingPermissionDenied: Bool {
        guard #available(iOS 14, *) else { return false }
        let status = ATTrackingManager.trackingAuthorizationStatus
        return status == .denied || status == .restricted
    }

    var adsBlockedByRegionalPrivacy: Bool {
        trackingPermissionDenied && privacyOptionsRequired
    }

    func stopAds() {
        guard !advertisingOptedOut else { return }
        UserDefaults.standard.set(true, forKey: advertisingOptOutKey)
        MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState = .disabled
        notifyObservers()
    }

    func start(from controller: UIViewController) {
        guard !updateStarted else { return }
        updateStarted = true
        applicationActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self, self.consentResolved,
                  self.adServingMode != self.lastNotifiedMode else { return }
            self.notifyObservers()
        }
        consent.requestConsentInfoUpdate(with: RequestParameters()) { [weak self, weak controller] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.consentUpdateSucceeded = error == nil
                if error != nil || self.trackingPermissionDenied {
                    self.finishConsentResolution()
                    return
                }
                ConsentForm.loadAndPresentIfRequired(from: controller) { [weak self] formError in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        if formError != nil {
                            self.consentUpdateSucceeded = false
                            self.finishConsentResolution()
                        } else {
                            self.requestTrackingIfAppropriate(from: controller)
                        }
                    }
                }
            }
        }
    }

    func presentPrivacyOptions(from controller: UIViewController) {
        guard canPresentPrivacyOptions else { return }
        consentResolved = false
        notifyObservers()
        ConsentForm.presentPrivacyOptionsForm(from: controller) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                if error != nil { self.consentUpdateSucceeded = false }
                self.finishConsentResolution()
            }
        }
    }

    func adRequest() -> Request? {
        let mode = adServingMode
        guard mode != .blocked else { return nil }
        MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState =
            mode == .personalized ? .default : .disabled
        let request = Request()
        if mode != .personalized {
            let extras = Extras()
            extras.additionalParameters = ["npa": "1"]
            request.register(extras)
        }
        return request
    }

    private var adServingMode: AdServingMode {
        guard consentResolved, consentUpdateSucceeded, consent.canRequestAds,
              !advertisingOptedOut else { return .blocked }
        // The published European UMP form asks about personalized advertising.
        // Do not request even nonpersonalized ads after an ATT denial while that
        // regional privacy choice is required, including with older UMP consent.
        if adsBlockedByRegionalPrivacy { return .blocked }
        guard #available(iOS 14, *),
              ATTrackingManager.trackingAuthorizationStatus == .authorized,
              umpAllowsPersonalization else { return .nonPersonalized }
        return .personalized
    }

    private var umpAllowsPersonalization: Bool {
        guard consent.canRequestAds else { return false }
        if consent.consentStatus == .notRequired { return true }
        guard consent.consentStatus == .obtained,
              let purposes = UserDefaults.standard.string(forKey: "IABTCF_PurposeConsents"),
              purposes.count >= 4 else { return false }
        let flags = Array(purposes)
        return flags[0] == "1" && flags[2] == "1" && flags[3] == "1"
    }

    private func requestTrackingIfAppropriate(from controller: UIViewController?) {
        guard #available(iOS 14, *),
              ATTrackingManager.trackingAuthorizationStatus == .notDetermined,
              umpAllowsPersonalization,
              UIApplication.shared.applicationState == .active,
              controller?.viewIfLoaded?.window != nil else {
            finishConsentResolution()
            return
        }
        ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
            DispatchQueue.main.async { self?.finishConsentResolution() }
        }
    }

    private func finishConsentResolution() {
        consentResolved = true
        if canRequestAds && !adsStarted {
            adsStarted = true
            MobileAds.shared.requestConfiguration.maxAdContentRating = GADMaxAdContentRating.general
            MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .unspecified
            MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState =
                adServingMode == .personalized ? .default : .disabled
            MobileAds.shared.start { _ in }
        }
        notifyObservers()
    }

    private func notifyObservers() {
        let mode = adServingMode
        if mode != .personalized {
            MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState = .disabled
        }
        lastNotifiedMode = mode
        revision += 1
        NotificationCenter.default.post(name: .adPrivacyDidChange, object: nil)
    }
}
#endif
