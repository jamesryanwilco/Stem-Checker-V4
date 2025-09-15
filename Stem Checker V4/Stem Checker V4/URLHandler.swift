import Foundation

class URLHandler: ObservableObject {
    @Published var urlsToLoad: [URL] = []
}
