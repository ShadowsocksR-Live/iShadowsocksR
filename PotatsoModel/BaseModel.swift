//
//  BaseModel.swift
//
//  Created by LEI on 4/6/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import RealmSwift

open class BaseModel: Object {
    @objc open dynamic var uuid = UUID().uuidString
    @objc open dynamic var createAt = Date().timeIntervalSince1970
    @objc open dynamic var updatedAt = Date().timeIntervalSince1970
    @objc open dynamic var deleted = false
    @objc open dynamic var synced = false

    override open class func primaryKey() -> String? {
        return "uuid"
    }
    
    static var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm:ss"
        return f
    }

    open func validate() throws {
        //
    }
}
