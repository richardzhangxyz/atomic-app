//
//  ShieldConfigurationExtension.swift
//  AtomicShieldConfiguration
//
//  Construction Zone Warning Shield - High Contrast Safety Yellow
//

import Foundation
import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Construction zone warning shield UI - safety yellow, high contrast, impossible to ignore
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    // MARK: - Mindful Reminder Library
    
    /// Title + subtitle pairs - firm but kind
    private let messageOptions: [(title: String, subtitle: String)] = [
        // Time limit messages with instruction
        ("⏱️ TIME LIMIT REACHED", "Tap below to open Atomic and unlock with intention."),
        ("✋ PAUSE.", "Your time is up. Open Atomic to proceed mindfully."),
        ("🗳️ CHOOSE.", "Small choices compound. Open Atomic to continue."),
        ("📐 SYSTEMS.", "Time's up. Open Atomic to unlock intentionally."),
        ("🔄 HABITS.", "Limit reached. Open Atomic to reflect and unlock."),
        ("🌅 FUTURE.", "Be the person your future self will thank."),
        
        // Mark Manson inspired
        ("💪 STRUGGLE.", "What you choose to struggle for defines who you are."),
        ("🚪 BOUNDARIES.", "Time's up. Open Atomic to proceed with intention."),
        ("🎯 VALUES.", "Limit reached. Open Atomic to make a conscious choice."),
        
        // Jonathan Haidt inspired
        ("🌱 GROW.", "Your best self is built through resistance, not comfort."),
        ("⚡ FRICTION.", "Growth requires friction. This moment is the work."),
        ("🏔️ CHALLENGE.", "Time limit reached. Open Atomic to continue."),
        
        // Phil Knight inspired
        ("🚀 FORWARD.", "The only way forward is through."),
        ("👟 SHOW UP.", "Show up for yourself. That's all there is."),
        ("🏃 MOVE.", "Don't stop. Don't ever stop."),
        
        // Stoic / Ryan Holiday inspired
        ("🪨 OBSTACLE.", "The obstacle is the way."),
        ("⏳ TEMPORARY.", "This discomfort is temporary. Regret lasts longer."),
        
        // Presence & mindfulness
        ("🧘 BREATHE.", "You're not avoiding the app. You're choosing your future."),
        ("💭 REFLECT.", "What would the best version of you do right now?"),
        ("🔓 FREEDOM.", "Freedom is on the other side of discipline."),
        ("✨ BECOME.", "The person you want to be is on the other side of this moment.")
    ]
    
    /// Select one message pair per presentation
    private func selectMessage(for appName: String?) -> (title: String, subtitle: String) {
        return messageOptions.randomElement() ?? messageOptions[0]
    }
    
    // MARK: - Color System
    
    // BACKGROUND: Vivid orange-yellow (more saturated to combat iOS muting)
    private var backgroundColor: UIColor {
        // Using a more saturated golden-orange that iOS may preserve better
        UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0) // #FFD900 - vivid gold
    }
    
    // PRIMARY TEXT: Pure black in light mode, Yellow in dark mode
    private var primaryTextColor: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                // Bright yellow on dark background
                return UIColor(red: 1.0, green: 0.929, blue: 0.161, alpha: 1.0) // #FFED29
            } else {
                // Pure black for maximum contrast
                return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            }
        }
    }
    
    // SECONDARY TEXT: Slightly softer
    private var secondaryTextColor: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                // Dimmer yellow on dark background
                return UIColor(red: 0.9, green: 0.836, blue: 0.145, alpha: 1.0)
            } else {
                // Dark gray for readability
                return UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
            }
        }
    }
    
    // ICON COLOR: Pure black in light mode, yellow in dark mode
    private var iconColor: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 1.0, green: 0.929, blue: 0.161, alpha: 1.0) // #FFED29
            } else {
                // Pure black
                return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            }
        }
    }
    
    // SECONDARY BUTTON TEXT
    private var secondaryButtonTextColor: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 1.0, green: 0.929, blue: 0.161, alpha: 1.0) // #FFED29
            } else {
                return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            }
        }
    }
    
    // DANGER ACCENT: Hazard Red (for "bad" unlock action)
    private let hazardRed = UIColor(red: 0.757, green: 0.071, blue: 0.122, alpha: 1.0) // #C1121F
    
    // MARK: - Shield Configuration
    
    private func createBrutalShieldConfiguration(appName: String?) -> ShieldConfiguration {
        let message = selectMessage(for: appName)
        
        return ShieldConfiguration(
            // No blur - solid background
            backgroundBlurStyle: nil,
            
            // Vivid gold background (iOS will mute it somewhat)
            backgroundColor: backgroundColor,
            
            // Icon: dark in light mode, yellow in dark mode
            icon: UIImage(systemName: "xmark.octagon.fill")?.withTintColor(iconColor, renderingMode: .alwaysOriginal),
            
            // Dynamic title with emoji
            title: ShieldConfiguration.Label(
                text: message.title,
                color: primaryTextColor
            ),
            
            // Thoughtful subtitle
            subtitle: ShieldConfiguration.Label(
                text: message.subtitle,
                color: secondaryTextColor
            ),
            
            // Primary button: Open the main app to unlock
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OPEN ATOMIC TO UNLOCK",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: hazardRed,
            
            // Secondary button: Encouraging, positive framing
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "STAY BLOCKED ✨",
                color: secondaryButtonTextColor
            )
        )
    }
    
    // MARK: - DataSource Overrides
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let appName = application.localizedDisplayName
        return createBrutalShieldConfiguration(appName: appName)
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        let appName = application.localizedDisplayName
        return createBrutalShieldConfiguration(appName: appName)
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        let domainName = webDomain.domain
        return createBrutalShieldConfiguration(appName: domainName)
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        let domainName = webDomain.domain
        return createBrutalShieldConfiguration(appName: domainName)
    }
}
