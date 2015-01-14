//
//  Event.swift
//  LocationsSwift
//
//  Created by osabe on 2015/01/14.
//  Copyright (c) 2015年 andropenguin. All rights reserved.
//

import Foundation
import CoreData

class Event: NSManagedObject {

    @NSManaged var creationDate: NSDate
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber

}
