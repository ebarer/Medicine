//
//  policyMedDateCreated.swift
//  Medicine
//
//  Created by Elliot Barer on 2016-02-03.
//  Copyright © 2016 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class policyMedDateCreated: NSEntityMigrationPolicy {

//    - (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)inSourceInstance
//    entityMapping:(NSEntityMapping *)inMapping
//    manager:(NSMigrationManager *)inManager
//    error:(NSError **)outError {
//    NSManagedObject *newObject;
//    NSEntityDescription *sourceInstanceEntity = [inSourceInstance entity];
//    
//    // correct entity? just to be sure
//    if ( [[sourceInstanceEntity name] isEqualToString:@"<-the_entity->"] ) {
//    newObject = [NSEntityDescription insertNewObjectForEntityForName:@"<-the_entity->" inManagedObjectContext:[inManager destinationContext]];
//    
//    // obtain the attributes
//    NSDictionary *keyValDict = [inSourceInstance committedValuesForKeys:nil];
//    NSArray *allKeys = [[[inSourceInstance entity] attributesByName] allKeys];
//    // loop over the attributes
//    for (NSString *key  in allKeys) {
//    // Get key and value
//    id value = [keyValDict objectForKey:key];
//    if ( [key isEqualToString:@"<-the_attribute->"] ) {
//    // === here retrieve old value ==
//    id oldValue = [keyValDict objectForKey:key];
//    // === here do conversion as needed ==
//    // === then store new value ==
//    [newObject setValue:@"<-the_converted_string->" forKey:key];
//    } else { // no need to modify the value. Copy it across
//    [newObject setValue:value forKey:key];
//    }
//    }
//    
//    [inManager associateSourceInstance:inSourceInstance  withDestinationInstance:newObject forEntityMapping:inMapping];
//    }
//    return YES;
//    }

    override func createDestinationInstancesForSourceInstance(sInstance: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        <#code#>
    }
    
}
