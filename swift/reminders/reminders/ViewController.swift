//
//  ViewController.swift
//  reminders
//
//  Created by Michael Chirico on 11/3/18.
//  Copyright © 2018 Michael Chirico. All rights reserved.
//

import UIKit
import EventKit
//import EventKitUI



class ViewController: UIViewController {
  
  let eventStore = EKEventStore()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    //AddEvent()
    //UpdateEvent()
    //AddReminder()
    
    //UpdateReminder()
    
    //QueryReminder()
    //QueryEvent()
    //Test()
    //Remove()
    //Q()
  }
  
  
  
  func Q() {
    let startDate=Date().addingTimeInterval(-60*60*24)
    let endDate=Date().addingTimeInterval(60*60*24*3)
    
    let rLib = Reminder()
    
    rLib.getEvents(startDate: startDate,endDate: endDate) {
      (rfc) in self.PrEvents(rfc: rfc)
    }
  }
  
  func PrEvents(rfc: Reminder.ResultFromCall) {
    print("\n\nWe are in PrEvents\n\n")
    if let i = rfc.e {
      print("count:  \(i.count)")
    } else {
      print("count: 0")
    }
    if let events = rfc.e {
      for i in events {
        print("title: \(String(describing: i.title))")
        print("date: \(String(describing: i.startDate))")
      }
    }
  }
  
  
  
  
  func Test() {
    
    let rLib = Reminder()
    
    let dateString0 = "2018-11-4 9:56:25pm"
    let dateString1 = "2018-11-4 11:21:25pm"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ssa" //Input Format
    dateFormatter.timeZone = TimeZone.current
    let startDate = dateFormatter.date(from: dateString0)
    let endDate = dateFormatter.date(from: dateString1)
    
    
    rLib.addCalEvent(title: "Test123-reminderLib", notes: "Notes on Bozo", startDate: startDate!, endDate: endDate!) {
      (h) in
      print(h)
    }
    
   
    
  }
  
  func Remove() {
    
    let rLib = Reminder()
    let startDate=Date().addingTimeInterval(-60*60*24)
    let endDate=Date().addingTimeInterval(60*60*24*3)
    
    rLib.removeEvent(title: "Test123-reminderLib", startDate: startDate, endDate: endDate) {
      (rfc) in self.PrEvents(rfc: rfc)
    }
    
  }
  
  
  
  
  func AddEvent() {
    eventStore.requestAccess(to: EKEntityType.event, completion: {
      granted, error in
      if (granted) && (error == nil) {
        print("granted \(granted)")
        
        
        let event:EKEvent = EKEvent(eventStore: self.eventStore)
        event.title = "Test Title"
        event.startDate = NSDate() as Date
        event.endDate = NSDate() as Date
        event.notes = "This is a note"
        event.calendar = self.eventStore.defaultCalendarForNewEvents
        
        
        do {
          try self.eventStore.save(event, span: EKSpan.thisEvent, commit: true)
        } catch {
          print("Cannot save")
          return
        }
        print("Saved Event")
      }
    })
  }
  
  func AddReminder() {
    eventStore.requestAccess(to: EKEntityType.reminder, completion: {
      granted, error in
      if (granted) && (error == nil) {
        print("granted \(granted)")
        
        
        let reminder:EKReminder = EKReminder(eventStore: self.eventStore)
        reminder.title = "Must do this!"
        reminder.priority = 2
        
        //  Below to show completed
        //reminder.completionDate = Date()
        
        reminder.notes = "...this is a note"
        
        
        let alarmTime = Date().addingTimeInterval(1*60*24*3)
        let alarm = EKAlarm(absoluteDate: alarmTime)
        reminder.addAlarm(alarm)
        
        reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
        
        
        do {
          try self.eventStore.save(reminder, commit: true)
        } catch {
          print("Cannot save")
          return
        }
        print("Reminder saved")
      }
    })
  }
  
  
  func QueryReminder() {
    
    eventStore.requestAccess(to: EKEntityType.reminder, completion: {
      granted, error in
      if (granted) && (error == nil) {
        print("granted \(granted)")
        
        let predicate: NSPredicate? = self.eventStore.predicateForReminders(in: nil)
        if let aPredicate = predicate {
          self.eventStore.fetchReminders(matching: aPredicate, completion: {(_ reminders: [EKReminder]?) -> Void in
            
            for reminder: EKReminder? in reminders ?? [EKReminder?]() {
              // Do something for each reminder.
              print("\n\n\nreminder: \(String(describing: reminder?.title))")
              if let title = reminder?.title {
                
                if title.range(of: "Must do this!") != nil {
                  do {
                    try self.eventStore.remove(reminder!, commit: true)
                  } catch {
                    print("could not remove reminder")
                    continue
                  }
                  print("deleted")
                }
              }
              
            }
            
          })
          
          
        }
      }
    })
    
  }
  
  
  func UpdateReminder() {
    
    eventStore.requestAccess(to: EKEntityType.reminder, completion: {
      granted, error in
      if (granted) && (error == nil) {
        print("granted \(granted)")
        
        let predicate: NSPredicate? = self.eventStore.predicateForReminders(in: nil)
        if let aPredicate = predicate {
          self.eventStore.fetchReminders(matching: aPredicate, completion: {(_ reminders: [EKReminder]?) -> Void in
            for reminder: EKReminder? in reminders ?? [EKReminder?]() {
              // Do something for each reminder.
              print("\n\n\nreminder: \(String(describing: reminder?.title))")
              if let title = reminder?.title {
                
                if title.range(of: "Must do this!") != nil {
                  
                  reminder?.notes = "...modified note\n\n...more data\n\n"
                  do {
                    try self.eventStore.save(reminder!, commit: true)
                  } catch {
                    print("could not update reminder")
                    continue
                  }
                  print("Updated")
                }
              }
              
            }
          })
          
          
        }
      }
    })
    
  }
  
  
  
  
  
  func QueryEvent() {
    
    eventStore.requestAccess(to: EKEntityType.event, completion: {
      granted, error in
      if (granted) && (error == nil) {
        print("granted \(granted)")
        
        
        // What about Calendar entries?
        let startDate=Date().addingTimeInterval(-60*60*24)
        let endDate=Date().addingTimeInterval(60*60*24*3)
        let predicate2 = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        
        print("startDate:\(startDate) endDate:\(endDate)")
        let eV = self.eventStore.events(matching: predicate2) as [EKEvent]?
        
        if eV != nil {
          for i in eV! {
            print("Title  \(String(describing: i.title))" )
            print("stareDate: \(String(describing: i.startDate))" )
            print("endDate: \(String(describing: i.endDate))" )
            print("notes: \(String(describing: i.notes))")
            
            
            if i.title == "Test Title" {
              print("YES" )
              // Uncomment if you want to delete
              do {
                try self.eventStore.remove(i, span: EKSpan.thisEvent)
              } catch {
                print("Problem removing")
              }
              
            }
          }
        }
        
        
      }
    })
    
  }
  
  
  
  func UpdateEvent() {
    
    eventStore.requestAccess(to: EKEntityType.event, completion: {
      granted, error in
      if (granted) && (error == nil) {
        print("granted \(granted)")
        
        
        // What about Calendar entries?
        let startDate=Date().addingTimeInterval(-60*60*24)
        let endDate=Date().addingTimeInterval(60*60*24*3)
        let predicate2 = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        
        print("startDate:\(startDate) endDate:\(endDate)")
        let eV = self.eventStore.events(matching: predicate2) as [EKEvent]?
        
        if eV != nil {
          for i in eV! {
            print("Title  \(String(describing: i.title))" )
            print("stareDate: \(String(describing: i.startDate))" )
            print("endDate: \(String(describing: i.endDate))" )
            print("notes: \(String(describing: i.notes))")
            
            
            if i.title == "Test Title" {
              print("YES" )
              // Uncomment if you want to delete
              do {
                i.notes = "Changed Notes"
                //try self.eventStore.remove(i, span: EKSpan.thisEvent)
                try self.eventStore.save(i, span: EKSpan.thisEvent)
              } catch {
                print("Problem saving")
              }
              
            }
          }
        }
        
        
      }
    })
    
  }
  
}
