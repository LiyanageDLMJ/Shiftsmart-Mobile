// import 'package:flutter/material.dart';
// import 'package:shiftsmart/services/emergency_contact_service.dart';

// class EmployeeAddEmergencyContact extends StatefulWidget {
//   const EmployeeAddEmergencyContact({super.key});

//   @override
//   State<EmployeeAddEmergencyContact> createState() =>
//       _EmployeeAddEmergencyContactState();
// } 

// class _EmployeeAddEmergencyContactState
//     extends State<EmployeeAddEmergencyContact> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _relationshipController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _relationshipController.dispose();
//     _phoneController.dispose();
//     _emailController.dispose();
//     _addressController.dispose();
//     super.dispose();
//   }

//   void _clearForm() {
//     _nameController.clear();
//     _relationshipController.clear();
//     _phoneController.clear();
//     _emailController.clear();
//     _addressController.clear();
//   }

//   // Save contact information
//   Future<void> _saveContact() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         final contact = {
//           'name': _nameController.text,
//           'relationship': _relationshipController.text,
//           'phone': _phoneController.text,
//           'email': _emailController.text,
//           'address': _addressController.text,
//           'isPrimary': true, // Default to primary for simplicity
//         };

//         // Save contact to the backend via service
//         await EmergencyContactService().addContact(contact);

//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Emergency contact added successfully')),
//         );

//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error adding contact: ${e.toString()}')),
//         );
//         Navigator.pop(context);

//       } finally {
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;

//     return SafeArea(
//       child: Center(
//         child: Container(
//           margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//           padding: const EdgeInsets.all(16),
//           constraints: BoxConstraints(
//             maxHeight: screenHeight * 0.9,
//             maxWidth: 500,
//           ),
//           decoration: BoxDecoration(
//             color: Colors.black.withValues(alpha: 0.8),
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Material(
//             color: Colors.transparent,
//             child: Column(
//               children: [
//                 _headerSection(),
//                 const SizedBox(height: 10),
//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: _formSection(),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _headerSection() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text(
//             "Add Emergency Contact",
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 20,
//             ),
//           ),
//           Image.asset(
//             'assets/Siren.png',
//             color: const Color(0xFF3498DB),
//             width: 35,
//             height: 35,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _formSection() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildLabel("Full Name"),
//             _buildTextField(
//               controller: _nameController,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter a name';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             _buildLabel("Relationship"),
//             _buildTextField(
//               controller: _relationshipController,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter relationship';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             _buildLabel("Mobile Number"),
//             _buildTextField(
//               controller: _phoneController,
//               keyboardType: TextInputType.phone,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter a phone number';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             _buildLabel("Email"),
//             _buildTextField(
//               controller: _emailController,
//               keyboardType: TextInputType.emailAddress,
//               validator: (value) {
//                 if (value != null && value.isNotEmpty) {
//                   if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
//                       .hasMatch(value)) {
//                     return 'Please enter a valid email';
//                   }
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             _buildLabel("Address"),
//             _buildTextField(
//               controller: _addressController,
//               maxLines: 2,
//             ),
//             const SizedBox(height: 30),
//             _buildActionButtons(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLabel(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Text(
//         text,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     TextInputType keyboardType = TextInputType.text,
//     String? Function(String?)? validator,
//     int maxLines = 1,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//         color: Colors.white.withValues(alpha: 0.1),
//       ),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: keyboardType,
//         maxLines: maxLines,
//         style: const TextStyle(color: Colors.white),
//         decoration: InputDecoration(
//           contentPadding:
//               const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           border: InputBorder.none,
//           errorStyle: const TextStyle(color: Colors.redAccent),
//         ),
//         validator: validator,
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         Expanded(
//           child: GestureDetector(
//             onTap: _clearForm,
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [
//                     Color(0xFF025769),
//                     Color.fromARGB(255, 51, 49, 162),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               padding: const EdgeInsets.symmetric(vertical: 14),
//               alignment: Alignment.center,
//               child: const Text(
//                 'Clear',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 15),
//         Expanded(
//           child: GestureDetector(
//             onTap: _isLoading ? null : _saveContact,
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [
//                     Color(0xFF1E88E5),
//                     Color(0xFF1565C0),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               padding: const EdgeInsets.symmetric(vertical: 14),
//               alignment: Alignment.center,
//               child: _isLoading
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         color: Colors.white,
//                         strokeWidth: 2,
//                       ),
//                     )
//                   : const Text(
//                       'Save',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
