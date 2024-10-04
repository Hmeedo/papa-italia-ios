//
//  MenuViewModel.swift
//  papa italia
//
//  Created by Hameed Dahabry on 04/10/2024.
//

import SwiftUI
import FirebaseFirestore
class MenuViewModel: ObservableObject {
    @Published var selectedItem: MenuItem?
    @Published var showActionSheet = false
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    @Published var items: [MenuItem] = []
    @Published var meals: [String : [MenuItem]] = [:]
    @Published var selectedLanguage: Languages = Languages(rawValue: Constants.selectedLangauge) ?? .ar  {
        didSet {
            Constants.selectedLangauge = selectedLanguage.rawValue
            let _ = objectWillChange
        }
    }
    
    func reload() {
        error = nil
        Task {
            await loadData()
        }
    }
    
    @MainActor
    func loadData() async {
        isLoading = true
        let db = Firestore.firestore()
        let collection = db.collection("Menu")
        do {
            let snapshot = try await collection.getDocuments()
            items = try snapshot.documents.map({ try $0.data(as: MenuItem.self) }).sorted(by: { $0.index ?? 0 < $1.index ?? 0})
            isLoading = false
        }
        catch {
            self.error = error
            isLoading = false
        }
    }
    
    @MainActor
    func loadMeals(for item: String) async {
        let db = Firestore.firestore()
        let collection = db.collection("Menu").document(item).collection("Meals")
        do {
            let snapshot = try await collection.getDocuments()
            let items = try snapshot.documents.map({ try $0.data(as: MenuItem.self) })
            meals[item] = items.sorted(by: { $0.price ?? 0 > $1.price ?? 0}).sorted(by: { $0.group < $1.group }).sorted(by: { $0.index ?? 0 < $1.index ?? 0})
        }
        catch {
            print(error)
        }
    }
    
    func fillData() async throws {
        let db = Firestore.firestore()
        
        if let url = Bundle.main.url(forResource: "data", withExtension: "json") {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
            for object in json ?? [] {
                var newObject = object
                if newObject["price"] == nil {
                    newObject["price"] = 0
                }
//                if newObject["index"] == nil {
//                    newObject["index"] = 0
//                }
//                if newObject["group_ar"] == nil {
//                    newObject["group_ar"] = ""
//                }
//                if newObject["group_he"] == nil {
//                    newObject["group_he"] = ""
//                }
                
                let meals = newObject["Meals"] as? [[String: Any]] ?? []
                newObject.removeValue(forKey: "Meals")
                if let id = newObject["id"]  as? String {
                    newObject.removeValue(forKey: "id")
                    try await db.collection("Menu").document(id).setData(newObject)
                    for meal in meals {
                        var newMeal = meal
//                        if newMeal["price"] == nil {
//                            newMeal["price"] = 0
//                        }
                        if newMeal["index"] == nil {
                            newMeal["index"] = 0
                        }
//                        if newMeal["group_ar"] == nil {
//                            newMeal["group_ar"] = ""
//                        }
//                        if newMeal["group_he"] == nil {
//                            newMeal["group_he"] = ""
//                        }
                        
                        try await db.collection("Menu").document(id).collection("Meals").addDocument(data: newMeal)
                        if (newMeal["group_he"] as? String) == "מיוחדים" {
                            var smallNewMeal = newMeal
                            smallNewMeal["name_ar"] = (smallNewMeal["name_ar"] as! String) + " " + "(صغير)"
                            smallNewMeal["name_he"] = (smallNewMeal["name_he"] as! String) + " " + "(אישית)"
                            smallNewMeal["price"] = (smallNewMeal["price"] as! Int) - 20
                            try await db.collection("Menu").document(id).collection("Meals").addDocument(data: smallNewMeal)
                        }
    
                    }
                }

                print(object)
            }
    
        }
    }
    
    func loadAllData() async {
        var info = [[String: Any]]()
        let db = Firestore.firestore()
        let collection = db.collection("Menu")
        let jsonEncoder = Firestore.Encoder()

        do {
            let snapshot = try await collection.getDocuments()
            let items = try snapshot.documents.map({ try $0.data(as: MenuItem.self) }).sorted(by: { $0.index ?? 0 < $1.index ?? 0})
            
            for item in items {
                var dict = try jsonEncoder.encode(item)
                if let id = item.id {
                    
                    let subCollection = db.collection("Menu").document(id).collection("Meals")
                    let subSnapshot = try await subCollection.getDocuments()
                    var subItems = try subSnapshot.documents.map({ try $0.data(as: MenuItem.self) })
                    
                    subItems = subItems.sorted(by: { $0.price ?? 0 > $1.price ?? 0}).sorted(by: { $0.group < $1.group }).sorted(by: { $0.index ?? 0 < $1.index ?? 0})
                    var subinfo = [[String: Any]]()
                    for subItem in subItems {
                        let subdict = try jsonEncoder.encode(subItem)
                         subinfo.append(subdict)
                    }
                    dict["id"] = id
                    dict["image"] = "\(id).png"
                    dict["Meals"] = subinfo
                    info.append(dict)
                }
            }
            save(info: info)
        }
        catch {
           print(error)
        }
    }
    
    func save(info: [[String: Any]]) {
        if let jsonString = convertDictionaryToJSON(info),
           let data = jsonString.data(using: .utf8) {
           try? data.write(to: URL(filePath: "/Users/hmeedo/Desktop/data.json"))
              print(jsonString)
        }
    }
    
    func convertDictionaryToJSON(_ object: [[String: Any]]) -> String? {

       guard let jsonData = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted) else {
          print("Something is wrong while converting dictionary to JSON data.")
          return nil
       }

       guard let jsonString = String(data: jsonData, encoding: .utf8) else {
          print("Something is wrong while converting JSON data to JSON string.")
          return nil
       }

       return jsonString
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}

