import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  void loadContacts() {
    contacts = StorageService.getAllContacts();
    setState(() {});
  }

  void addContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    _showContactDialog(
      title: "Add Emergency Contact",
      nameController: nameController,
      phoneController: phoneController,
      onSave: () async {
        if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
        await StorageService.addContact(
          Contact(name: nameController.text, phone: phoneController.text),
        );
        if (mounted) Navigator.pop(context);
        loadContacts();
      },
    );
  }

  void editContact(int index) {
    final contact = contacts[index];
    final nameController = TextEditingController(text: contact.name);
    final phoneController = TextEditingController(text: contact.phone);

    _showContactDialog(
      title: "Edit Contact",
      nameController: nameController,
      phoneController: phoneController,
      onSave: () async {
        if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
        contact.name = nameController.text;
        contact.phone = phoneController.text;
        await contact.save();
        if (mounted) Navigator.pop(context);
        loadContacts();
      },
    );
  }

  /// 🎨 Reusable Premium Dialog for Add/Edit
  void _showContactDialog({
    required String title,
    required TextEditingController nameController,
    required TextEditingController phoneController,
    required VoidCallback onSave,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: "Contact Name",
                prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF4A90E2)),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number",
                prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF4A90E2)),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void callContact(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch phone dialer.")),
          );
        }
      }
    } catch (e) {
      print("Error launching dialer: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Premium soft background
      appBar: AppBar(
        title: const Text("Emergency Contacts", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addContactDialog,
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_ic_call_rounded, color: Colors.white),
        label: const Text("Add Contact", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: contacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                    ),
                    child: Icon(Icons.contact_phone_rounded, size: 60, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 20),
                  Text("No contacts added yet.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text("Tap the button below to add one.", style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 100), // Extra bottom padding for FAB
              physics: const BouncingScrollPhysics(),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final c = contacts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // 🧑 Avatar Profile
                        Container(
                          height: 55,
                          width: 55,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF4A90E2).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              c.name.isNotEmpty ? c.name[0].toUpperCase() : "?",
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // 📝 Name & Phone
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.phone,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),

                        // ⚙️ Actions (Edit / Delete / Call)
                        Row(
                          children: [
                            // Edit
                            GestureDetector(
                              onTap: () => editContact(index),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                                child: const Icon(Icons.edit_rounded, color: Color(0xFF4A90E2), size: 20),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delete
                            GestureDetector(
                              onTap: () async {
                                await StorageService.deleteContact(index);
                                loadContacts();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252), size: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 🔥 MASSIVE CALL BUTTON
                            GestureDetector(
                              onTap: () => callContact(c.phone),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: const Icon(Icons.call_rounded, color: Colors.white, size: 26),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}