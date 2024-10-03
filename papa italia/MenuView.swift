//
//  ContentView.swift
//  papa italia
//
//  Created by Hameed Dahabry on 27/09/2024.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct MenuView: View {
    @Environment(\.dismiss) var dismiss
    @State private var height: CGFloat = 100
    @State private var scale: CGFloat = 1
    private let coordinateSpaceName = "scrollViewSpaceName"
    
    @StateObject private var viewModel = MenuViewModel()
    
    func isRunningOnIPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var items: [GridItem] {
        if isRunningOnIPad() {
            [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        } else {
            [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
    }
    
    var body: some View {
        ZStack {
            Color(.appBackground)
                .ignoresSafeArea(.all)
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                }else if let error = viewModel.error {
                    Image(systemName: "wifi.exclamationmark")
                        .symbolRenderingMode(.hierarchical)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .foregroundStyle(Color.appRed)
                    Text(error.localizedDescription)
                        .bold()
                    Button {
                        viewModel.reload()
                    } label: {
                        Text(Constants.reloadTitle)
                            .padding()
                            .bold()
                            .foregroundColor(.appGreen)
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.appBackground)
                            .shadow(radius: 3)
                    }

                }else {
                    header()
                    contentView()
                }
            }
        }
        .task {
           // await viewModel.loadAllData()
            await viewModel.loadData()
        }
    }
    
    @ViewBuilder func contentView() -> some View {
        ScrollView {
            if let item = viewModel.selectedItem {
                innerMenuView(item: item)
                    .transition(.opacity)
            } else {
                Spacer()
                    .frame(height: 16)
                categoriesView()
                    .transition(.opacity)
            }
        }
        .animation(.easeIn,value: viewModel.selectedItem == nil)
        .coordinateSpace(name: coordinateSpaceName)
        .onPreferenceChange(ScrollViewWithPullDownOffsetPreferenceKey.self) { value in
            if value < 0 {
                height = max(100 - ((abs(value) / 100) * 100), 40)
                scale = 1
            }else {
                height = 100
                scale = 1 + ((abs(value) / 100) * 1)
            }
        }
    }
    
    @ViewBuilder func header() -> some View {
        ZStack {
            HStack {
                Button {
                    viewModel.showActionSheet = true
                } label: {
                    HStack {
                        Text(viewModel.selectedLanguage.displayName)
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .bold()
                }
                .actionSheet(isPresented: $viewModel.showActionSheet) {
                    ActionSheet(title: Text("בחר שפה - اختر لغة"), buttons: [
                        .default(Text("عربي"), action: { // 5
                            viewModel.selectedLanguage = .ar
                        }),
                        .default(Text("עברית"), action: {
                            viewModel.selectedLanguage = .he
                        })
                    ]
                    )
                }
                
                Spacer()
                
                Button(action: {
                    if viewModel.selectedItem != nil {
                        viewModel.selectedItem = nil
                    }else {
                        dismiss()
                    }
                }, label: {
                    Image(systemName: viewModel.selectedItem != nil ? "chevron.left" : "xmark")
                        .bold()
                })
                .frame(width: 40,height: 40)
            }
            .padding(.horizontal)
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: height)
                .scaleEffect(scale)
                .shadow(radius: 2 * scale)
        }
        
    }
    
    @ViewBuilder func innerMenuView(item: MenuItem) -> some View {
        LazyVStack {
            titleView(item: item)
            if let id = item.id, let meals = viewModel.meals[id] {
                ForEach(0..<meals.count) { index in
                    let item = meals[index]
                    let shouldShowInfo = index == 0 || item.group != meals[index - 1].group
                    mealView(item: item,shouldShowInfo: shouldShowInfo)
                }
            }else {
                ProgressView()
                    .task {
                        guard let id = item.id else { return }
                        await viewModel.loadMeals(for: id)
                    }
            }
        }
        .background(
            GeometryReader { proxy in
                let offset = proxy.frame(in: .named(coordinateSpaceName)).minY
                Color.clear.preference(key: ScrollViewWithPullDownOffsetPreferenceKey.self, value: offset)
            }
        )
    }
    
    @ViewBuilder func categoriesView() -> some View {
        LazyVGrid(columns: items) {
            ForEach(viewModel.items) { item in
                MenuItemView(item: item)
                    .onTapGesture {
                        viewModel.selectedItem = item
                    }
            }
        }
        .padding(.horizontal, 8)
        .background(
            GeometryReader { proxy in
                let offset = proxy.frame(in: .named(coordinateSpaceName)).minY
                Color.clear.preference(key: ScrollViewWithPullDownOffsetPreferenceKey.self, value: offset)
            }
        )
    }
    
    @ViewBuilder func titleView(item: MenuItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Rectangle()
                .fill(.appGold)
                .frame(height: 2)
                .ignoresSafeArea()
            Text(item.name)
                .foregroundStyle(.appRed)
                .font(.title3)
                .fontWeight(.heavy)
                .padding(.horizontal)
            Rectangle()
                .fill(.appGold)
                .frame(height: 2)
                .ignoresSafeArea()
            
            if item.info.count > 0 {
                HStack {
                    Spacer()
                    Text(item.info)
                        .font(.headline)
                        .foregroundStyle(.appGreen)
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder func mealView(item: MenuItem, shouldShowInfo: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if shouldShowInfo, item.group.count > 0 {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(.clear)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [.clear, .appGold]), startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(height: 1)
                        .ignoresSafeArea()
                    
                    Text(item.group)
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundStyle(.appGreen)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize()
                    
                    Rectangle()
                        .fill(.clear)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [ .appGold, .clear]), startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(height: 1)
                        .ignoresSafeArea()
                    
                }
                
            }
            
            HStack {
                Text(item.name)
                    .font(.headline)
                Spacer()
                Text(item.priceString)
                    .font(.headline)
            }
            .padding(.horizontal)
            
            if item.info.count > 0 {
                Text(item.info)
                    .font(.subheadline)
                    .padding(.horizontal)
            }
        }
        .padding(.bottom)
    }
}

struct MenuItemView: View {
    let item: MenuItem
    @State private var image : UIImage?
    
    var body: some View {
        VStack {
            Image(uiImage: image ?? UIImage(named: "logo")!)
                .resizable()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(4)
            
            Text(item.name)
                .font(.headline)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom)
                .padding(.horizontal)
        }
        .aspectRatio(1.3, contentMode: .fit)
        .task(id: item.id, priority: .background) {
            if let cacheImage = await item.getCachedImage() {
                image = cacheImage
            }else {
                image = try? await item.getImage()
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    Color.appGold,
                    style: StrokeStyle(
                        lineWidth: 3
                    )
                )
        }
    }
    
    func isRunningOnIPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}

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

struct ScrollViewWithPullDownOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

#Preview {
    MenuView()
}
