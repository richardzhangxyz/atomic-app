//
//  ShieldConfigurationExtension.swift
//  AtomicShieldConfiguration
//
//  Custom shield configuration for blocked apps
//

import Foundation
import ManagedSettings
import ManagedSettingsUI
import UIKit

/// This extension provides custom shield UI when blocked apps are opened
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Read attempt count from App Group
        let defaults = UserDefaults(suiteName: "group.com.01labs.kaizen")
        let attemptCount = defaults?.integer(forKey: "attemptCount") ?? 1
        
        // Increment attempt count for next time
        defaults?.set(attemptCount + 1, forKey: "attemptCount")
        
        // Get app name if available
        let appName = application.localizedDisplayName ?? "this app"
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(red: 0.95, green: 0.94, blue: 0.98, alpha: 1.0),
            icon: UIImage(systemName: "leaf.fill"),
            title: ShieldConfiguration.Label(
                text: "Quick pause.",
                color: UIColor(red: 0.4, green: 0.3, blue: 0.6, alpha: 1.0)
            ),
            subtitle: ShieldConfiguration.Label(
                text: attemptCount > 1 
                    ? "You've tried to open \(appName) \(attemptCount) times. Take a moment to reflect."
                    : "You've reached your limit for \(appName). Want to continue mindfully?",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Reflect & Unlock",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.5, green: 0.4, blue: 0.7, alpha: 1.0),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: UIColor.secondaryLabel
            )
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        // Same configuration for category-based shields
        return configuration(shielding: application)
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        let domainName = webDomain.domain ?? "this website"
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(red: 0.95, green: 0.94, blue: 0.98, alpha: 1.0),
            icon: UIImage(systemName: "leaf.fill"),
            title: ShieldConfiguration.Label(
                text: "Quick pause.",
                color: UIColor(red: 0.4, green: 0.3, blue: 0.6, alpha: 1.0)
            ),
            subtitle: ShieldConfiguration.Label(
                text: "You've reached your limit for \(domainName). Want to continue mindfully?",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Reflect & Unlock",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.5, green: 0.4, blue: 0.7, alpha: 1.0),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: UIColor.secondaryLabel
            )
        )
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return configuration(shielding: webDomain)
    }
}
