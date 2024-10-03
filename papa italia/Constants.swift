//
//  Constants.swift
//  papa italia
//
//  Created by Hameed Dahabry on 28/09/2024.
//

import Foundation

class Constants {
    static var selectedLangauge: String {
        set {
            UserDefaults.standard.setValue(newValue, forKey: "lan")
            UserDefaults.standard.set([newValue], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
        get {
            let locale = NSLocale.current.language.languageCode?.identifier
            return UserDefaults.standard.string(forKey: "lan") ?? locale?.lowercased() ?? "ar"
        }
    }
    
    static var cancelTitle: String {
        if Constants.selectedLangauge == "he" {
            "ביטול"
        }else {
            "الغاء"
        }
    }
    
    static var reloadTitle: String {
        if Constants.selectedLangauge == "he" {
            "נסה שוב"
        }else {
            "اعادة المحاولة"
        }
    }
}

enum Languages: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    
    case ar
    case he
    
    var displayName: String {
        switch self {
        case .ar:
            "عربي"
        case .he:
            "עברית"
        }
    }
}

