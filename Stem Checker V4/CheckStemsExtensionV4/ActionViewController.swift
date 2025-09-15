//
//  ActionViewController.swift
//  CheckStemsExtensionV4
//
//  Created by James Ryan Wilkins on 12/09/2025.
//

import Cocoa
import UniformTypeIdentifiers

class ActionViewController: NSViewController {

    private let confirmationLabel = NSTextField(labelWithString: "")
    private let openButton = NSButton(title: "Open", target: nil, action: nil)
    private let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)

    override func loadView() {
        self.view = NSView()

        // Configure the view
        self.view.frame.size = NSSize(width: 300, height: 120)

        // Configure the label
        let fileCount = self.extensionContext?.inputItems.count ?? 0
        let pluralS = fileCount == 1 ? "" : "s"
        confirmationLabel.stringValue = "Open \(fileCount) stem\(pluralS) with Stem Checker V4?"
        confirmationLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        confirmationLabel.alignment = .center
        confirmationLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(confirmationLabel)

        // Configure the Open button
        openButton.bezelStyle = .rounded
        openButton.keyEquivalent = "\r" // Allows pressing Enter to trigger it
        openButton.target = self
        openButton.action = #selector(send(_:))
        openButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(openButton)
        
        // Configure the Cancel button
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancel(_:))
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(cancelButton)

        // Set up constraints
        NSLayoutConstraint.activate([
            confirmationLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 20),
            confirmationLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            confirmationLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            
            cancelButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20),
            cancelButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: 80),
            
            openButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20),
            openButton.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -10),
            openButton.widthAnchor.constraint(equalToConstant: 80)
        ])
    }

    @IBAction func send(_ sender: AnyObject?) {
        guard let extensionItems = self.extensionContext?.inputItems as? [NSExtensionItem] else { return }
        var collectedURLs: [URL] = []
        let group = DispatchGroup()

        for item in extensionItems {
            if let attachments = item.attachments {
                for provider in attachments {
                    for typeId in provider.registeredTypeIdentifiers {
                        NSLog("Checking type: \(typeId)")
                        if provider.hasItemConformingToTypeIdentifier(typeId) {
                            group.enter()
                            provider.loadItem(forTypeIdentifier: typeId, options: nil) { (data, error) in
                                defer { group.leave() }
                                if let url = data as? URL {
                                    if url.startAccessingSecurityScopedResource() {
                                        NSLog("Got usable URL: \(url.path)")
                                        collectedURLs.append(url)
                                        url.stopAccessingSecurityScopedResource()
                                    } else {
                                        NSLog("Failed to access security-scoped resource: \(url)")
                                    }
                                } else if let nsData = data as? NSData,
                                          let url = NSURL(dataRepresentation: nsData as Data,
                                                          relativeTo: nil) as? URL {
                                    if url.startAccessingSecurityScopedResource() {
                                        NSLog("Got usable URL from NSData: \(url.path)")
                                        collectedURLs.append(url)
                                        url.stopAccessingSecurityScopedResource()
                                    } else {
                                         NSLog("Failed to access security-scoped resource from NSData: \(url)")
                                    }
                                } else {
                                    NSLog("Attachment for \(typeId) was not a URL. Got: \(String(describing: data))")
                                }
                            }
                        }
                    }
                }
            }
        }

        group.notify(queue: .main) {
            NSLog("Retrieved URLs: \(collectedURLs)")

            // --- Launch the main application ---
            // NOTE: This will fail until we add the correct entitlements.
            if !collectedURLs.isEmpty {
                // Find the main app using its bundle identifier
                let mainAppIdentifier = "com.example.Stem-Checker-V4"
                let mainAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: mainAppIdentifier)

                if let url = mainAppURL {
                    NSLog("Resolved main app URL: \(url.path)")
                    let configuration = NSWorkspace.OpenConfiguration()
                    NSWorkspace.shared.open(collectedURLs, withApplicationAt: url, configuration: configuration) { _, error in
                        if let error = error {
                            NSLog("Error launching main app: \(error.localizedDescription)")
                        } else {
                            NSLog("Successfully asked macOS to open files in main app.")
                        }
                    }
                } else {
                    NSLog("Could not find the main application with bundle identifier: \(mainAppIdentifier)")
                }
            }
            
            // Preserve originals instead of replacing them with nothing
            if let items = self.extensionContext?.inputItems {
                self.extensionContext?.completeRequest(returningItems: items, completionHandler: nil)
            } else {
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        }
    }

    @IBAction func cancel(_ sender: AnyObject?) {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        self.extensionContext!.cancelRequest(withError: cancelError)
    }

}
