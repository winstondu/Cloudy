// Copyright (c) 2020 Nomad5. All rights reserved.

import Foundation
import UIKit

/// Container for address bar updates
struct AddressBarInfo {
    let url:          String?
    let canGoBack:    Bool
    let canGoForward: Bool
}

/// Abstraction for controlling the menu
protocol MenuController {
    func updateAddressBar(with info: AddressBarInfo)
    func show()
}

/// Overlay controller
protocol OverlayController {
    func showOverlay(for address: String?)
}

/// View controller to handle everything on the menu screen
/// (after pressed the menu button)
class MenuViewController: UIViewController {

    /// View references
    @IBOutlet var shadowViews: [UIView]!
    @IBOutlet weak var userAgentTextField:         UITextField!
    @IBOutlet weak var manualUserAgent:            UISwitch!
    @IBOutlet weak var addressBar:                 UITextField!
    @IBOutlet weak var backButton:                 UIButton!
    @IBOutlet weak var forwardButton:              UIButton!
    @IBOutlet weak var buttonGeforceNow:           UIImageView!
    @IBOutlet weak var buttonGeforceNowBeta:       UIImageView!
    @IBOutlet weak var buttonStadia:               UIImageView!
    @IBOutlet weak var buttonLuna:                 UIImageView!
    @IBOutlet weak var buttonBoosteroid:           UIImageView!
    @IBOutlet weak var buttonGamepadTester:        UIImageView!
    @IBOutlet weak var buttonPatreon:              UIImageView!
    @IBOutlet weak var buttonPayPal:               UIImageView!
    @IBOutlet weak var allowInlineFeedback:        UISwitch!
    @IBOutlet weak var standaloneSwitch:           UISwitch!
    @IBOutlet weak var controllerHackSwitch:       UISwitch!
    @IBOutlet weak var controllerIdSelector:       UISegmentedControl!
    @IBOutlet weak var onScreenControllerSelector: UISegmentedControl!
    @IBOutlet weak var touchFeedbackSelector:      UISegmentedControl!
    @IBOutlet weak var customJsInjection:          UITextField!
    @IBOutlet weak var scalingFactorTextField:     UITextField!
    @IBOutlet weak var versionLabel:               UILabel!

    /// Some injections
    var webController:      WebController?
    var overlayController:  OverlayController?
    var menuActionsHandler: MenuActionsHandler?

    /// By default hide the status bar
    override var prefersStatusBarHidden: Bool {
        true
    }

    /// View is ready to be configured
    override func viewDidLoad() {
        super.viewDidLoad()
        // tap to close
        let tap = UITapGestureRecognizer(target: self, action: #selector(onOverlayClosePressed))
        view.addGestureRecognizer(tap)
        // tap for stadia button
        let tapStadia = UITapGestureRecognizer(target: self, action: #selector(onStadiaButtonPressed))
        buttonStadia.addGestureRecognizer(tapStadia)
        // tap for geforce now button
        let tapGeforceNow = UITapGestureRecognizer(target: self, action: #selector(onGeforceNowButtonPressed))
        buttonGeforceNow.addGestureRecognizer(tapGeforceNow)
        // tap for geforce now beta button
        let tapGeforceNowBeta = UITapGestureRecognizer(target: self, action: #selector(onGeforceNowBetaButtonPressed))
        buttonGeforceNowBeta.addGestureRecognizer(tapGeforceNowBeta)
        // tap for boosteroid button
        let tapBoosteroid = UITapGestureRecognizer(target: self, action: #selector(onBoosteroidButtonPressed))
        buttonBoosteroid.addGestureRecognizer(tapBoosteroid)
        // tap for luna button
        let tapLuna = UITapGestureRecognizer(target: self, action: #selector(onLunaButtonPressed))
        buttonLuna.addGestureRecognizer(tapLuna)
        // tap for gamepad tester button
        let tapGamepadTester = UITapGestureRecognizer(target: self, action: #selector(onGamepadTesterButtonPressed))
        buttonGamepadTester.addGestureRecognizer(tapGamepadTester)
        // tap for patreon button
        let tapPatreon = UITapGestureRecognizer(target: self, action: #selector(onPatreonButtonPressed))
        buttonPatreon.addGestureRecognizer(tapPatreon)
        // tap for pay pal button
        let tapPayPal = UITapGestureRecognizer(target: self, action: #selector(onPayPalButtonPressed))
        buttonPayPal.addGestureRecognizer(tapPayPal)
        // init
        userAgentTextField.text = UserDefaults.standard.manualUserAgent
        manualUserAgent.isOn = UserDefaults.standard.useManualUserAgent
        allowInlineFeedback.isOn = UserDefaults.standard.allowInlineMedia
        standaloneSwitch.isOn = UserDefaults.standard.actAsStandaloneApp
        controllerHackSwitch.isOn = UserDefaults.standard.injectControllerScripts
        controllerIdSelector.selectedSegmentIndex = UserDefaults.standard.controllerId.rawValue
        onScreenControllerSelector.selectedSegmentIndex = UserDefaults.standard.onScreenControlsLevel.rawValue
        touchFeedbackSelector.selectedSegmentIndex = UserDefaults.standard.touchFeedbackType.rawValue
        customJsInjection.text = UserDefaults.standard.customJsCodeToInject
        scalingFactorTextField.text = String(UserDefaults.standard.webViewScale)
        // apply shadows
        shadowViews.forEach { $0.addShadow() }
        // update stuff
        updateVersionLabel()
    }

    /// Set version to label
    private func updateVersionLabel() {
        guard let versionNumber = Bundle.main.releaseVersionNumber,
              let buildNumber = Bundle.main.buildVersionNumber else {
            Log.e("Invalid version and build number")
            versionLabel.text = "invalid"
            return
        }
        versionLabel.text = "Cloudy v\(versionNumber)(\(buildNumber))"
    }
}

/// Implementing controlling protocol
extension MenuViewController: MenuController {

    /// Update address bar elements
    func updateAddressBar(with info: AddressBarInfo) {
        addressBar.text = info.url
        backButton.isEnabled = info.canGoBack
        forwardButton.isEnabled = info.canGoForward
    }

    /// Fade in
    func show() {
        view.fadeIn()
    }
}

/// UI handling extension
extension MenuViewController {

    /// Hide menu and keyboard
    func hideMenu() {
        view.fadeOut()
        addressBar.resignFirstResponder()
    }

    /// Forward
    @IBAction func onForwardPressed(_ sender: Any) {
        webController?.executeNavigation(action: .forward)
        hideMenu()
    }

    /// Go backward
    @IBAction func onBackPressed(_ sender: Any) {
        webController?.executeNavigation(action: .backward)
        hideMenu()
    }

    /// Navigate to a url
    @IBAction func onGoPressed(_ sender: Any) {
        // early exit
        guard let address = addressBar.text else { return }
        webController?.navigateTo(address: address)
        hideMenu()
    }

    /// Reload current page
    @IBAction func onReloadPressed(_ sender: Any) {
        webController?.executeNavigation(action: .reload)
        hideMenu()
    }

    /// Clear address bar pressed
    @IBAction func onClearPressed(_ sender: Any) {
        addressBar.text = ""
        addressBar.becomeFirstResponder()
    }

    /// Delete cache pressed
    @IBAction func onResetCacheAndCookiesPressed(_ sender: Any) {
        webController?.clearCache()
    }

    /// Manual user agent changed
    @IBAction func onManualUserAgentSwitchChanged(_ sender: Any) {
        UserDefaults.standard.useManualUserAgent = manualUserAgent.isOn
    }

    /// Allow inline media changed
    @IBAction func allowInlineMediaValueChanged(_ sender: Any) {
        UserDefaults.standard.allowInlineMedia = allowInlineFeedback.isOn
    }

    /// Change standalone behavior
    @IBAction func onStandaloneValueChanged(_ sender: Any) {
        UserDefaults.standard.actAsStandaloneApp = standaloneSwitch.isOn
    }

    /// Change controller hack injection behavior
    @IBAction func onControllerHacksValueChanged(_ sender: Any) {
        UserDefaults.standard.injectControllerScripts = controllerHackSwitch.isOn
    }

    /// User agent value changed
    @IBAction func onUserAgentValueChanged(_ sender: Any) {
        UserDefaults.standard.manualUserAgent = userAgentTextField.text
    }

    /// Handle click outside of any element
    @objc func onOverlayClosePressed(_ sender: Any) {
        hideMenu()
    }

    /// Handle stadia shortcut
    @objc func onStadiaButtonPressed(_ sender: Any) {
        webController?.navigateTo(address: Navigator.Config.Url.googleStadia.absoluteString)
        hideMenu()
    }

    /// Handle geforce now shortcut
    @objc func onGeforceNowButtonPressed(_ sender: Any) {
        webController?.navigateTo(address: Navigator.Config.Url.geforceNowOld.absoluteString)
        hideMenu()
    }

    /// Handle geforce now beta shortcut
    @objc func onGeforceNowBetaButtonPressed(_ sender: Any) {
        webController?.navigateTo(address: Navigator.Config.Url.geforceNowBeta.absoluteString)
        hideMenu()
    }

    /// Handle luna shortcut
    @objc func onLunaButtonPressed(_ sender: Any) {
        webController?.navigateTo(address: Navigator.Config.Url.amazonLuna.absoluteString)
        hideMenu()
    }

    /// Handle boosteroid shortcut
    @objc func onBoosteroidButtonPressed(_ sender: Any) {
        webController?.navigateTo(address: Navigator.Config.Url.boosteroid.absoluteString)
        hideMenu()
    }

    /// Handle gamepad tester shortcut
    @objc func onGamepadTesterButtonPressed(_ sender: Any) {
        webController?.navigateTo(address: Navigator.Config.Url.gamepadTester.absoluteString)
        hideMenu()
    }

    /// Handle patreon shortcut
    @objc func onPatreonButtonPressed(_ sender: Any) {
        overlayController?.showOverlay(for: Navigator.Config.Url.patreon.absoluteString)
        hideMenu()
    }

    /// Handle paypal shortcut
    @objc func onPayPalButtonPressed(_ sender: Any) {
        overlayController?.showOverlay(for: Navigator.Config.Url.paypal.absoluteString)
        hideMenu()
    }

    /// Controller ID changed in menu
    @IBAction func onControllerIdChanged(_ sender: Any) {
        guard let newId = GCExtendedGamepad.id(rawValue: controllerIdSelector.selectedSegmentIndex) else {
            Log.e("Something went wrong parsing the selected controller ID: \(onScreenControllerSelector.selectedSegmentIndex)")
            return
        }
        UserDefaults.standard.controllerId = newId
    }

    /// On screen controls value changed in menu
    @IBAction func onOnScreenControlChanged(_ sender: Any) {
        guard let newLevel = OnScreenControlsLevel(rawValue: onScreenControllerSelector.selectedSegmentIndex) else {
            Log.e("Something went wrong parsing the selected on screen controls level: \(onScreenControllerSelector.selectedSegmentIndex)")
            return
        }
        UserDefaults.standard.onScreenControlsLevel = newLevel
        menuActionsHandler?.updateOnScreenController(with: newLevel)
    }

    /// Touch feedback selector changed
    @IBAction func onTouchFeedbackChanged(_ sender: Any) {
        guard let newFeedbackType = TouchFeedbackType(rawValue: touchFeedbackSelector.selectedSegmentIndex) else {
            Log.e("Something went wrong parsing the selected touch feedback type: \(touchFeedbackSelector.selectedSegmentIndex)")
            return
        }
        UserDefaults.standard.touchFeedbackType = newFeedbackType
        menuActionsHandler?.updateTouchFeedbackType(with: newFeedbackType)
    }

    /// Custom js code injection changed
    @IBAction func onCustomJsInjectCodeChanged(_ sender: Any) {
        UserDefaults.standard.customJsCodeToInject = customJsInjection.text
    }

    /// Inject custom code
    @IBAction func onInjectCustomCodePressed(_ sender: Any) {
        guard let code = customJsInjection.text,
              !code.isEmpty else {
            return
        }
        menuActionsHandler?.injectCustom(code: code)
    }

    /// Scaling changed
    @IBAction func onScalingFactorChanged(_ sender: Any) {
        guard let text = scalingFactorTextField.text,
              let factor = Int(text) else {
            Log.e("Something went wrong parsing the scaling factor: \(scalingFactorTextField.text ?? "nil")")
            return
        }
        UserDefaults.standard.webViewScale = -factor
        menuActionsHandler?.updateScalingFactor(with: -factor)
    }
}
