//
//  Extensions.swift
//  Staradio
//
//  Created by Giacomo Marangoni on 15/12/16.
//  Copyright © 2016 matthewfecher.com. All rights reserved.
//

import Foundation

extension String {
    func decodeAll() -> String{
        let dataStr = self.data(using: String.Encoding.isoLatin1)
        return String(data: dataStr!, encoding: String.Encoding.utf8)!
    }
}
