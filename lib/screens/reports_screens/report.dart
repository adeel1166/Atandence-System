import 'package:attendance_system/screens/reports_screens/search_attendance.dart';
import 'package:attendance_system/screens/reports_screens/top_students_attendees.dart';
import 'package:flutter/material.dart';
import 'package:attendance_system/models/user.dart' as model;
import '../../widgets/my_outlined_button.dart';
import 'daily_report.dart';
import 'monthly_report.dart';

class ReportPage extends StatefulWidget {
  final model.User user;
  const ReportPage({Key? key, required this.user,}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {

  @override
  Widget build(BuildContext context) {
    // if is Guard, show only search attendance screen
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0).copyWith(top: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reports', style: TextStyle(fontWeight: FontWeight.bold),),
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              MyOutlinedButton(
                onTap: ()=> Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SearchAttendanceScreen(user: widget.user),),
                ),
                text: 'Search Attendance',
              ),
              const SizedBox(height: 10.0,),
              MyOutlinedButton(
                onTap: ()=> Navigator.push(context,
                  MaterialPageRoute(builder: (context) => DailyReportScreen(user: widget.user),),
                ),
                text: 'Daily Report',
              ),
              const SizedBox(height: 10.0,),
              MyOutlinedButton(
                onTap: ()=> Navigator.push(context,
                  MaterialPageRoute(builder: (context) => MonthlyReportScreen(user: widget.user),),
                ),
                text: 'Monthly Report',
              ),
              const SizedBox(height: 10.0,),
              Visibility(
                visible: (widget.user.role != 'Guard'),
                child: MyOutlinedButton(
                  onTap: ()=> Navigator.push(context,
                    MaterialPageRoute(builder: (context) => TopStudentsAttendeesScreen(user: widget.user),),
                  ),
                  text: 'Top Students Attendees',
                ),
              ),
              const SizedBox(height: 20.0,),
            ],
          ),
        ),
      ),
    );
  }
}
