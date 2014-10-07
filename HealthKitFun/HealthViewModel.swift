//
//  HealthViewModel.swift
//  HealthKitFun
//
//  Created by Josh Brown on 10/6/14.
//  Copyright (c) 2014 Roadfire Software. All rights reserved.
//

import Foundation
import HealthKit

class HealthViewModel {
    
    let healthStore: HKHealthStore
    var steps = 0
    var distance = 0.0
    
    init() {
        self.healthStore = HKHealthStore()
    }
    
    func fetchData(completion: (success: Bool) -> ()) {
        self.requestAccessToDataTypes { (success) -> () in
            completion(success: success)
        }
    }
    
    func requestAccessToDataTypes(completion: (success: Bool) -> ()) {
        if !HKHealthStore.isHealthDataAvailable() {
            completion(success: false)
            return
        }
        
        let typesToRead = self.dataTypesToRead()
        healthStore.requestAuthorizationToShareTypes(NSSet(), readTypes:typesToRead, completion: { (success, error) -> Void in
            if !success {
                println("HealthKit can't access the data it needs to display these values.")
                completion(success: false)
                return
            }
            
            self.fetchSteps(){}
            self.fetchDistance() {
                completion(success: true)
            }
        })
    }

    func dataTypesToRead() -> NSSet {
        let stepType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
        let distanceType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)
        return NSSet(objects: stepType, distanceType)
    }
    
    func fetchSteps(completion: () -> ()) {
        let stepsType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
        self.fetchTotalDataOfQuantityType(stepsType, completion: { (quantity, error) -> () in
            if let quantity = quantity {
                self.steps = Int(quantity.doubleValueForUnit(HKUnit.countUnit()))
            }
            completion()
        })
    }
    
    func fetchDistance(completion: () -> ()) {
        let distanceType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)
        self.fetchTotalDataOfQuantityType(distanceType, completion: { (quantity, error) -> () in
            if let quantity = quantity {
                self.distance = quantity.doubleValueForUnit(HKUnit.mileUnit())
            }
            completion()
        })
    }
    
    func fetchTotalDataOfQuantityType(quantityType: HKQuantityType, completion:(quantity: HKQuantity?, error: NSError?) -> ()) {
        let calendar = NSCalendar.currentCalendar()
        let now = NSDate()
        
        let flags: NSCalendarUnit = .YearCalendarUnit | .MonthCalendarUnit | .DayCalendarUnit
        let components = calendar.components(flags, fromDate: now)

        let startDate = calendar.dateFromComponents(components)
        let endDate = calendar.dateByAddingUnit(NSCalendarUnit.DayCalendarUnit, value: 1, toDate: startDate!, options: nil)
        
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .StrictStartDate)
        
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: HKStatisticsOptions.CumulativeSum) { (query, result, error) -> Void in
            if result != nil {
                completion(quantity: result.sumQuantity(), error: error)
            }
        }
        healthStore.executeQuery(query)
    }
    
    func numberOfRowsInSection(section: Int) -> Int {
        return 2
    }
    
    func titleForRowAtIndexPath(indexPath: NSIndexPath) -> String {
        switch indexPath.row {
        case 0:
            return "Steps"
        case 1:
            return "Walking/Running Distance"
        default:
            return "hmm...."
        }
    }
    
    func subtitleForRowAtIndexPath(indexPath: NSIndexPath) -> String {
        switch indexPath.row {
        case 0:
            return "\(self.steps)"
        case 1:
            return "\(self.distance) mi"
        default:
            return "//TODO"
        }
    }
}
