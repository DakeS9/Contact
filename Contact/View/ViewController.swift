//
//  ViewController.swift
//  Contact
//
//  Created by Dauren Sunnatulla on 30.11.2022.
//

import UIKit

class ViewController: UIViewController {
    
    
    @IBOutlet weak var segmentedControll: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var arrayOfContactGroup: [ContactGroup] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    /// Объект от структуры ContactManager
    let contactManager = ContactManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.register(UINib(nibName: "ContactTableViewCell", bundle: nil), forCellReuseIdentifier: ContactTableViewCell.identifier)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl!.addTarget(self, action: #selector(reloadDataSource), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadDataSource()
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        reloadDataSource()
    }
    
    @IBAction func addContacts(_ sender: Any) {
        let alertController = UIAlertController.init(title: "Add Contact", message: nil, preferredStyle: .alert)
        alertController.addTextField { textFiled in
            textFiled.placeholder = "First name"
        }
        alertController.addTextField { textFiled in
            textFiled.placeholder = "Last name"
        }
        alertController.addTextField { textFiled in
            textFiled.placeholder = "Phone number"
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            guard let firstName: String = alertController.textFields![0].text, !firstName.isEmpty else {
                self.showErrorAlert(message: "First name is empty")
                return
            }
            guard let lastName: String = alertController.textFields![1].text, !lastName.isEmpty else {
                self.showErrorAlert(message: "Last name is empty")
                return
            }
            guard let phone: String = alertController.textFields![2].text, !phone.isEmpty else {
                self.showErrorAlert(message: "Phone is empty")
                return
            }
            
            let contact = Contact(firstName: firstName, lastName: lastName, phone: phone)
            self.add(contact: contact)
        }
        alertController.addAction(addAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        
        present(alertController, animated: true)
    }
    
    func showErrorAlert(message: String) {
        let errorAlertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Okay", style: .default)
        errorAlertController.addAction(okAction)
        
        present(errorAlertController, animated: true)
    }
    
    func add(contact: Contact) {
        contactManager.add(contact: contact)
        self.reloadDataSource()
    }
    
    @objc
    func reloadDataSource() {
        tableView.refreshControl!.beginRefreshing()
        
        var dictionary: [String: [Contact]] = [:]
        
        let allContacts = contactManager.getAllContact()
        
        allContacts.forEach { contact in
            
            var key: String!
            
            if segmentedControll.selectedSegmentIndex == 0 {
                key = String(contact.firstName.first!)
            } else if segmentedControll.selectedSegmentIndex == 1 {
                key = String(contact.lastName.first!)
            }
            
            if var existingContact = dictionary[key] {
                existingContact.append(contact)
                dictionary[key] = existingContact
            } else {
                dictionary[key] = [contact]
            }
        }
        
        var arrayOfContactGroup: [ContactGroup] = []
        
        let alphabeticallyOrderedKeys: [String] = dictionary.keys.sorted { key1, key2 in
            return key1 < key2
        }
        alphabeticallyOrderedKeys.forEach { key in
            
            let contacts = dictionary[key]
            let contactGroup = ContactGroup(title: key, contacts: contacts!)
            arrayOfContactGroup.append(contactGroup)
        }
        tableView.refreshControl!.endRefreshing()
        self.arrayOfContactGroup = arrayOfContactGroup
    }

    func getContact(indexPath: IndexPath) -> Contact {
        let contactGroup = arrayOfContactGroup[indexPath.section]
        let contact = contactGroup.contacts[indexPath.row]
        return contact
    }
    
    func deleteContact(indexPath: IndexPath) {
        let deletedContact = arrayOfContactGroup[indexPath.section].contacts.remove(at: indexPath.row)
        
        if arrayOfContactGroup[indexPath.section].contacts.count < 1  {
            arrayOfContactGroup.remove(at: indexPath.section)
        }
        
        contactManager.delete(contactToDelete: deletedContact)
    }
}

// Расширение для ViewController и подписка на протокол UITableViewDelegate
extension ViewController: UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return arrayOfContactGroup.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfContactGroup[section].contacts.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.identifier, for: indexPath) as! ContactTableViewCell
        let contact = getContact(indexPath: indexPath)
        
        if segmentedControll.selectedSegmentIndex == 0 {
            cell.titleLabel.text = "\(contact.firstName) \(contact.lastName)"
        } else if segmentedControll.selectedSegmentIndex == 1 {
            cell.titleLabel.text = "\(contact.lastName) \(contact.firstName)"
        }
        return cell
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return arrayOfContactGroup[section].title
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteContact(indexPath: indexPath)
        }
    }
    
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let contact = getContact(indexPath: indexPath)
        let contactViewController = ContactViewController()
        contactViewController.contact = contact
        navigationController?.pushViewController(contactViewController, animated: true)
    }
    
}

struct Contact: Codable {
    let firstName: String
    let lastName: String
    let phone: String
}

struct ContactGroup {
    let title: String
    var contacts: [Contact]
}

struct ContactManager {
    let  allContactsKey: String = "allContactKey"
    
    let userDefaults: UserDefaults = UserDefaults.standard
    
    func getAllContact() -> [Contact] {
        var allContacts: [Contact] = []
        
        if let data = userDefaults.object(forKey: allContactsKey) as? Data {
            
            do {
                
                let decoder = JSONDecoder()
                allContacts = try decoder.decode([Contact].self, from: data)
            } catch {
                print("could'n decode given data to [Contact] with error:\(error.localizedDescription)")
            }
        }
        return allContacts
    }
    
    func add(contact: Contact) {
        var allContacts = getAllContact()
        
        allContacts.append(contact)
        
        save(allContacts: allContacts)
    }
    
    func edit(contactToEdit: Contact, editedContact: Contact) {
        var allContacts = getAllContact()
        
        for index in 0..<allContacts.count {
            let contact = allContacts[index]
            
            if contact.firstName == contactToEdit.firstName && contact.lastName == contactToEdit.lastName && contact.phone == contactToEdit.phone {
                
                allContacts.remove(at: index)
                allContacts.insert(editedContact, at: index)
                
                break
            }
        }
        save(allContacts: allContacts)
    }
    
    func delete(contactToDelete: Contact) {
        var allContact = getAllContact()
        for index in 0..<allContact.count {
            
            let contact = allContact[index]
            
            if contact.firstName == contactToDelete.firstName && contact.lastName == contactToDelete.lastName && contact.phone == contactToDelete.phone {
                allContact.remove(at: index)
                
                break
            }
        }
        save(allContacts: allContact)
    }
    
    func save(allContacts: [Contact]) {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(allContacts)
            
            userDefaults.set(encodedData, forKey: allContactsKey)
        } catch {
            print("Could'n encode given [Contacts] ingo data with error\(error.localizedDescription)")
        }
    }
}


extension String {
    
    func isValidPhoneNumber() -> Bool{
        
        let regEx = "^\\+(?:[0-9]?){6,14}[0-9]$"
        let phoneCheck = NSPredicate(format: "SELF MATCHES[c] %@", regEx)
        
        return phoneCheck.evaluate(with: self)
    }
}
