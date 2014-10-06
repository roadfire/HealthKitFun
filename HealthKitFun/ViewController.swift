//
//  ViewController.swift
//  HealthKitFun
//
//  Created by Josh Brown on 10/6/14.
//  Copyright (c) 2014 Roadfire Software. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UITableViewController {
    
    let viewModel = HealthViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
    }
    
    func refresh() {
        viewModel.fetchSteps { () -> () in
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        }
        viewModel.fetchDistance{ () -> () in
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if HKHealthStore.isHealthDataAvailable() {
            viewModel.requestAccessToDataTypes()
            self.refresh()
        } else {
            let alert = UIAlertController(title: "Health Data Unavailable", message: "Health Data is unavailable - this isn't going to work well...", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: { (action) in
                // nothing to do
            })
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }    

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        configureCell(cell, forRowAtIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.textLabel?.text = viewModel.titleForRowAtIndexPath(indexPath)
        cell.detailTextLabel?.text = viewModel.subtitleForRowAtIndexPath(indexPath)
    }

}

