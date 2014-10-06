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
    
    var healthStore: HKHealthStore?
    var steps = 0
    var distance = 0.0
    
    init() {
        self.healthStore = HKHealthStore()
    }
    
    func requestAccessToDataTypes() {
        let typesToRead = self.dataTypesToRead()
        self.healthStore?.requestAuthorizationToShareTypes(NSSet(), readTypes:typesToRead, completion: { (success, error) -> Void in
            if !success {
                println("HealthKit can't access the data it needs to display these values.")
                return
            }
            
            self.fetchSteps(){}
            self.fetchDistance(){}
        })
    }

    func dataTypesToRead() -> NSSet {
        let stepType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
        let distanceType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)
        return NSSet(objects: stepType, distanceType)
    }
    
    func fetchSteps(completion: () -> ()) {
        let stepsType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
        self.fetchMostRecentDataOfQuantityType(stepsType, anchor: 0) { (quantitySamples, newAnchor, error) -> () in
            println("quantity samples: \(quantitySamples)")
            
            var steps = 0
            if let samples = quantitySamples {
                for sample in samples {
                    steps += Int(sample.quantity.doubleValueForUnit(HKUnit.countUnit()))
                    println("adding steps: \(steps)")
                }
            }
            
            self.steps = steps
            completion()
        }
    }
    
    func fetchDistance(completion: () -> ()) {
        let distanceType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)
        self.fetchTotalDataOfQuantityType(distanceType, completion: { (quantity, error) -> () in
            self.distance = quantity.doubleValueForUnit(HKUnit.mileUnit())
            completion()
        })
    }
    
    func fetchMostRecentDataOfQuantityType(quantityType: HKQuantityType, anchor: Int, completion:(quantitySamples: [HKQuantitySample]?, newAnchor: Int, error: NSError?) -> ()) {
        let query = HKAnchoredObjectQuery(type: quantityType, predicate: nil, anchor: anchor, limit: 0) { (query, results, newAnchor, error) -> Void in
            completion(quantitySamples: results as? [HKQuantitySample], newAnchor: newAnchor, error: error)
        }
        
        self.healthStore?.executeQuery(query)
    }
    
    func fetchTotalDataOfQuantityType(quantityType: HKQuantityType, completion:(quantity: HKQuantity, error: NSError?) -> ()) {
        
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
        self.healthStore?.executeQuery(query)
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
