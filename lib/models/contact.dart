class Contact {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String relationship;
  final String? bloodType;
  final String? city;
  final String? age;
  final String circleType; // 'General', 'Family', 'Relatives', etc.

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.relationship,
    this.bloodType,
    this.city,
    this.age,
    required this.circleType,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phoneNumber': phoneNumber,
    'email': email,
    'relationship': relationship,
    'bloodType': bloodType,
    'city': city,
    'age': age,
    'circleType': circleType,
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'],
    name: json['name'],
    phoneNumber: json['phoneNumber'],
    email: json['email'],
    relationship: json['relationship'],
    bloodType: json['bloodType'],
    city: json['city'],
    age: json['age'],
    circleType: json['circleType'],
  );
}