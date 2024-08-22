import 'package:attendance_system/utils/consts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:attendance_system/models/user.dart' as model;

import '../../models/school.dart';
import '../../models/subject.dart';
import '../../services/firestore.dart';

class SchoolInfoScreen extends StatefulWidget {
  final model.User user;
  const SchoolInfoScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<SchoolInfoScreen> createState() => _SchoolInfoScreenState();
}

class _SchoolInfoScreenState extends State<SchoolInfoScreen> {
  School school = School(name: '', id: '', address: '- - -', schoolUsersRef: []);
  var totalEnrollees = '';

  void fetchSchool() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.user.schoolID).get();

    school = School.fromJson(snapshot.data());

    setState(() {

    });
  }

  void editEnrollees() {
    final enrolleesController = TextEditingController();
    final noOfMalesController = TextEditingController();
    final noOfFemalesController = TextEditingController();

    void edit() {
      if (noOfMalesController.text.isEmpty || noOfFemalesController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fields cannot be empty!')));
        return;
      }

      final updatedSubject = Subject(
        name: widget.user.subjects[0].name,
        noOfMale: noOfMalesController.text.trim().toString(),
        noOfFemale: noOfFemalesController.text.trim().toString(),
        fromTime: widget.user.subjects[0].fromTime,
        toTime: widget.user.subjects[0].toTime,
      );

      Navigator.pop(context);

      FirestoreService().updateSubject(
          widget.user.subjects[0], updatedSubject, () {}
      );

      setState(() {
        totalEnrollees = enrolleesController.text.trim().toString();
        widget.user.subjects[0].noOfMale = noOfMalesController.text.trim().toString();
        widget.user.subjects[0].noOfFemale = noOfFemalesController.text.trim().toString();
      });
    }

    showDialog(context: context, builder: (context) => SimpleDialog(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: enrolleesController,
                decoration: const InputDecoration(
                  hintText: 'Total Enrollees'
                ),
              ),
              TextField(
                controller: noOfMalesController,
                decoration: const InputDecoration(
                    hintText: 'Total Males'
                ),
              ),
              TextField(
                controller: noOfFemalesController,
                decoration: const InputDecoration(
                    hintText: 'Total Females'
                ),
              ),
              const SizedBox(height: 5.0,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  TextButton(onPressed: edit, child: const Text('Edit')),
                ],
              ),
            ],
          ),
        ),
      ],
    ),);
  }

  @override
  void initState() {
    fetchSchool();
    totalEnrollees = '${int.parse(widget.user.subjects[0].noOfMale) + int.parse(widget.user.subjects[0].noOfFemale)}';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Information'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: editEnrollees,
                    child: const Text('Edit', style: TextStyle(color: myColor)),
                  ),
                ],
              ),
              const SizedBox(height: 35.0,),
              Text('School Name: ${widget.user.schoolName}', style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
              const SizedBox(height: 10.0,),
              Text('School ID: ${widget.user.schoolID}',),
              const SizedBox(height: 10.0,),
              Text('School Address: ${school.address.isEmpty? 'Not Mentioned' : school.address}',),
              const SizedBox(height: 35.0,),
              Text('Total Enrollees: $totalEnrollees'),
              const SizedBox(height: 5.0,),
              Text('Total Males: ${widget.user.subjects[0].noOfMale}'),
              const SizedBox(height: 5.0,),
              Text('Total Females: ${widget.user.subjects[0].noOfFemale}'),
              const SizedBox(height: 20.0,),
            ],
          ),
        ),
      ),
    );
  }
}
