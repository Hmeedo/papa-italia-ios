//
//  MainView.swift
//  papa italia
//
//  Created by Hameed Dahabry on 28/09/2024.
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewViewModel()
    var body: some View {
        ZStack {
            Color(.appBackground)
                .ignoresSafeArea(.all)
            
            ZStack(alignment: .bottom) {
                Rectangle()
                    .foregroundColor(.clear)
                Text(addressTitle)
                    .fontWeight(.black)
                    .foregroundStyle(.appGold)
                    .padding()
            }
            
            ZStack(alignment: .topLeading) {
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
                .padding(.horizontal)
                
                Rectangle()
                    .foregroundColor(.clear)
            }
            
            VStack(spacing: 40) {
                Image("logo")
                    .shadow(radius: 3)
                
                HStack(spacing: 8) {
                    Button(action: {
                        viewModel.openMenu()
                    }, label: {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "fork.knife")
                                Text(menuTitle)
                            }
                            .foregroundStyle(.appBackground)
                            Spacer()
                        }
                    })
                    .frame(height: 100)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.appRed)
                            .shadow(radius: 3)
                    }

                    VStack {
                        Button(action: {
                            viewModel.openInstagram()
                        }, label: {
                            ZStack {
                                Rectangle()
                                    .fill(.clear)
                                Image("insta")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                            
                        })
                        
                        LinearGradient(
                            gradient: Gradient(
                                colors: [.clear, .appGold, .clear]
                            ),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 1)
                        
                        Button(action: {
                            viewModel.openMap()
                        }, label: {
                            ZStack {
                                Rectangle()
                                    .fill(.clear)
                                Image(systemName: "location.fill")
                            }
                        })
                    }.background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.appBackground)
                            .shadow(radius: 3)
                    }
                    .frame(height: 100)
                    
                    Button(action: {
                        viewModel.call()
                    }, label: {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "phone.fill")
                                Text(orderNowTitle)
                            }
                            .foregroundStyle(.appBackground)
                            Spacer()
                        }
                    })
                    .frame(height: 100)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.appGreen)
                            .shadow(radius: 3)
                    }
                }
                .padding()
                .frame(maxWidth: 600)
            }
        }
        .fullScreenCover(isPresented: $viewModel.urlToOpen.mappedToBool(), onDismiss: {
            viewModel.urlToOpen = nil
        }, content: {
            SFSafariView(url: viewModel.urlToOpen!)
        })
        .fullScreenCover(isPresented: $viewModel.showMenu, content: {
            MenuView()
        })
        .fullScreenCover(isPresented: $viewModel.showMap, onDismiss: {
            viewModel.showMap = false
        }, content: {
            MapView()
        })
    }
    
    var orderNowTitle: String {
        if Constants.selectedLangauge == "he" {
            "הזמן עכשיו"
        }else {
            "اطلب الان"
        }
    }
    
    var menuTitle: String {
        if Constants.selectedLangauge == "he" {
            "תפריט"
        }else {
            "قائمة الطعام"
        }
    }
    
    var addressTitle: String {
        if Constants.selectedLangauge == "he" {
            "רחוב אל ג׳ליל מול תחנת סונול"
        }else {
            "شارع الجليل مقابل محطة سونول"
        }
    }
}

class MainViewViewModel: ObservableObject {
    @Published var showActionSheet = false
    @Published var showMenu = false
    @Published var showMap = false
    @Published var urlToOpen : URL?
    
    @Published var selectedLanguage: Languages = Languages(rawValue: Constants.selectedLangauge) ?? .ar  {
        didSet {
            Constants.selectedLangauge = selectedLanguage.rawValue
            let _ = objectWillChange
        }
    }
    
    private var phoneNumber: String = "046361110"
    private var instaAppURL = URL(string: "instagram://user?username=papa.italia_")!
    private var instaURL =  URL(string: "https://www.instagram.com/papa.italia_")!
    
    func openMap() {
        showMap = true
    }
    
    func openMenu() {
        showMenu = true
    }
    
    func call() {
        let url = URL(string: "tel:\(phoneNumber)")!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func openInstagram() {
        if UIApplication.shared.canOpenURL(instaAppURL) {
            UIApplication.shared.open(instaAppURL)
        }else {
            urlToOpen = instaURL
        }
    }
    
}

#Preview {
    MainView()
}
