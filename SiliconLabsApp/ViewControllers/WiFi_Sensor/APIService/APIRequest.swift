//
//  APIRequest.swift
//  IPAddressDemo
//
//  Created by SovanDas Maity on 24/06/24.
//

import Foundation

enum HttpMethods: String {
   case POST = "POST"
   case GET  = "GET"
 }
struct ApiHTTPrequest {
    
}

struct URLForRequest {
    var uri: String
    func getUrl() -> String {
        let ipArress = UserDefaults.standard.string(forKey: "access_point_IPA")
        let Url = String(format: "http://\(ipArress ?? "")/\(uri)")
        return Url
    }
    
}

class APIRequest {
    static let sharedInstance = APIRequest()

    func postApiCall(parameterDictionary: String, url : String, completionBlock: @escaping (_ ReponsData: Data?, _ APIClientError:Error?) -> Void) {
        
//        let ipArress = UserDefaults.standard.string(forKey: "access_point_IPA")
//        let Url = String(format: "http://\(ipArress ?? "")/\(url)")
        
        let UrlRe = URLForRequest(uri: url)
        let Url = UrlRe.getUrl()
        print(Url)

        //let Url = String(format: "http://192.168.10.10/\(url)")
        guard let serviceUrl = URL(string: Url) else { return }
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = HttpMethods.POST.rawValue
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        let parameters = parameterDictionary
        let postData = parameters.data(using: .utf8)
    
        request.httpBody = postData
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(response)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completionBlock(data, nil)
                    }else{
                        completionBlock(nil, error)
                    }
                }else{
                    completionBlock(nil, error)
                }
            }else{
                completionBlock(nil, error)
            }

        }.resume()
    }
    
    func getApiCall(url : String, completionBlock: @escaping (_ ReponsData: Data?, _ APIClientError:Error?) -> Void) {

//        let ipArress = UserDefaults.standard.string(forKey: "access_point_IPA")
//        let Url = String(format: "http://\(ipArress ?? "")/\(url)")
//        print(Url)
        
        let UrlRe = URLForRequest(uri: url)
        let Url = UrlRe.getUrl()
        print(Url)
        //let Url = String(format: "http://192.168.10.10/\(url)")
        guard let serviceUrl = URL(string: Url) else { return }
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = HttpMethods.GET.rawValue
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(response)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completionBlock(data, nil)
                    }else{
                       completionBlock(nil, error)
                    }
                }else{
                    completionBlock(nil, error)
                }
            }else{
                completionBlock(nil, error)
            }
            
        }.resume()
    }
}
