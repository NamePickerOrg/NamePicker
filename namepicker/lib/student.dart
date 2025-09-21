import 'package:flutter/material.dart';

class Student {
  int? id;
  String name;
  String gender;
  String studentId;

  Student({this.id, required this.name, required this.gender, required this.studentId});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'studentId': studentId,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      gender: map['gender'],
      studentId: map['studentId'],
    );
  }
}
