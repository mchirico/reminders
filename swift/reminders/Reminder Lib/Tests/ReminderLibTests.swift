
import XCTest
import EventKit
@testable import reminders


class reminderLibTests: XCTestCase {
  
  let rLib = Reminder()
  let TestTitle = "Bozo Entry"
  
  
  override func setUp() {
    let expectation = self.expectation(description: "Add Cal Event")
    
    let dateString0 = "2018-11-5 9:56:25pm"
    let dateString1 = "2018-11-5 11:21:25pm"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ssa" //Input Format
    dateFormatter.timeZone = TimeZone.current
    let startDate = dateFormatter.date(from: dateString0)
    let endDate = dateFormatter.date(from: dateString1)
    
    let rLib = Reminder()
    
    rLib.addCalEvent(title: self.TestTitle, notes: "Notes on Bozo", startDate: startDate!, endDate: endDate!) {
      (h) in
      print(h)
      print("\n\n............****\n\n")
      XCTAssert(h.status == "Saved Event", "Event not saved")
      
      expectation.fulfill()
    }
    
    
    waitForExpectations(timeout: 5, handler: nil)
    
  }
  
  override func tearDown() {
    
    let expectation = self.expectation(description: "Get Events")
    
    let dateString0 = "2018-11-3 9:56:25pm"
    let dateString1 = "2018-11-14 11:21:25pm"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ssa" //Input Format
    dateFormatter.timeZone = TimeZone.current
    let startDate = dateFormatter.date(from: dateString0)
    let endDate = dateFormatter.date(from: dateString1)
    
    let rLib = Reminder()
    
    rLib.removeEvent(title: self.TestTitle, startDate: startDate!, endDate: endDate!) {
      
      h in print("\(String(describing: h))")
      expectation.fulfill()
      
    }
    waitForExpectations(timeout: 5, handler: nil)
    
  }
  
  
  func PrEvents(rfc: Reminder.ResultFromCall) {
    print("....\n\n")
    var found_Daylight_Savings_Entry = false
    if let events = rfc.e {
      print("\n\n")
      for i in events {
        print("title: \(String(describing: i.title!))")
        print("date: \(String(describing: i.startDate!))")
        
        if i.title!.range(of: "Daylight Saving Time End") != nil {
          found_Daylight_Savings_Entry = true
        }
      }
      XCTAssert(found_Daylight_Savings_Entry == true, "Can't find end Daylight Saving Time End")
      return
      
    }
    print("NO GOOD....\n\n")
    XCTFail()
  }
  
  
  func testReminderFunctions() {
    
    let expectation = self.expectation(description: "Add reminder")
    var alarmTime = Date().addingTimeInterval(1*60*24*3)
    let rLib = Reminder()
    
    rLib.addReminder(title: "Bozo call home", notes: "Notes for Bozo",
                     priority: 1, alarmTime: alarmTime) {
                      
                      (rfc) in
                      XCTAssert(rfc.status == "Reminder saved",
                                "Reminder not saved")
                      expectation.fulfill()
                      
    }
    
    wait(for: [expectation], timeout: 3.0)
    
    
    // Now get our reminder
    
    let startDate = Date().addingTimeInterval(60*24*2)
    let endDate = Date().addingTimeInterval(1*60*24*4)
    let expectation2 = self.expectation(description: "Query reminders")
    
    rLib.getReminders(startDate: startDate, endDate: endDate) {
      
      (rfc) in
      var correctTitle = false
      for i in rfc.r! {
        if let title = i.title {
          if title == "Bozo call home" {
            correctTitle = true
          }
        }
        XCTAssert(correctTitle, "Couldn't find reminder")
      }
      expectation2.fulfill()
    }
    wait(for: [expectation2], timeout: 3.0)
    
    
    // Now update it
    let expectation3 = self.expectation(description: "Update reminder")
    alarmTime = Date().addingTimeInterval(1*60*24*5)
    rLib.updateReminders(title: "Bozo call home", newTitle: "Bozo call dog", newNotes: "new Notes", newPriority: 3, newAlarmTime: alarmTime, startDate: startDate, endDate: endDate) {
      
      (rfc) in
      expectation3.fulfill()
      
    }
    wait(for: [expectation3], timeout: 3.0)
    
    // Delete
    let expectation4 = self.expectation(description: "Remove reminders")
    
    rLib.removeReminders(title:"Bozo call dog", startDate: startDate, endDate: endDate) {
      
      (rfc) in
      var correctTitle = false
      var modifiedTitle = true
      for i in rfc.r! {
        if let title = i.title {
          if title == "Bozo call dog" {
            correctTitle = true
          }
          if title == "Bozo call home" {
            modifiedTitle = false
          }
        }
        XCTAssert(correctTitle, "reminder didn't get delete")
        XCTAssert(modifiedTitle, "reminder didn't get modified")
      }
      expectation4.fulfill()
    }
    wait(for: [expectation4], timeout: 3.0)
  }
  
  
  // Grab Daylight_Savings_Entry
  //   should work on all simulators
  func testGetEvents() {
    
    let expectation = self.expectation(description: "Get Events")
    
    let dateString0 = "2018-11-3 9:56:25pm"
    let dateString1 = "2018-11-4 11:21:25pm"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ssa" //Input Format
    dateFormatter.timeZone = TimeZone.current
    let startDate = dateFormatter.date(from: dateString0)
    let endDate = dateFormatter.date(from: dateString1)
    
    let rLib = Reminder()
    
    rLib.getEvents(startDate: startDate!,endDate: endDate!) {
      (rfc) in self.PrEvents(rfc: rfc)
      
      expectation.fulfill()
    }
    
    // Need way to delay
    // Ref: https://www.swiftbysundell.com/posts/unit-testing-asynchronous-swift-code
    waitForExpectations(timeout: 5, handler: nil)
    
  }
  
  
  func testRemoveEvent() {
    
    let expectation = self.expectation(description: "Get Events")
    
    let dateString0 = "2018-11-3 9:56:25pm"
    let dateString1 = "2018-11-4 11:21:25pm"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ssa" //Input Format
    dateFormatter.timeZone = TimeZone.current
    let startDate = dateFormatter.date(from: dateString0)
    let endDate = dateFormatter.date(from: dateString1)
    
    let rLib = Reminder()
    
    rLib.removeEvent(title: "Test123-reminderLib", startDate: startDate!, endDate: endDate!) {
      
      h in print("\(String(describing: h))")
      expectation.fulfill()
      
    }
    waitForExpectations(timeout: 5, handler: nil)
    
    
    
  }

  
  func testAddCalEvent() {
    
    let expectation = self.expectation(description: "Add Cal Event")
    
    let dateString0 = "2018-11-5 9:56:25pm"
    let dateString1 = "2018-11-5 11:21:25pm"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ssa" //Input Format
    dateFormatter.timeZone = TimeZone.current
    let startDate = dateFormatter.date(from: dateString0)
    let endDate = dateFormatter.date(from: dateString1)
    
    let rLib = Reminder()
    
    rLib.addCalEvent(title: self.TestTitle, notes: "Notes on Bozo", startDate: startDate!, endDate: endDate!) {
      (h) in
      print(h)
      XCTAssert(h.status == "Saved Event", "Event not saved")
      expectation.fulfill()
    }
    waitForExpectations(timeout: 5, handler: nil)
    
  }

  
  func testGetSumMulOf() {
    let expectation = self.expectation(description: "Sum up values")
    getSumMulOf(array: [16,756,442,6,23]) { (result) in
      print(result)
      XCTAssert(result[0] == 1243, "Sum should equal 1243")
      XCTAssert(result[1] == 737807616, "Sum should equal 737807616")
      expectation.fulfill()
      return result[0]+result[1]
    }
    waitForExpectations(timeout: 3, handler: nil)
  }

  
  func testExample() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}
