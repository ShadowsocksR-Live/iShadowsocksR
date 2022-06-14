//
//  Images.swift
//
//  Created by LEI on 1/23/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation

public extension String {
    
    var image: UIImage? {
        return UIImage(named: self)
    }
    
    var templateImage: UIImage? {
        return UIImage(named: self)?.withRenderingMode(.alwaysTemplate)
    }
    
    var originalImage: UIImage? {
        return UIImage(named: self)?.withRenderingMode(.alwaysOriginal)
    }

}
