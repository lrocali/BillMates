//
//  Model.swift
//  BillMates
//
//  Created by Lucas Rocali on 4/26/15.
//  Copyright (c) 2015 Lucas Rocali. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import Parse
import ParseUI
import SystemConfiguration

// Essa eh a model
class Model {
    
    
    var addedUsers: [String] = [String]()
    
    var billObjects: NSMutableArray = NSMutableArray()
    
    var filteredBills: NSMutableArray = NSMutableArray()
    
    var userObject: PFUser?
    
    var groupObject : PFObject?
    
    var groupFriendsString : [String] = [String]()
    
    var debtObjects : NSMutableArray = NSMutableArray()
    
    var relations : [Relation] = [Relation]()
    
    var personalRelations : [Relation] = [Relation]()
    
    var imageToSave : UIImage?
    
    var imageTBNToSave : UIImage?
    
    var hasImg : Bool = false
    
    var connectionStatus : Bool? //true has connectio, false otherwise

    func refreshNetworkStatus() {
        if isConnectedToNetwork(){
            connectionStatus = true
        } else {
            connectionStatus = false
        }
    }
    func refreshData() {
        refreshNetworkStatus()
        //println(self.billObjects)
        //println(connectionStatus)
        var queryy = PFUser.query()
        queryy!.fromLocalDatastore()
            var user = queryy!.getObjectWithId(PFUser.currentUser()!.objectId!)
            self.userObject = user! as? PFUser
            //println(self.userObject)
            if(self.userObject != nil){
                var query = PFUser.query()
                var userr : PFUser = self.userObject!
                if (self.userObject != nil){
                    if userr["group"] != nil {
                        self.fetchAllObjects()
                        self.fetchAllObjectsFromLocalDataStore()
                    }
                }
            }
    }
    func fetchAllObjectsFromLocalDataStore(){
        
        
        //var query = PFUser.query()
        //var user = query!.getObjectWithId(PFUser.currentUser()!.objectId!) as! PFUser
        //self.userObject = user
        var user : PFUser = self.userObject!
        var queryBill: PFQuery = PFQuery(className: "Bill")
        queryBill.fromLocalDatastore()
        queryBill.whereKey("groupName", equalTo: user["group"]!)
        queryBill.findObjectsInBackgroundWithBlock { (objects,error) -> Void in
            if (error == nil){
                var temp: NSArray = objects! as NSArray
                ////println(temp)
                self.billObjects.removeAllObjects()
                 if temp.count > 0 {
                    self.billObjects = temp.mutableCopy() as! NSMutableArray
                    //println("\tbillObjects saved \(self.billObjects.count)")
                    NSNotificationCenter.defaultCenter().postNotificationName("load", object: nil)
                }
                
            } else {
                ////println(error?.userInfo)
                //println("ERROR NO FECTH FROM LOCAL - BILL")
            }
        }
        var queryGroup: PFQuery = PFQuery(className: "Group")
        queryGroup.fromLocalDatastore()
        queryGroup.whereKey("groupName", equalTo: user["group"]!)
        queryGroup.findObjectsInBackgroundWithBlock { (objects,error) -> Void in
            if (error == nil){
                var temp: NSArray = objects! as NSArray
                ////println(temp)
                if temp.count > 0 {
                    var aux : NSMutableArray = temp.mutableCopy() as! NSMutableArray
                    self.groupObject = aux.firstObject as! PFObject
                    self.groupFriendsString = self.groupObject!["groupFriends"] as! [String]
                    //println("\tgroupFRiensdsString saved \(self.groupFriendsString)")
                }
                
            } else {
                ////println(error?.userInfo)
                //println("ERROR NO FECTH FROM LOCAL - GROUP")
            }
            
        }
        var queryDebt : PFQuery = PFQuery(className: "Debts")
        queryDebt.fromLocalDatastore()
        queryDebt.whereKey("groupName", equalTo: user["group"]!)
        
        var temp: NSArray = queryDebt.findObjects() as! NSArray
        if temp.count > 0{
            self.debtObjects.removeAllObjects()
            self.debtObjects  = temp.mutableCopy() as! NSMutableArray
            //println("\tdebtObjects saved \(self.debtObjects)")
            if self.groupObject != nil {
                var groupFriends : [String] = self.groupObject!["groupFriends"] as! [String]
                if self.debtObjects.count != self.getNumOfDebts(groupFriends.count) {
                    //self.calculateDebts(true)
                    ////println("DEBTS DIFERENTS NA THREAD")
                } else {
                    //self.calculateDebts(true)
                    //println("DEBTS IGUAIS NA THREAD")
                }
                
            }
            
        }
    }
    
    func fetchAllObjects(){
        //println("FETCH LOCAL")
        if self.connectionStatus! {
            //println("NAO DA UNPIN")
            PFObject.unpinAllObjectsInBackgroundWithBlock(nil)
        
        var query = PFUser.query()
            //var user = query!.getObjectWithId(PFUser.currentUser()!.objectId!) as! PFUser
        var user : PFUser = self.userObject!
        //println(user)
        var queryBill: PFQuery = PFQuery(className: "Bill")
        queryBill.whereKey("groupName", equalTo: user["group"]!)
        
        queryBill.findObjectsInBackgroundWithBlock { (objects,error) -> Void in
            if (error == nil){
                PFObject.pinAllInBackground(objects,block:nil)
                self.fetchAllObjectsFromLocalDataStore()
            } else {
                //println("ERROR NO FECTH - BILL")
            }
        }
        
        var queryFriend: PFQuery = PFQuery(className: "Group")
        queryFriend.whereKey("groupName", equalTo: user["group"]!)
        
        queryFriend.findObjectsInBackgroundWithBlock { (objects,error) -> Void in
            if (error == nil){
                PFObject.pinAllInBackground(objects,block:nil)
                self.fetchAllObjectsFromLocalDataStore()
            } else {
                //println("ERROR NO FECTH - GROUP")
            }
            
        }
        
        var queryDebt : PFQuery = PFQuery(className: "Debts")
        queryDebt.whereKey("groupName", equalTo: user["group"]!)
        
        queryDebt.findObjectsInBackgroundWithBlock { (objects,error) -> Void in
            if (error == nil){
                PFObject.pinAllInBackground(objects,block:nil)
                self.fetchAllObjectsFromLocalDataStore()
            } else {
                //println("ERROR NO FECTH - DEBTS")
            }
            
        }
        }
        
    }
    func createGroup(groupName:String,groupKey:String) -> Bool{
        refreshNetworkStatus()
        
        var queryGroup: PFQuery = PFQuery(className: "Group")
        //queryGroup.fromLocalDatastore()
        queryGroup.whereKey("groupName", equalTo: groupName)
        
        var temp: NSArray = queryGroup.findObjects()! as NSArray
        if temp.count > 0 {
            return false
        }
        
        var object : PFObject!
        
        object = PFObject(className: "Group")
        
        object["whoCreate"] = PFUser.currentUser()!.username!
        
        object["groupName"] = groupName
        object["groupKey"] = groupKey
        
        var groupFriends : [String] = []
        groupFriends.append(PFUser.currentUser()!.username!)
        
        object["groupFriends"] = groupFriends
        
        var query = PFUser.query()
        var user = query!.getObjectWithId(PFUser.currentUser()!.objectId!) as! PFUser
        
        user["group"] = groupName
        
        if object.save() && user.save() {
            self.groupObject = object
            //println("\tgroup created \(self.groupObject)")
            return true
        } else {
            return false
        }
    }
    
    func joinGroupWhithoutLogin(name:String) -> Bool{
        refreshNetworkStatus()
        var query = PFUser.query()
        query!.fromLocalDatastore()
        query!.whereKey("username", equalTo: name)
        
        var temp : NSArray = query!.findObjects()! as NSArray
        
        if temp.count > 0 {
            return false
        }
        for friend in self.groupFriendsString {
            if friend == name {
                return false
            }
        }
        self.groupFriendsString.append(name)
        
        var groupFriendsString = self.groupFriendsString
        //var sortedNames = groupFriendsString.sorted { $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending }
        //println(sortedNames)
         //self.groupFriendsString = sortedNames
        groupObject!["groupFriends"] = self.groupFriendsString
        if connectionStatus! {
            if groupObject!.save(){
                refreshData()
                self.calculateDebts(true)
                //println("group joined without user\(self.groupObject)")
                return true
            } else {
                //println("problme to save")
                return false
            }
        } else {
            groupObject!.saveEventually()
            refreshData()
            self.calculateDebts(true)
            //println("group joined without user\(self.groupObject)")
            return true
            
        }
    }
    
    func joinGroup(groupName:String,groupKey:String) -> Bool{
        refreshNetworkStatus()
        var queryGroup: PFQuery = PFQuery(className: "Group")
        //queryGroup.fromLocalDatastore()
        queryGroup.whereKey("groupName", equalTo: groupName)
        
        var temp: NSArray = queryGroup.findObjects()! as NSArray
        
        //println(temp)
        var group : NSMutableArray = temp.mutableCopy() as! NSMutableArray
        
        if group.count > 0 {
            //println(group.objectAtIndex(0))
            var g : PFObject = group.objectAtIndex(0) as! PFObject
            
            var key : String = g["groupKey"] as! String
            
            if key != groupKey {
                return false
            }
            
            var groupFriends : [String] = g["groupFriends"] as! [String]
            
            groupFriends.append(PFUser.currentUser()!.username!)
            
            self.groupFriendsString = groupFriends
            var groupFriendsString = self.groupFriendsString
           // var sortedNames = groupFriendsString.sorted { $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending }
            //println(sortedNames)
            
            //self.groupFriendsString = sortedNames
            
            groupFriends = self.groupFriendsString
            g["groupFriends"] = groupFriends
            
            var query = PFUser.query()
            var user = query!.getObjectWithId(PFUser.currentUser()!.objectId!) as! PFUser
            
            user["group"] = groupName
            
            if g.save() && user.save(){
                self.groupObject = g
                //println("group joined \(self.groupObject)")
                return true
            } else {
                return false
            }
        }
        else {
           return false 
        }
    }
    func resetModel() {
        Static.instance = nil
        //self.billObjects = []
    }
    //Singleton
    private struct Static {
        static var instance: Model?
    }
    class var sharedInstance: Model {
        if (Static.instance == nil) {
            Static.instance = Model()
        }
        return Static.instance!
    }
    
    func deleteBill(index: Int) {
        refreshNetworkStatus()
        //println("Delete bill at \(index)")
        
        var bill = billObjects.objectAtIndex(index) as! PFObject
        
        var query = PFQuery(className:"Bill")
        query.fromLocalDatastore()
        query.getObjectInBackgroundWithId(bill.objectId!) {
            (bill: PFObject?, error: NSError?) -> Void in
            if error != nil {
                //println("ERRO PRA DELETAR")
            } else {
                if self.connectionStatus! {
                    bill?.delete()
                } else {
                    bill?.deleteEventually()
                }
                //self.billObjects.removeObjectAtIndex(index)
                self.calculateDebts(true)
            }
            
        }
        self.billObjects.removeObjectAtIndex(index)
    }
    
    func canDelete(username:String) -> Bool {
        for debt in self.debtObjects {
            var checkDebt : PFObject = debt as! PFObject
            var user1 : String = checkDebt["user1"] as! String
            var user2 : String = checkDebt["user2"] as! String
            var value : Float = checkDebt["value"] as! Float
            if (user1 == username || user2 == username) && value != 0 {
                //println("esse cara deve!!")
                return false
            }
        }
        return true
    }
    
    func deleteGroupOfUser() -> Bool{
        refreshNetworkStatus()
        var user : PFUser = self.userObject!
        var username : String = user["username"] as! String
        if canDelete(username) {
            user["group"] = "nil"
            if connectionStatus! {
                user.save()
            } else {
                //println("No connection")
                user.saveEventually()
            }
            self.resetModel()
            //billObjects = []
            return true
        } else {
            return false
        }
        
    }
    func deleteUserOfGroup(index: Int) -> Int{
        refreshNetworkStatus()
        //println(self.debtObjects)
        
        //println(self.groupFriendsString)
        var userToDelete : String = self.groupFriendsString[index]
        
        for debt in self.debtObjects {
            var checkDebt : PFObject = debt as! PFObject
            var user1 : String = checkDebt["user1"] as! String
            var user2 : String = checkDebt["user2"] as! String
            var value : Float = checkDebt["value"] as! Float
            if (user1 == userToDelete || user2 == userToDelete) && value != 0 {
                //println("esse cara deve!!")
                return 1
            }
        }
        var query = PFUser.query()
        query?.fromLocalDatastore()
        query!.whereKey("username", equalTo: userToDelete)
        
        var temp : NSArray = query!.findObjects()! as NSArray
       
        if temp.count > 0 {
            return 2
        }
 
        //println("Delete user at \(index)")
    
        self.groupFriendsString.removeAtIndex(index)
        
        self.groupObject!["groupFriends"] = self.groupFriendsString
        
        
        if connectionStatus! {
            self.groupObject!.save()
        } else {
            self.groupObject!.saveEventually()
        }
        self.calculateDebts(true)
        
        return 0
    }
    func resetImages() {
        hasImg = false
    }
    func setImages(imageToSet:UIImage) {
        imageToSave = imageToSet
        hasImg = true
    }
    
    func saveBill(#description:String, value:String) {
        refreshNetworkStatus()
        var object : PFObject!
        
        object = PFObject(className: "Bill")
        
        object["whoCreated"] = self.userObject!["username"] as! String
        
        object["description"] = description
        object["value"] = NSString(string: value).floatValue
        
        object["paidBy"] = self.userObject!.username
        
        object["sharedWith"] = addedUsers
        
        object["shouldPaid"] = addedUsers
        
        object["activated"] = true
        
        
        
        //let scaledImage = scaleImageWith(pickedImage)
        //var defautImg : UIImage = UIImage(named: "0")!
        
        //var query = PFUser.query()
        //var user = query!.getObjectWithId(PFUser.currentUser()!.objectId!) as! PFUser
        var user : PFUser = self.userObject!
        object["groupName"] =  user["group"]!
        
        
        if hasImg {
            //println("tem imagem pra salvar")
            var image : UIImage = self.imageToSave!
            var imageData = UIImagePNGRepresentation(image)
            var imageFile = PFFile(data:imageData)
            object["img"] = imageFile
            
            var imageTBN : UIImage = self.imageToSave!
            let widthTBN: CGFloat = 50.0
            let heightTBN: CGFloat = 50.0
            var sizeTBN = CGSizeMake(widthTBN, heightTBN)
            let scaleTBN: CGFloat = 1.0
            UIGraphicsBeginImageContextWithOptions(sizeTBN, false, scaleTBN) //---
            imageTBN.drawInRect(CGRect(origin: CGPointZero, size: sizeTBN))
            let scaledImageTBN = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            var imageTBNData = UIImagePNGRepresentation(scaledImageTBN)
            var imageTBNFile = PFFile(data:imageTBNData)
            object["imgTBN"] = imageTBNFile
            
            resetImages()
            
        }
        if connectionStatus! {
            object.saveInBackgroundWithBlock({
                (success:Bool,error:NSError?) -> Void in
                if (error == nil){
                    //println("Salvou!")
                    self.calculateDebts(true)
                }
                else {
                    //println("NAO SALVOU BILL")
                }
            })
        } else {
            object.saveEventually()
        }
        self.billObjects.addObject(object)
        //addedUsers.removeAll(keepCapacity: false)
    }
    
    func editBill(#description:String, value:String, billId: String,cellId:Int) -> Bool{
        refreshNetworkStatus()
        var queryBill: PFQuery = PFQuery(className: "Bill")
        queryBill.fromLocalDatastore()
        var billToEdit: PFObject! = queryBill.getObjectWithId(billId)
        
        if billToEdit != nil {
            //println(billToEdit)
            
            
            var sharedWith : [String] = billToEdit!["sharedWith"] as! [String]
            var shouldPaid : [String] = billToEdit!["shouldPaid"] as! [String]
            if sharedWith.count != shouldPaid.count {
                return false
            }
            billToEdit!["whoCreated"] = self.userObject!["username"] as! String
            
            billToEdit!["description"] = description
            billToEdit!["value"] = NSString(string: value).floatValue
            billToEdit!["sharedWith"] = self.addedUsers
            billToEdit!["shouldPaid"] = self.addedUsers
            if self.hasImg {
                //println("tem imagem pra salvar")
                var image : UIImage = self.imageToSave!
                var imageData = UIImagePNGRepresentation(image)
                var imageFile = PFFile(data:imageData)
                billToEdit!["img"] = imageFile
                
                var imageTBN : UIImage = self.imageToSave!
                let widthTBN: CGFloat = 50.0
                let heightTBN: CGFloat = 50.0
                var sizeTBN = CGSizeMake(widthTBN, heightTBN)
                let scaleTBN: CGFloat = 1.0
                UIGraphicsBeginImageContextWithOptions(sizeTBN, false, scaleTBN) //---
                imageTBN.drawInRect(CGRect(origin: CGPointZero, size: sizeTBN))
                let scaledImageTBN = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                var imageTBNData = UIImagePNGRepresentation(scaledImageTBN)
                var imageTBNFile = PFFile(data:imageTBNData)
                billToEdit!["imgTBN"] = imageTBNFile
                
                self.resetImages()
                
                
            }
            self.billObjects.removeObjectAtIndex(cellId)
            self.billObjects.insertObject(billToEdit!, atIndex: cellId)
            
            //self.billObjects.addObject(billToEdit!)
            self.calculateDebts(true)
            billToEdit!.saveEventually()
        } else {
            println("nao achou bill to edit")
            return false
            
        }
        return true
    
    }
    func addAddedUsers(name: String){
        self.addedUsers.append(name)
    }
    
    func removeAddedUsers(name:String){
        var index = -1
        for i in 0..<addedUsers.count {
            if (addedUsers[i] == name) {
                index = i
            }
        }
        if index >= 0{
            addedUsers.removeAtIndex(index)
        }
    }
    
    func isAddedUser(name:String) -> Bool {
        var index = -1
        for i in 0..<addedUsers.count {
            if (addedUsers[i] == name) {
                index = i
            }
        }
        if index >= 0{
            return true
        }
        return false
    }
    
    func isTotallyEmpty(text:String) -> Bool {
        let trimmed = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        return trimmed.isEmpty
    }
    
    func getNumOfDebts(n:Int) -> Int{
        var numOfDebts = 0
        for i in 1..<n{
            numOfDebts = numOfDebts + i
        }
        ////println("pra \(n) eh \(numOfDebts)")
        return numOfDebts
    }
    
    func createDebtRelations(groupFriends: [String],groupName:String,create:Bool) {
        refreshNetworkStatus()
        
        //var debtsToDelte : NSArray = self.debtObjects as NSArray
        /*
        var queryDebts: PFQuery = PFQuery(className: "Debts")
        //queryDebts.fromLocalDatastore()
        queryDebts.whereKey("groupName", equalTo: groupName)
        
        queryDebts.findObjectsInBackgroundWithBlock { (objects,error) -> Void in
            if (error == nil){
                var temp: NSArray = objects! as NSArray
                var refreshedDebts  = temp.mutableCopy() as! NSMutableArray
                if create{
                    for debt in refreshedDebts {
                        var pfdebt : PFObject = debt as! PFObject
                        if self.connectionStatus! {
                            pfdebt.delete()
                        } else {
                            pfdebt.deleteEventually()
                        }
                    }
                } else {
                    self.debtObjects = refreshedDebts
                }
                
            } else {
                //println("FUDEU NO REFRESH EM BACKGROUND")
            }
        }/*
        for debt in self.debtObjects {
            var debtToDelete : PFObject = debt as! PFObject
            debtToDelete.delete()
            
        }*/
        if create {
            self.debtObjects.removeAllObjects()
            for i in 1..<groupFriends.count {
                for j in (i+1)...groupFriends.count {
                    //println("Relation between \(i) and \(j)")
                    var object : PFObject!
                    object = PFObject(className: "Debts")
                    
                    var groupNameStr : String = String(i) + String(j)
                    object["debtId"] = groupNameStr
                    object["user1"] = groupFriends[i-1]
                    object["user2"] = groupFriends[j-1]
                    object["value"] = 0
                    object["groupName"] = groupName
                    self.debtObjects.addObject(object)
                    if connectionStatus! {
                        object.save()
                    } else {
                        object.saveEventually()
                    }
                }
            }
        }
        */
    }
    
    func getDebtId(paidBy:String,sharedUser:String,groupFriends:[String]) -> (debtId: String, direction: Int){
        // 1 = user 2 should pay to user 1
        // -1 = user 1 should pay to user 2
        var direction : Int = 0
        var indexUser1 : Int = -1
        var indexUser2 : Int = -1
        for i in 0..<groupFriends.count {
            if groupFriends[i] == paidBy {
                indexUser1 = i
            }
            if groupFriends[i] == sharedUser {
                indexUser2 = i
            }
        }
        var debtId : String = ""
        if indexUser1 < indexUser2 {
            debtId = String(indexUser1+1) + String(indexUser2+1)
            direction = 1
        } else {
            debtId = String(indexUser2+1) + String(indexUser1+1)
            direction = -1
        }
        return (debtId,direction)
    }
    
    func refreshDebts() {
        var groupFriends : [String] = self.groupFriendsString
        var groupName : String = self.groupObject!["groupName"] as! String
        refreshNetworkStatus()
        var localDebtStorage = Dictionary<String, Float>()
        localDebtStorage.removeAll(keepCapacity: false)
        for i in 1..<groupFriends.count {
            for j in (i+1)...groupFriends.count {
                var dbtID : String = String(i) + String(j)
                localDebtStorage[dbtID] = 0.0 as Float
            }
        }
        for billObject in self.billObjects {  //----
            var bill : PFObject = billObject as! PFObject
            
            var paidBy : String = bill["paidBy"] as! String
            var sharedWith : [String] = bill["sharedWith"] as! [String]
            var shouldPaid : [String] = bill["shouldPaid"] as! [String]
            var value : Float = bill["value"] as! Float
            if shouldPaid.count == 1 {
                if  shouldPaid[0] == paidBy{
                    bill["activated"] = false
                    bill.saveEventually()
                }
            }
            if shouldPaid.count == 0 {
                    bill["activated"] = false
                    bill.saveEventually()
            }
            ////println(paidBy + sharedWith[0])
            for userThatShouldPay in shouldPaid {
                if userThatShouldPay != paidBy {
                    var (dbId,direction) = getDebtId(paidBy, sharedUser: userThatShouldPay, groupFriends: groupFriends)
                    localDebtStorage[dbId] = localDebtStorage[dbId]! + value*Float(direction)/Float(sharedWith.count)
                }
            }
        }
        for debt in self.debtObjects {
            var value : Float = 0
            var debtObj : PFObject = debt as! PFObject
            for localDebt in localDebtStorage {
                //var debtIdStr : String = debt["debtId"] as String
                if debtObj["debtId"] as! String == localDebt.0{
                    value = localDebt.1
                }
            }
            debtObj["value"] = value
            debtObj.saveEventually()
        }
        self.generateDebtStrings()
    }
    
    func filterBillsByRelation(user1:String,user2:String){
        refreshNetworkStatus()
        self.filteredBills.removeAllObjects()
        //println("FILTER FOR \(user1) AND \(user2)")
        var bills = self.billObjects
        for bill in bills {
            var paidBy: String = bill["paidBy"] as! String
            var sharedWith: [String] = bill["sharedWith"] as! [String]
            if user1 == paidBy {
                for sharedUser in sharedWith {
                    if user2 == sharedUser {
                        filteredBills.addObject(bill)
                    }
                }
            }
            if user2 == paidBy {
                for sharedUser in sharedWith {
                    if user1 == sharedUser {
                        filteredBills.addObject(bill)
                    }
                }
            }
        }
        //println(filteredBills)
    }
    func getPersonalRelations(){
        self.personalRelations.removeAll(keepCapacity: false)
        var userName : String = userObject!["username"] as! String
        for relation in self.relations {
            if relation.user1 == userName {
                self.personalRelations.append(relation)
            }
            if relation.user2 == userName {
                var auxRelation = relation
                auxRelation.user1 = relation.user2
                auxRelation.user2 = relation.user1
                auxRelation.value = (-1)*auxRelation.value
                self.personalRelations.append(auxRelation)
            }
        }
    }
    func abs(n:Float) -> Float{
        var absn = n
        if n < 0 {
            absn = n*(-1)
        }
        return absn
    }
    func generateDebtStrings() {
        //println("GENERATE")
        //self.relations = []
        var debts = self.debtObjects
        self.relations.removeAll(keepCapacity: false)
        var debtStr : String = ""
        for debt in debts {
            var user1 : String = debt["user1"] as! String
            var user2 : String = debt["user2"] as! String
            var idStr : String = debt["debtId"] as! String
            var idInt : Int = idStr.toInt()!
            var value : Float = debt["value"] as! Float
            if value < 0 {
                debtStr = user1 + " --> " + user2 + " = " +  String(format: "%.2f",value*(-1))
            } else if value > 0{
                debtStr = user1 + " <-- " + user2 + " = " +  String(format: "%.2f",value)
            } else {
                debtStr =  user1 + " -- " + user2 + " = " +  String(format: "%.2f",value)
            }
            var relation : Relation = Relation()
            relation.debtStringCell = debtStr
            relation.user1 = user1
            relation.user2 = user2
            relation.value = value
            
            relation.id = idInt
            self.relations.append(relation)
        }
        //println(self.relations)
        var relationsToOrder = self.relations
        
        
        let sortedRelations = relationsToOrder.sorted { (lhs:Relation, rhs:Relation) in
            //return lhs.user1.localizedCaseInsensitiveCompare(rhs.user1) == NSComparisonResult.OrderedAscending
            var value1 = self.abs(lhs.value)
            var value2 = self.abs(rhs.value)

            return  value1 > value2        }
        self.relations = sortedRelations
        for relation in self.relations{
            //println(relation.debtStringCell)
        }
        NSNotificationCenter.defaultCenter().postNotificationName("loadDebts", object: nil)
    }
    
    func calculateDebts(background:Bool) {
        refreshNetworkStatus()
        if self.groupObject != nil {
            var groupFriends : [String] = self.groupFriendsString
            if self.debtObjects.count != getNumOfDebts(groupFriends.count) {
                println("\n 1 ≠ DIFERENTE DO PARSE BORA - VER \nDEVERIA TER: \(getNumOfDebts(groupFriends.count)) \nTEM: \(self.debtObjects.count)\n")
                var userGroupName : String = self.groupObject!["groupName"] as! String
                var queryDebt : PFQuery = PFQuery(className: "Debts")
                queryDebt.whereKey("groupName", equalTo: userGroupName)
                var tempDebts : NSArray = queryDebt.findObjects()! as NSArray

                var refreshedDebts : NSMutableArray = tempDebts.mutableCopy() as! NSMutableArray
                self.debtObjects = refreshedDebts
                
                var queryGroup: PFQuery = PFQuery(className: "Group")
                queryGroup.whereKey("groupName", equalTo: userGroupName)
                var NSGroup : NSArray = queryGroup.findObjects()! as NSArray
                var refreshedGroup : PFObject = NSGroup.firstObject as! PFObject
                var refreshedGroupFriends : [String] = refreshedGroup["groupFriends"] as! [String]
                self.groupFriendsString = refreshedGroupFriends
                
                var numOfRefreshedDebts = refreshedDebts.count
                var numOfDebtsThatShouldHave = getNumOfDebts(refreshedGroupFriends.count)
                var numOfDebtsThatShouldHaveForLessOneUser = getNumOfDebts(refreshedGroupFriends.count - 1)
                
                if numOfRefreshedDebts == numOfDebtsThatShouldHave {
                    //refresh
                     println("\n 1 ≠ = DEBTS UPDATE, REFRESH - VER \nDEVERIA TER: \(numOfDebtsThatShouldHave) \nTEM: \(numOfRefreshedDebts)\n")
                    refreshDebts()
                    
                } else if numOfRefreshedDebts == numOfDebtsThatShouldHaveForLessOneUser  {
                    println("\n 1 ≠ < ADICIONAR RELACAO PRO ULTIMO USUAIO ADICIONADO  - VER \nDEVERIA TER: \(numOfDebtsThatShouldHave) \nTEM: \(numOfRefreshedDebts)\n")
                    //add new debts for new user
                    var indexUser : Int = self.groupFriendsString.count
                    for i in 1..<self.groupFriendsString.count {
                        var object : PFObject!
                        object = PFObject(className: "Debts")
                        
                        var groupNameStr : String = String(i) + String(indexUser)
                        object["debtId"] = groupNameStr
                        object["user1"] = groupFriends[i-1]
                        object["user2"] = groupFriends[indexUser-1]
                        object["value"] = 0
                        object["groupName"] = userGroupName
                        self.debtObjects.addObject(object)
                        object.saveEventually()
                    }
                } else {
                    
                    //delete all, aguar fi, vai chupar pica grande grossa
                    println("\n 1 ≠ > USUARIO DELETADO DELETAR TUDO E CRIAR  - VER \nDEVERIA TER: \(numOfDebtsThatShouldHave) \nTEM: \(numOfRefreshedDebts)\n")
                    for debt in self.debtObjects {
                        var debtPF : PFObject = debt as! PFObject
                        debtPF.deleteInBackground()
                    }
                    self.debtObjects.removeAllObjects()
                    
                    for i in 1..<self.groupFriendsString.count {
                        for j in (i+1)...self.groupFriendsString.count {
                            ////println("CREATE >>>> Relation between \(i) and \(j)")
                            var object : PFObject!
                            object = PFObject(className: "Debts")
                            
                            var groupNameStr : String = String(i) + String(j)
                            object["debtId"] = groupNameStr
                            object["user1"] = groupFriends[i-1]
                            object["user2"] = groupFriends[j-1]
                            object["value"] = 0
                            object["groupName"] = userGroupName
                            self.debtObjects.addObject(object)
                            object.saveEventually()
                        }
                    }
                    //refresh
                    refreshDebts()

                }
                refreshDebts()
            } else {
                //refresh
                 println("\n 1 = JUST REFRESH \nDEVERIA TER: \(getNumOfDebts(groupFriends.count)) \nTEM: \(self.debtObjects.count)\n")
                refreshDebts()
            }
        }
        
        
        
        
        /*refreshNetworkStatus()
        if self.groupObject != nil{
            
            var userGroupName : String = self.groupObject!["groupName"] as! String
            var groupFriends : [String] = self.groupFriendsString
            //println("DDEBT OBJECTS : \(self.debtObjects.count)")
            //println(self.getNumOfDebts(groupFriends.count))
            var queryDebt : PFQuery = PFQuery(className: "Debts")
            //queryDebt.fromLocalDatastore()
            queryDebt.whereKey("groupName", equalTo: userGroupName)

            if background {
                queryDebt.findObjectsInBackgroundWithBlock{(objects,error) -> Void in
                if (error == nil){
                    var temp: NSArray = objects! as NSArray
                    //println("NUMERO DE DEBTS NO PARSE: \(temp.count)")
                    if temp.count != self.getNumOfDebts(groupFriends.count) {
                        var queryGroup: PFQuery = PFQuery(className: "Group")
                        queryGroup.whereKey("groupName", equalTo: userGroupName)
                        var NSGroup : NSArray = queryGroup.findObjects()! as NSArray
                        var refreshedGroup : PFObject = NSGroup.firstObject as! PFObject
                        var refreshedGroupFriends : [String] = refreshedGroup["groupFriends"] as! [String]
                        self.groupFriendsString = refreshedGroupFriends
                        if temp.count != self.getNumOfDebts(refreshedGroupFriends.count){
                            //println("\t\t\t\t\t#############CREATE RELATIONS")
                            self.createDebtRelations(refreshedGroupFriends, groupName: userGroupName, create: true)
                        } else {
                            self.createDebtRelations(refreshedGroupFriends, groupName: userGroupName, create: false)
                        }
                    }
                    //println("GET RELATIONS")
                    self.refreshDebts(groupFriends,groupName:userGroupName,backGround:background)
                    
                } else {
                    //println("FUDEU NO REFRESH EM BACKGROUND")
                }

                }
            } else {
                var temp: NSArray = queryDebt.findObjects()! as NSArray
                //println("NUMERO DE DEBTS NO PARSE: \(temp.count)")
                if temp.count != getNumOfDebts(groupFriends.count) {
                    
                    var queryGroup: PFQuery = PFQuery(className: "Group")
                    queryGroup.fromLocalDatastore()
                    queryGroup.whereKey("groupName", equalTo: userGroupName)
                    var NSGroup : NSArray = queryGroup.findObjects()! as NSArray
                    var refreshedGroup : PFObject = NSGroup.firstObject as! PFObject
                    //println("\t\t\t\t\t#############CREATE RELATIONS")
                    var refreshedGroupFriends : [String] = refreshedGroup["groupFriends"] as! [String]
                    self.groupFriendsString = refreshedGroupFriends
                    if temp.count < self.getNumOfDebts(refreshedGroupFriends.count){
                        //println("\t\t\t\t\t#############CREATE RELATIONS DELETEI USER")
                        self.createDebtRelations(refreshedGroupFriends, groupName: userGroupName, create: true)
                    } else {
                        self.createDebtRelations(refreshedGroupFriends, groupName: userGroupName, create: false)
                    }
                }
                //println("GET RELATIONS")
                refreshDebts(groupFriends,groupName:userGroupName,backGround:background)
            }
            
            
            //generateDebtStrings()
            //println("FINISH TO CALCULATE \(self.relations)")
        }*/
    }
    
    func findIndex(names:[String],name:String) -> Int {
        var index = -1
        for i in 0..<names.count {
            if names[i] == name {
                index = i
            }
        }
        return index
    }
    
    func settleUp(user1:String,user2:String) {
        println(user1 + " " + user2)
        println(self.filteredBills)
        for bill in self.filteredBills {
            var shouldPaid : [String] = bill["shouldPaid"] as! [String]
            if user1 == bill["paidBy"] as! String {
                println(findIndex(shouldPaid, name: user1))
                if findIndex(shouldPaid, name: user1) >= 0 {
                    shouldPaid.removeAtIndex(findIndex(shouldPaid, name: user1))
                }
            }
            if user2 == bill["paidBy"] as! String {
                println(findIndex(shouldPaid, name: user2))
                if findIndex(shouldPaid, name: user2) >= 0 {
                    shouldPaid.removeAtIndex(findIndex(shouldPaid, name: user2))
                }
            }
            
            for user in shouldPaid {
                if user1 == user {
                    println(findIndex(shouldPaid, name: user1))
                    if findIndex(shouldPaid, name: user1) >= 0 {
                        shouldPaid.removeAtIndex(findIndex(shouldPaid, name: user1))
                    }
                }
                if user2 == user {
                    println(findIndex(shouldPaid, name: user2))
                    if findIndex(shouldPaid, name: user2) >= 0 {
                        shouldPaid.removeAtIndex(findIndex(shouldPaid, name: user2))
                    }
                }
            }
            //bill["shouldPaid"] = shouldPaid
            var PFBill : PFObject = bill as! PFObject
            PFBill["shouldPaid"] = shouldPaid
            PFBill.saveEventually()
        }
        //refreshData()
    }
    
    func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0)).takeRetainedValue()
        }
        
        var flags: SCNetworkReachabilityFlags = 0
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == 0 {
            return false
        }
        
        let isReachable = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        
        return (isReachable && !needsConnection) ? true : false
    }
    
    
   
}
