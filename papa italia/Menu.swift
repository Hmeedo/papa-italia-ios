//
//  Menu.swift
//  papa italia
//
//  Created by Hameed Dahabry on 27/09/2024.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseStorage
import SwiftUI

struct MenuItem: Codable, Identifiable {
    @DocumentID var id: String?
    let name_ar: String?
    let name_he: String?
    let group_ar: String?
    let group_he: String?
    let info_ar: String?
    let info_he: String?
    let price: Int?
    let index: Int?
}

extension MenuItem {
    private var lan: String {
        Constants.selectedLangauge
    }
    var name: String {
        if lan == "ar" {
            name_ar ?? ""
        }else {
            name_he ?? ""
        }
    }
    
    var info: String {
        if lan == "ar" {
            info_ar ?? ""
        }else {
            info_he ?? ""
        }
    }
    
    var group: String {
        if lan == "ar" {
            group_ar ?? ""
        }else {
            group_he ?? ""
        }
    }
    
    var priceString: String {
        if price == 0 || price == nil {
            lan == "ar" ? "مجاناً" : "חינם"
        }else {
            "\(price!) ₪"
        }
    }
    
    private var imageReference : StorageReference {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imagesRef = storageRef.child("\(id!).png")
        return imagesRef
    }
    
    
    func getCachedImage() async -> UIImage? {
        guard let data = imageReference.cachedData(), let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    
    func getImage() async throws -> UIImage {
        guard let data = try await imageReference.data(), let image = UIImage(data: data) else {
            throw ImageError.invalidData
        }
        return image
    }
}

enum ImageError: Error {
    case invalidData
    case invalidURL
}

extension StorageReference {
    //one cache policy we support load local else data
    func data() async throws -> Data? {
        guard let metadata = try? await self.getMetadata() else {
            // if we can't load data then we return cached data
           return cachedData()
        }
        if let localCacheDate = metadataDate(),
           let remoteDate = metadata.updated ?? metadata.timeCreated,
            localCacheDate == remoteDate,
            let data = cachedData() {
            return data
        }else {
            let data = try await self.data(maxSize: 5 * 1024 * 1024)
            saveMetadataDate(metadata.updated ?? Date())
            let _ = cacheData(data)
            return data
        }
    }

    
    private func cacheData(_ data: Data) {
        let _ = writeToTempFile(data: data, fileName: name)
    }
    
    func cachedData() -> Data? {
        readFromTempFile(fileName: name)
    }
    
    private func saveMetadataDate(_ date : Date) {
        let string = date.timeIntervalSince1970
        guard let data = string.description.data(using: .utf8) else { return }
        let _ = writeToTempFile(data: data, fileName: "\(self.name)metadata")
    }
    
    private func metadataDate() -> Date? {
        guard let data = readFromTempFile(fileName: "\(self.name)metadata"),
        let string = String.init(data: data, encoding: .utf8),
              let ts = TimeInterval(string) else {
            return nil
        }
        return Date(timeIntervalSince1970: ts)
    }
    
    private func writeToTempFile(data: Data, fileName: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            print("File written to: \(fileURL.path)")
            return fileURL
        } catch {
            print("Error writing file: \(error)")
            return nil
        }
    }

    private  func readFromTempFile(fileName: String) -> Data? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            let data = try Data(contentsOf: fileURL)
            //print("File read from: \(fileURL.path)")
            return data
        } catch {
           // print("Error reading file: \(error)")
            return nil
        }
    }
}

struct FontModifier: ViewModifier, Animatable {
    private let fontSizeBegin: CGFloat
    private let fontsizeEnd: CGFloat
    private var progress: CGFloat

    init(fontSizeBegin: CGFloat = 20, fontsizeEnd: CGFloat = 100, progress: CGFloat) {
        self.fontSizeBegin = fontSizeBegin
        self.fontsizeEnd = fontsizeEnd
        self.progress = progress
    }

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    private var font: Font {
        let size = fontSizeBegin + ((fontsizeEnd - fontSizeBegin) * (progress / 100))
        return .system(size: size)
    }

    func body(content: Content) -> some View {
        content
            .font(font)
            .bold()
    }
}


