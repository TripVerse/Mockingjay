//
//  Builders.swift
//  Mockingjay
//
//  Created by Kyle Fuller on 01/03/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation

func convertFromGetToPost(_ getRequest : URLRequest) -> URLRequest?
{
  guard let urlString = getRequest.url?.absoluteString else
  {
    return nil
  }
  
  let url = URL(string: urlString)
  
  var request: URLRequest = getRequest
  
//  let randomString = String(describing:arc4random()%1000)
//  request.url = URL(string:"http://google.com/search?q=\(randomString)")
  request.httpMethod = "POST"
  
  //TODO Remove query parameters
  
//  request.setValue("application/json", forHTTPHeaderField:"Content-Type")
//  request.timeoutInterval = 60.0
  
  //additional headers
  //    request.setValue("deviceIDValue", forHTTPHeaderField:"DeviceId")
  var values: [String: AnyObject] = getRequest.url?.queryItems ?? [:]
  
  let valuesSerialized = try? JSONSerialization.data(withJSONObject: values, options: [])
  //    let bodyStr = "string or data to add to body of request"
  //    let bodyData = bodyStr.data(using: String.Encoding.utf8, allowLossyConversion: true)
  request.httpBody = valuesSerialized
  
  return request
}

// Collection of generic builders
public func convertFromGetToPostBuilder() -> (URLRequest,@escaping (Response)->(Void)) -> (Void)
{
  return {
    (request:URLRequest, completionHandler:@escaping (Response)->(Void)) in
    
    print("convertFromGetToPostBuilder: \(request.url?.absoluteString)")
    //Convert GET parameters to POST parameters
    let ephemeralSession = URLSession(configuration: URLSessionConfiguration.ephemeral)
    
    //            let url = URL(string: "https://itunes.apple.com")
    let postRequest = convertFromGetToPost(request)! //TODO Remove forced unwrap
    
    // 5
    let dataTask = ephemeralSession.dataTask(with: postRequest) {
      data, response, error in
      // 7
      if let error = error {
        print(error.localizedDescription)
        completionHandler(.failure(error as NSError))
      } else if let httpResponse = response as? HTTPURLResponse {
        var download = Download.noContent
        
        if let data = data
        {
          download = Download.content(data)
        }
        
        completionHandler(Response.success(httpResponse, download))
      }
    }
    // 8
    dataTask.resume()
    
    //TODO: Perform request
    
    //    if let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers) {
    //      return Response.success(response, download)
    //    }
    //
    //    return .failure(NSError(domain: NSExceptionName.internalInconsistencyException.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to construct response for stub."]))
  }
}

/// Generic builder for returning a failure
public func failure(_ error: NSError) -> (_ request: URLRequest) -> Response {
  return { _ in return .failure(error) }
}

public func http(_ status:Int = 200, headers:[String:String]? = nil, download:Download=nil) -> (_ request: URLRequest) -> Response {
  return { (request:URLRequest) in
    if let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers) {
      return Response.success(response, download)
    }
    
    return .failure(NSError(domain: NSExceptionName.internalInconsistencyException.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to construct response for stub."]))
  }
}

public func json(_ body: Any, status:Int = 200, headers:[String:String]? = nil) -> (_ request: URLRequest) -> Response {
  return { (request:URLRequest) in
    do {
      let data = try JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions())
      return jsonData(data, status: status, headers: headers)(request)
    } catch {
      return .failure(error as NSError)
    }
  }
}

public func jsonData(_ data: Data, status: Int = 200, headers: [String:String]? = nil) -> (_ request: URLRequest) -> Response {
  return { (request:URLRequest) in
    var headers = headers ?? [String:String]()
    if headers["Content-Type"] == nil {
      headers["Content-Type"] = "application/json; charset=utf-8"
    }
    
    return http(status, headers: headers, download: .content(data))(request)
  }
}
