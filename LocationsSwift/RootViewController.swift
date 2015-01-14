//
//  RootViewController.swift
//  LocationsSwift
//
//  Created by osabe on 2015/01/14.
//  Copyright (c) 2015年 andropenguin. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class RootViewController: UITableViewController, CLLocationManagerDelegate {

    var events: [Event]?
    lazy var managedObjectContext : NSManagedObjectContext? = {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        if let managedObjectContext = appDelegate.managedObjectContext {
            return managedObjectContext
        }
        else {
            return nil
        }
    }()
    
    var _locationManager: CLLocationManager?
    
    func locationManager() -> CLLocationManager {
        if _locationManager != nil {
            return _locationManager!
        }
        _locationManager = CLLocationManager()
        _locationManager!.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        _locationManager!.delegate = self
        
        if _locationManager!.respondsToSelector("requestWhenInUseAuthorization") {
            _locationManager!.requestWhenInUseAuthorization()
        }
        
        return _locationManager!
        
    }
    var addButton: UIBarButtonItem?
    
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        if addButton == nil {
            return
        }
        addButton!.enabled = true
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        if addButton == nil {
            return
        }
        addButton?.enabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // タイトルを設定する
        self.title = "Locations"
        
        // ボタンをセットアップする
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "addEvent")
        addButton!.enabled = false
        self.navigationItem.rightBarButtonItem = addButton
        
        // ロケーションマネージャを起動する
        self.locationManager().startUpdatingLocation()
        
//        events = [Event]()
        
        let request = NSFetchRequest()
        if let entity: NSEntityDescription = NSEntityDescription.entityForName("Event", inManagedObjectContext: self.managedObjectContext!) {
            request.entity = entity
        }
        
        let sortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        let sortDescriptors: [NSSortDescriptor] = [sortDescriptor]
        request.sortDescriptors = sortDescriptors
        
        var error: NSError? = nil
        var fetchResults: [Event]? = self.managedObjectContext!.executeFetchRequest(request, error: &error) as? [Event]
        if (fetchResults == nil) {
            // エラー処理をする
            println("error")
            return
        }
        events = fetchResults
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        _locationManager = nil
    }
    
    func addEvent() {
        if _locationManager == nil {
            self.locationManager()
        }
        var location: CLLocation? = _locationManager!.location
        println("location = \(location)")
        if location == nil {
            println("location is nil")
            return
        }
        
        let managedObject: AnyObject = NSEntityDescription.insertNewObjectForEntityForName("Event", inManagedObjectContext: self.managedObjectContext!)
        let event = managedObject as LocationsSwift.Event
        var coodinate: CLLocationCoordinate2D = location!.coordinate as CLLocationCoordinate2D
        event.latitude = NSNumber(double: coodinate.latitude)
        event.longitude = NSNumber(double: coodinate.longitude)
        event.creationDate = NSDate()
        println("event = \(event)")
        
        var error: NSError? = nil
        if !self.managedObjectContext!.save(&error) {
            // エラー処理をする
            println("error")
            return
        }

        if events!.isEmpty {
            events!.append(event)
        } else {
            events!.insert(event, atIndex: 0)
        }
        var indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths(NSArray(object: indexPath), withRowAnimation: UITableViewRowAnimation.Fade)
        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: true)

    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return events!.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // タイムスタンプ用の日付フォーマッタ
        var dateFormatter: NSDateFormatter? = nil
        if dateFormatter == nil {
            dateFormatter = NSDateFormatter()
            dateFormatter!.timeStyle = NSDateFormatterStyle.MediumStyle
            dateFormatter!.dateStyle = NSDateFormatterStyle.MediumStyle
        }
        
        // 緯度と経度用の数値フォーマッタ
        var numberFormatter: NSNumberFormatter? = nil
        if numberFormatter == nil {
            numberFormatter = NSNumberFormatter()
            numberFormatter!.numberStyle = NSNumberFormatterStyle.DecimalStyle
            numberFormatter!.maximumFractionDigits = 3
        }
        
        let CellIdentifier = "Cell"
        
        // 新規セルをデキューまたは作成する
        var cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as? UITableViewCell
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: CellIdentifier)
        }
        
        var event: Event? = events![indexPath.row]
        println("event = \(event)")
        
        cell!.textLabel!.text = dateFormatter!.stringFromDate(event!.creationDate)
        
        var string = String(format: "%@, %@", numberFormatter!.stringFromNumber(event!.latitude)!,
            numberFormatter!.stringFromNumber(event!.longitude)!)
        cell!.detailTextLabel!.text = string
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            // 指定のインデックスパスにある管理オブジェクトを削除する
            let eventToDelete: NSManagedObject = events![indexPath.row]
            self.managedObjectContext!.deleteObject(eventToDelete)
            
            // 配列とTable Viewを更新する
            events!.removeAtIndex(indexPath.row)
            // NSArray(object: indexPath)だと、ビルドエラーになる。
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            
            // 変更をコミットする
            var error: NSError? = nil
            if !self.managedObjectContext!.save(&error) {
                // エラー処理をする
                println("error")
                return
            }
        }
    }

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as UITableViewCell

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
