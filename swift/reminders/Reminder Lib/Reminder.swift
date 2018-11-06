
import EventKit

// Just for ideas ... you can delete, when done

struct Product {
  var name: String
  var cost: Double
}

struct Coupon {
  var code: String
  var discountPercentage: Double
}


class PriceCalculator {
  static func calculateFinalPrice(for products: [Product],
                                  applying coupon: Coupon?) -> Double {
    
    var finalPrice = products.reduce(0) { price, product
      in
      return price + product.cost
    }
    
    if let coupon = coupon {
      let multiplier = coupon.discountPercentage / 100
      let discount = Double(finalPrice) * multiplier
      finalPrice -= Double(discount)
    }
    
    return finalPrice
  }
}




func getSumMulOf(array:[Int],
                 handler: @escaping (([Int])->Int)) {
  
  var sum: Int = 0
  var mul: Int = 1
  for value in array {
    sum += value
    mul *= value
  }
  
  DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
    print("sum+mul: \(handler([sum,mul]))")
  })
}

class Reminder {
  
  //let eventStore = EKEventStore()
  let eventStore: EKEventStore
  
  struct ResultFromCall {
    var status: String?
    var granted: String?
    var notes: String?
    var calendarItemIdentifier: String?
    var e: [EKEvent]?
    var r: [EKReminder]?
  }
  
  
  init(eventStore: EKEventStore = EKEventStore()) {
    self.eventStore = eventStore
  }
  
  func addReminderHack(title: String,
                   notes: String,
                   priority: Int,
                   alarmTime: Date,
                   handler: @escaping ((ResultFromCall)->Void))  {
    
    var rfc = ResultFromCall()
    eventStore.requestAccess(to: EKEntityType.reminder, completion: {
      granted, error in
      if (granted) && (error == nil) {
        rfc.granted = "granted \(granted)"
        
        let reminder:EKReminder = EKReminder(eventStore: self.eventStore)
        reminder.title = title
        reminder.priority = priority
        rfc.calendarItemIdentifier = reminder.calendarItemIdentifier
        
        //  Below to show completed
        //reminder.completionDate = Date()
        
        reminder.notes = notes
        
        ///let alarmTime = Date().addingTimeInterval(1*60*24*3)
        let alarm = EKAlarm(absoluteDate: alarmTime)
        reminder.addAlarm(alarm)
        reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
        
        do {
          try self.eventStore.save(reminder, commit: true)
        } catch {
          rfc.status = "Cannot save"
          handler(rfc)
          return
        }
        
        rfc.status = "Reminder saved"
        handler(rfc)
        
      }
    })
  }
  
  
  
  func addReminder(title: String,
                   notes: String,
                   priority: Int,
                   alarmTime: Date,
                   handler: @escaping ((ResultFromCall)->Void))  {
    
    var rfc = ResultFromCall()
    eventStore.requestAccess(to: EKEntityType.reminder, completion: {
      granted, error in
      if (granted) && (error == nil) {
        rfc.granted = "granted \(granted)"
        
        let reminder:EKReminder = EKReminder(eventStore: self.eventStore)
        reminder.title = title
        reminder.priority = priority
        
        //  Below to show completed
        //reminder.completionDate = Date()
        
        reminder.notes = notes
        
        ///let alarmTime = Date().addingTimeInterval(1*60*24*3)
        let alarm = EKAlarm(absoluteDate: alarmTime)
        reminder.addAlarm(alarm)
        reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
        
        do {
          try self.eventStore.save(reminder, commit: true)
        } catch {
          rfc.status = "Cannot save"
          handler(rfc)
          return
        }
        rfc.status = "Reminder saved"
        handler(rfc)
        
      }
    })
  }
  
  
  func addCalEvent(title: String,
                   notes: String,
                   startDate: Date,
                   endDate: Date,
                   handler: @escaping ((ResultFromCall)->Void))  {
    
    var rfc = ResultFromCall()
    
    self.eventStore.requestAccess(to: EKEntityType.event, completion: {
      granted, error in
      if (granted) && (error == nil) {

        
        let event:EKEvent = EKEvent(eventStore: self.eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.calendar = self.eventStore.defaultCalendarForNewEvents
        
        
        do {
          try self.eventStore.save(event, span: EKSpan.thisEvent, commit: true)
          rfc.notes = "title: \(String(describing: event.title))"
        } catch {
          print("Cannot save")
          rfc.status = "Cannot save"
          handler(rfc)
          return
        }
        rfc.status = "Saved Event"
        handler(rfc)
      } else {
        rfc.status = "No Access"
        handler(rfc)
      }
    })
    
    
  }
  
  
  /*
   Sample on How to Use getEvents:
   
   */
  func testCalenderEntry() {
    
    func PrEvents(rfc: ResultFromCall) {
      if let events = rfc.e {
        for i in events {
          print("title: \(String(describing: i.title))")
          print("date: \(String(describing: i.startDate))")
        }
      }
    }
    
    let startDate=Date().addingTimeInterval(-60*60*24)
    let endDate=Date().addingTimeInterval(60*60*24*3)
    
    let rLib = Reminder()
    
    rLib.getEvents(startDate: startDate,endDate: endDate) {
      (rfc) in PrEvents(rfc: rfc)
    }
  }
  
  
  func getReminders(startDate: Date,
                    endDate: Date,
                    handler: @escaping ((ResultFromCall)->Void)) {
    
    var rfc = ResultFromCall()
    eventStore.requestAccess(to: EKEntityType.reminder, completion: {
      granted, error in
      if (granted) && (error == nil) {
        rfc.granted = "granted \(granted)"
        
        let predicate: NSPredicate? = self.eventStore.predicateForReminders(in: nil)
        if let aPredicate = predicate {
          self.eventStore.fetchReminders(matching: aPredicate, completion: {(_ reminders: [EKReminder]?) -> Void in
            
            rfc.r = reminders
            handler(rfc)
            
          })
          
          
        }
      }
    })
    
  }
  
  func updateReminders(title: String,
                       newTitle: String,
                       newNotes: String,
                       newPriority: Int,
                       newAlarmTime: Date,
                       
                       startDate: Date,
                       endDate: Date,
                       handler: @escaping ((ResultFromCall)->Void)) {
    
    var rfc = ResultFromCall()
    eventStore.requestAccess(to: EKEntityType.reminder, completion: {
      granted, error in
      if (granted) && (error == nil) {
        rfc.granted = "granted \(granted)"
        
        let predicate: NSPredicate? = self.eventStore.predicateForReminders(in: nil)
        if let aPredicate = predicate {
          self.eventStore.fetchReminders(matching: aPredicate, completion: {(_ reminders: [EKReminder]?) -> Void in
            
            rfc.r = reminders
            rfc.status = "Reminder Updated"
            
            
            for reminder: EKReminder? in reminders ?? [EKReminder?]() {
              // Do something for each reminder.
              
              if let title = reminder?.title {
                
                if title.range(of: title) != nil {
                  
                  reminder?.title = newTitle
                  reminder?.notes = newNotes
                  reminder?.priority = newPriority
                  
                  let alarm = EKAlarm(absoluteDate: newAlarmTime)
                  reminder?.alarms = [alarm]
                  // reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
                  
                  do {
                    try self.eventStore.save(reminder!, commit: true)
                  } catch {
                    rfc.status = "Could not update reminder"
                    continue
                  }
                  rfc.status = "Reminder Updated"
                }
              }
              
            }
            
            handler(rfc)
            
            
          })
          
          
        }
      }
    })
    
  }
  
  
  func removeReminders(title: String,
                       
                       startDate: Date,
                       endDate: Date,
                       handler: @escaping ((ResultFromCall)->Void)) {
    
    var rfc = ResultFromCall()
    eventStore.requestAccess(to: EKEntityType.reminder, completion: {
      granted, error in
      if (granted) && (error == nil) {
        rfc.granted = "granted \(granted)"
        
        let predicate: NSPredicate? = self.eventStore.predicateForReminders(in: nil)

        if let aPredicate = predicate {
          self.eventStore.fetchReminders(matching: aPredicate, completion: {(_ reminders: [EKReminder]?) -> Void in
            
            rfc.r = reminders
            rfc.status = "Reminder Updated"
            
            for reminder: EKReminder? in reminders ?? [EKReminder?]() {
              // Do something for each reminder.
              
              if let reminderTitle = reminder?.title {
                if reminderTitle.range(of: title) != nil {

                  do {
                    try self.eventStore.remove(reminder!, commit: true)
                  } catch {
                    rfc.status = "Could not remove reminder"
                    continue
                  }
                  rfc.status = "Reminder Removed"
                }
              }
              
            }
            
            handler(rfc)
            
            
          })
          
          
        }
      }
    })
    
  }
  
  
  
  func getEvents(startDate: Date,
                 endDate: Date,
                 handler: @escaping ((ResultFromCall)->Void)) {
    
    var rfc = ResultFromCall()
    eventStore.requestAccess(to: EKEntityType.event, completion: {
      granted, error in
      if (granted) && (error == nil) {
        let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let eV = self.eventStore.events(matching: predicate) as [EKEvent]?
        rfc.e = eV
        handler(rfc)
        
      }
    })
    
  }
  
  
  
  // Returns remaining events -- events not deleted
  func removeEvent(title: String,
                   startDate: Date,
                   endDate: Date,
                   handler: @escaping ((ResultFromCall)->Void)) {
    
    var rfc = ResultFromCall()
    eventStore.requestAccess(to: EKEntityType.event, completion: {
      granted, error in
      if (granted) && (error == nil) {
        print("\nREMOVE EVENT:\ngranted \(granted)")
        
        let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        
        print("startDate: \(startDate) endDate:\(endDate)")
        rfc.notes = "REMOVE  title: \(title), startDate: \(startDate), endDate:\(endDate)"
        let eV = self.eventStore.events(matching: predicate) as [EKEvent]?
        
        if eV != nil {
          for i in eV! {
            
            if i.title.range(of: title) != nil {
              print("YES" )
              
              do {
                try self.eventStore.remove(i, span: EKSpan.thisEvent)
              } catch {
                print("Problem removing")
                rfc.status = "Problem removing"
                continue
              }
            }
            
          }
          rfc.e = eV
          handler(rfc)
        }
        
        
      }
    })
  }
  
  
  
  
}
