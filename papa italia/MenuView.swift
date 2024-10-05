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
                    let shouldShowFooter = index < (meals.count - 1) && meals[index + 1].group != item.group
                    mealView(item: item,shouldShowInfo: shouldShowInfo, shouldShowFooter: shouldShowFooter)
                }
            } else {
                ProgressView()
                    .task {
                        guard let id = item.id else { return }
                        await viewModel.loadMeals(for: id)
                    }
            }
        }
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
    
    @ViewBuilder func mealView(item: MenuItem, shouldShowInfo: Bool, shouldShowFooter: Bool) -> some View {
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
            
            if shouldShowFooter, item.footer.count > 0 {
                Text(item.footer)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top)
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

#Preview {
    MenuView()
}
