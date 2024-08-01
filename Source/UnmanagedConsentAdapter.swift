// Copyright 2024-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK

/// The Chartboost Core Unmanaged Consent Adapter allows users to manage their own CMP integration directly, instead of relying
/// on Chartboost Core and a consent adapter to manage the CMP integration for them.
///
/// The use of the Unmanaged Consent Adapter is not preferred. Use one of the public Core consent adapters instead, for a
/// streamlined integration without the need to to manage the CMP SDK yourself.
///
/// Important information regarding the Unmanaged Consent Adapter:
/// - Users are responsible for setting new consent info in the Unmanaged Consent Adapter when this info is updated by the CMP.
/// Failure to do so will result in frameworks that depend on Core for consent to have outdated consent info.
/// - Users must take care to format the consent info set in the Unmanaged Consent Adapter by using the constants defined in
/// `ConsentKeys` and `ConsentValues` when proper. For more info see the ChartboostCore SDK documentation.
/// Failure to do so will result in frameworks that depend on Core for consent to have outdated consent info.
/// - Chartboost Core SDK APIs to show consent dialogs are no-ops with this adapter.
///
/// How to use:
///
/// 1. Create an instance of this adapter and pass it in a call to initialize the ChartboostCore SDK.
///    - If you want the adapter to read and report changes to IAB strings in User Defaults automatically, pass the
///    set the `usesIABStringsFromUserDefaults` parameter to true when instantiating the adapter.
/// 2. If:
///    1. Your CMP provides more info beyond standard IAB strings or you set `usesIABStringsFromUserDefaults` to false:
///       - Observe changes to consent info through whatever mechanism your CMP SDK provides.
///         When changes are received, set the new consent info on the adapter by modifying the `consents` property.
///       - Make sure to normalize consent info before setting it into the adapter by mapping it to predefined key and
///         value constants, such as ``ConsentKeys.ccpaOptIn`` and ``ConsentValues.granted``.
///    2. Your CMP reports consent info using standard IAB strings in User Defaults and you set `usesIABStringsFromUserDefaults` to true:
///       - Nothing else is needed.
@objc(CBCUnmanagedConsentAdapter)
@objcMembers
public final class UnmanagedConsentAdapter: NSObject, ConsentAdapter {
    /// The module identifier.
    public let moduleID = "unmanaged_consent_adapter"

    /// The version of the module.
    public let moduleVersion = "1.1.0.0.0"

    /// The delegate to be notified whenever any change happens in the CMP consent info.
    /// This delegate is set by Core SDK and is an essential communication channel between Core and the CMP.
    /// Adapters should not set it themselves.
    public weak var delegate: ConsentAdapterDelegate?

    /// The observer for changes on UserDefault's consent-related keys.
    private var userDefaultsObserver: Any?

    /// A flag that indicates if the adapter observers and fetches standard IAB consent strings from the
    /// user defaults. If enabled, this info is merged with the user-provided info to obtain the final
    /// map of consents.
    ///
    /// In some cases setting this flag to true is everything that's needed to receive CMP consent info.
    /// If the CMP used provides other consent information besides standard IAB consent strings, that info
    /// will need to be explicitly set by the user.
    ///
    /// This should be set to false if the user does not want to get this automatic behavior, and instead
    /// prefers to set all the consent info explicitly themselves.
    private var usesIABStringsFromUserDefaults: Bool

    /// The custom consents map set by the publisher.
    private var customConsents: [ConsentKey: ConsentValue] = [:]

    /// Indicates whether the CMP has determined that consent should be collected from the user.
    public var shouldCollectConsent = false

    /// Current user consent info as determined by the CMP.
    ///
    /// Consent info may include IAB strings, like TCF or GPP, and parsed boolean-like signals like "CCPA Opt In Sale"
    /// and partner-specific signals.
    ///
    /// Predefined consent key constants, such as ``ConsentKeys/tcf`` and ``ConsentKeys/usp``, are provided
    /// by Core. Adapters should use them when reporting the status of a common standard.
    /// Custom keys should only be used by adapters when a corresponding constant is not provided by the Core.
    ///
    /// Predefined consent value constants are also proivded, but are only applicable to non-IAB string keys, like
    /// ``ConsentKeys/ccpaOptIn`` and ``ConsentKeys/gdprConsentGiven``.
    public var consents: [ConsentKey: ConsentValue] {
        get {
            // Merge user-provided consents with standard IAB consents in the user defaults, only if enabled.
            // Otherwise just return the user-provided consents.
            if usesIABStringsFromUserDefaults {
                userDefaultsIABStrings.merging(customConsents, uniquingKeysWith: { _, second in second })
            } else {
                customConsents
            }
        }
        set {
            // This setter is intended to be called by the user to set the consent info obtained from their CMP.
            let oldValue = customConsents
            customConsents = newValue

            // Report changes to the Core SDK
            for (key, value) in newValue where oldValue[key] != value {
                delegate?.onConsentChange(key: key)
            }
            for key in oldValue.keys where newValue[key] == nil {
                delegate?.onConsentChange(key: key)
            }
        }
    }

    // MARK: - Instantiation and Initialization

    /// Instantiates a ``UnmanagedConsentAdapter`` module which can be passed on a call to
    /// ``ChartboostCore/initializeSDK(configuration:moduleObserver:)``.
    /// - parameter usesIABStringsFromUserDefaults: Flag to enable or disable this feature.
    /// For more info see ``UnmanagedConsentAdapter/usesIABStringsFromUserDefaults``.
    public init(usesIABStringsFromUserDefaults: Bool) {
        self.usesIABStringsFromUserDefaults = usesIABStringsFromUserDefaults
        super.init()
    }

    /// The designated initializer for the module.
    /// The Chartboost Core SDK will invoke this initializer when instantiating modules defined on
    /// the dashboard through reflection.
    /// - parameter credentials: A dictionary containing all the information required to initialize
    /// this module, as defined on the Chartboost Core's dashboard.
    ///
    /// - note: Modules should not perform costly operations on this initializer.
    /// Chartboost Core SDK may instantiate and discard several instances of the same module.
    /// Chartboost Core SDK keeps strong references to modules that are successfully initialized.
    public init(credentials: [String: Any]?) {
        self.usesIABStringsFromUserDefaults = credentials?["usesIABStringsFromUserDefaults"] as? Bool ?? false
        super.init()
    }

    /// Sets up the module to make it ready to be used.
    /// - parameter configuration: A ``ModuleConfiguration`` for configuring the module.
    /// - parameter completion: A completion handler to be executed when the module is done initializing.
    /// An error should be passed if the initialization failed, whereas `nil` should be passed if it succeeded.
    public func initialize(configuration: ModuleConfiguration, completion: @escaping (Error?) -> Void) {
        // Start observing changes to IAB consent strings in user defaults, if enabled.
        if usesIABStringsFromUserDefaults {
            userDefaultsObserver = startObservingUserDefaultsIABStrings()
        }

        // Always succeed, since we don't manage CMP initialization there's nothing to do here.
        completion(nil)
    }

    // MARK: - Consent

    /// Informs the CMP that the user has granted consent.
    /// This method should be used only when a custom consent dialog is presented to the user, thereby making the publisher
    /// responsible for the UI-side of collecting consent. In most cases ``showConsentDialog(_:from:completion:)`` should
    /// be used instead.
    /// If the CMP does not support custom consent dialogs or the operation fails for any other reason, the completion
    /// handler is executed with a `false` parameter.
    /// - parameter source: The source of the new consent. See the ``ConsentSource`` documentation for more info.
    /// - parameter completion: Handler called to indicate if the operation went through successfully or not.
    public func grantConsent(source: ConsentSource, completion: @escaping (_ succeeded: Bool) -> Void) {
        // No-op. Users should call their CMP SDK methods directly instead of going through the Chartboost Core SDK.
        completion(false)
    }

    /// Informs the CMP that the user has denied consent.
    /// This method should be used only when a custom consent dialog is presented to the user, thereby making the publisher
    /// responsible for the UI-side of collecting consent. In most cases ``showConsentDialog(_:from:completion:)``should
    /// be used instead.
    /// If the CMP does not support custom consent dialogs or the operation fails for any other reason, the completion
    /// handler is executed with a `false` parameter.
    /// - parameter source: The source of the new consent. See the ``ConsentSource`` documentation for more info.
    /// - parameter completion: Handler called to indicate if the operation went through successfully or not.
    public func denyConsent(source: ConsentSource, completion: @escaping (_ succeeded: Bool) -> Void) {
        // No-op. Users should call their CMP SDK methods directly instead of going through the Chartboost Core SDK.
        completion(false)
    }

    /// Informs the CMP that the given consent should be reset.
    /// If the CMP does not support the `reset()` function or the operation fails for any other reason, the completion
    /// handler is executed with a `false` parameter.
    /// - parameter completion: Handler called to indicate if the operation went through successfully or not.
    public func resetConsent(completion: @escaping (_ succeeded: Bool) -> Void) {
        // No-op. Users should call their CMP SDK methods directly instead of going through the Chartboost Core SDK.
        completion(false)
    }

    /// Instructs the CMP to present a consent dialog to the user for the purpose of collecting consent.
    /// - parameter type: The type of consent dialog to present. See the ``ConsentDialogType`` documentation for more info.
    /// If the CMP does not support a given type, it should default to whatever type it does support.
    /// - parameter viewController: The view controller to present the consent dialog from.
    /// - parameter completion: This handler is called to indicate whether the consent dialog was successfully presented or not.
    /// Note that this is called at the moment the dialog is presented, **not when it is dismissed**.
    public func showConsentDialog(
        _ type: ConsentDialogType,
        from viewController: UIViewController,
        completion: @escaping (_ succeeded: Bool) -> Void
    ) {
        // No-op. Users should call their CMP SDK methods directly instead of going through the Chartboost Core SDK.
        completion(false)
    }
}
