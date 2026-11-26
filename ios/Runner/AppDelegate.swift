import UIKit
import Flutter
import Firebase
import Contacts
import ContactsUI

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "Dx5veContacts") {
      ContactsChannel.shared.register(messenger: registrar.messenger())
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// Hands a scanned delegate to the system "New Contact" sheet, pre-filled, for
/// the user to confirm with Done. Same channel and method as Android's
/// MainActivity, so the Dart side has one code path.
///
/// Replaces flutter_contacts' insert, which requests access and inserts on a
/// background queue and replies to Flutter from there: on current Flutter the
/// call could hang (Save button stuck, no toast) or crash the app.
final class ContactsChannel: NSObject, CNContactViewControllerDelegate {
  static let shared = ContactsChannel()

  func register(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "dx5ve/contacts", binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        guard call.method == "insertViaContactsApp",
              let args = call.arguments as? [String: Any] else {
          result(FlutterMethodNotImplemented)
          return
        }
        // Method calls arrive on the main thread; reply right away so Dart
        // never waits on the user finishing the sheet.
        result(self?.open(args) ?? false)
      }
  }

  private func open(_ args: [String: Any]) -> Bool {
    guard topViewController() != nil else { return false }
    let contact = makeContact(args)
    // Ask once if we never have; the sheet opens whatever the answer.
    if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
      CNContactStore().requestAccess(for: .contacts) { [weak self] _, _ in
        DispatchQueue.main.async { self?.present(contact) }
      }
    } else {
      present(contact)
    }
    return true
  }

  private func makeContact(_ args: [String: Any]) -> CNMutableContact {
    func s(_ key: String) -> String {
      ((args[key] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    let c = CNMutableContact()
    c.givenName = s("firstName")
    c.familyName = s("lastName")
    c.organizationName = s("company")
    c.jobTitle = s("role")
    if !s("phone").isEmpty {
      c.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile,
                                       value: CNPhoneNumber(stringValue: s("phone")))]
    }
    if !s("email").isEmpty {
      c.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: s("email") as NSString)]
    }
    return c
  }

  private func present(_ contact: CNMutableContact) {
    guard let top = topViewController() else { return }
    let vc = CNContactViewController(forNewContact: contact)
    vc.contactStore = CNContactStore()
    vc.delegate = self
    top.present(UINavigationController(rootViewController: vc), animated: true)
  }

  func contactViewController(_ viewController: CNContactViewController,
                             didCompleteWith contact: CNContact?) {
    (viewController.navigationController ?? viewController).dismiss(animated: true)
  }

  private func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow } ?? (UIApplication.shared.delegate?.window ?? nil)
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }
}
