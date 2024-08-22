import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../utils/consts.dart';
import '../../models/Student.dart';
import '../../models/user.dart';
import 'package:mat_month_picker_dialog/mat_month_picker_dialog.dart';

class TopStudentsAttendeesScreen extends StatefulWidget {
  final User user;
  const TopStudentsAttendeesScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<TopStudentsAttendeesScreen> createState() => _TopStudentsAttendeesScreenState();
}

class _TopStudentsAttendeesScreenState extends State<TopStudentsAttendeesScreen> {
  final List<Student> _monthlyReport = [];
  Map<String, int> _studentsReport = {};

  final _dateController = TextEditingController(text: 'Select Month');
  final _noOfDaysController = TextEditingController(text: '30');
  DateTime? _selectedMonth = DateTime.now();

  final _items = [ // we will add teachers subject with it but first element will 'Select a Subject'
    'Select a Subject',
  ]; String _dropDownValue = 'Select a Subject';

  int getDaysOfMonth(DateTime? month) {
    return DateTime(_selectedMonth?.year ?? DateTime.now().year, (_selectedMonth?.month ?? DateTime.now().year) + 1, 0).day;
  }

  void getMonthlyReport() {
    // clearing all values, suppose orientation changed, values will increment, so clearing values
    _monthlyReport.clear();
    _studentsReport.clear();

    if (_dropDownValue == _items[0]) {
      return;
    }

    _selectedMonth ??= DateTime.now();

    // to get monthly report, we will iterate from first to last day of month and calculate result
    final firstDay = DateTime(_selectedMonth!.year, _selectedMonth!.month, 1); // first date of that specific month
    final lastDay = DateTime(_selectedMonth!.year, _selectedMonth!.month + 1, 1); // last date of that specific month

    for (DateTime date = firstDay; date.isBefore(lastDay); date = date.add(const Duration(days: 1))) {
      List<Student> thisDateReport = widget.user.studentsReport
          .where((student) => (student.date.day == date.day) && (student.date.month == date.month) && (student.date.year == date.year)
          && (student.subject == _dropDownValue) && student.isIn)
          .toList();
      _monthlyReport.addAll(thisDateReport);
    }

    // we have to now filter out (distinct) those student how are scanned multiply using informational text
    List<Student> monthlyReportDistinct = _monthlyReport.toSet().toList();

    for (var i in monthlyReportDistinct) {
      if (_studentsReport.containsKey(i.name)) {
        _studentsReport[i.name] = (_studentsReport[i.name]! + 1);
      } else {
        _studentsReport[i.name] = 1;
      }
    }

    if (_studentsReport.isNotEmpty) {
      _studentsReport = Map.fromEntries(_studentsReport.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)));
    }
  }

  String getTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void exportToExcel() async {

    final currentSubjectIndex = _items.indexWhere((subject) => subject == _dropDownValue) - 1; // subtracting 1 because items contain 1 additional element
    final subjectSelected = (currentSubjectIndex != -1) && (_dropDownValue != _items[0]);

    if (!subjectSelected) {
      showDialog(context: context, builder: (context) => AlertDialog(
        content: const Text('Please select any subject first!'),
        actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Ok'))],
      ),);

      return;
    }

    if (_studentsReport.isEmpty) {
      showDialog(context: context, builder: (context) => AlertDialog(
        content: const Text('No report to export'),
        actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Ok'))],
      ),);

      return;
    }

    try {
      Excel excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      String selectedMonthFormat = DateFormat('MMM-yyyy').format(_selectedMonth ?? DateTime.now());

      sheetObject.cell(CellIndex.indexByString("A1")).value = 'Student Name' as CellValue?;
      sheetObject.cell(CellIndex.indexByString("B1")).value = 'Total Attendees' as CellValue?;
      sheetObject.cell(CellIndex.indexByString("C1")).value = 'Total Absentees' as CellValue?;

      sheetObject.setColumnWidth(0, 25);

      int rowIndex = 2;
      final daysInMonth = getDaysOfMonth(_selectedMonth);

      for (var report in _studentsReport.keys) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = report as CellValue?;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = _studentsReport[report] as CellValue?;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = (daysInMonth - _studentsReport[report]!) as CellValue?;

        rowIndex++;
      }

      String timestamp = DateFormat('HH-mm-ss-dd-MM-yyyy').format(DateTime.now());

      final String? path = await _getSavePath('Top-Attendees-$_dropDownValue-$selectedMonthFormat-$timestamp');
      final excelData = excel.encode();
      if (path != null) {
        await File(path).writeAsBytes(excelData!).then((value) => {
          showDialog(context: context, builder: (context) =>
              AlertDialog(
                icon: const Icon(Icons.save, color: myColor),
                title: const Text('Report Exported'),
                content: SelectableText(value.toString()),
                actions: [
                  GestureDetector(
                    onTap: ()=> Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        margin: const EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(
                          color: myLightColor,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: const Center(child: Text('Ok', style: TextStyle(color: Colors.white, fontSize: 16.0,),),),
                      ),
                    ),
                  ),
                ],
              ),)
        });
      }
    } catch(e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  Future<String?> _getSavePath(String fileName) async {

    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      final path = '$result/$fileName.xlsx';
      return path;
    }
    return null;
  }

  @override
  void initState() {
    _items.addAll(widget.user.subjects.map((subject) => subject.name).toList());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    getMonthlyReport();
    int tableSrNoCount = 1;

    final currentSubjectIndex = _items.indexWhere((subject) => subject == _dropDownValue) - 1; // subtracting 1 because items contain 1 additional element
    final subjectSelected = (currentSubjectIndex != -1) && (_dropDownValue != _items[0]);

    var daysInMonth = getDaysOfMonth(_selectedMonth);

    try {
      daysInMonth = int.parse(_noOfDaysController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    var isDarkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Students Attendees',),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 25.0,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton(
                        value: _dropDownValue,
                        icon: const Icon(Icons.arrow_downward_rounded, color: myColor,),
                        items: _items.map((String items) {
                          return DropdownMenuItem(
                            value: items,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.50,
                              child: Text(items, style: const TextStyle(color: myColor), maxLines: 1, overflow: TextOverflow.ellipsis,),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _monthlyReport.clear();
                            _dropDownValue = newValue!;

                            if (widget.user.studentsReport.isEmpty) {
                              return;
                            }
                          });
                        },
                      ),
                      GestureDetector(
                          onTap: ()=> exportToExcel(),
                          child: Tooltip(
                            message: 'Export to excel', child: Container(
                              padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 5.0,),
                              child: const Icon(Icons.drive_folder_upload_outlined),
                            )
                          )
                      ),
                    ],
                  ),
                  const SizedBox(height: 15.0,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      dateTextContainer(_dateController, 'Month',),
                      const SizedBox(width: 5.0,),
                      !subjectSelected
                      ? const SizedBox()
                      : SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.user.subjects[currentSubjectIndex].name, style: const TextStyle(fontSize: 16.0,), maxLines: 2, overflow: TextOverflow.ellipsis,),
                              Text('From ${getTime(widget.user.subjects[currentSubjectIndex].fromTime)} to ${getTime(widget.user.subjects[currentSubjectIndex].toTime)}',
                                style: const TextStyle(fontSize: 12.0,),
                              ),
                              Text('Males: ${widget.user.subjects[currentSubjectIndex].noOfMale} - Females: ${widget.user.subjects[currentSubjectIndex].noOfFemale}',
                                style: const TextStyle(fontSize: 12.0,),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15.0,),
            !subjectSelected
              ? const Center(child: Padding(
              padding: EdgeInsets.only(top: 50.0),
              child: Text('Select any subject', style: TextStyle(fontSize: 18.0,),),
            ),)
              : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Visibility(
                visible: _studentsReport.isNotEmpty,
                replacement: const Text('No report'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${DateFormat('MMMM').format(_selectedMonth!)} Attendance Report'),
                    const SizedBox(height: 7.5,),
                    Row(
                      children: [
                        const Text('Number of Days: '),
                        const SizedBox(width: 5.0,),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            controller: _noOfDaysController,
                            onSubmitted: (value) {
                              try {
                                if (int.parse(value) > getDaysOfMonth(_selectedMonth) || int.parse(value) <= 0) {
                                  setState(() {
                                    _noOfDaysController.text =
                                        getDaysOfMonth(_selectedMonth).toString();
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()),),);
                              }
                            },
                            maxLength: 2,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(8),
                              counterText: '', // don't show digit at bottom corner
                              border: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0,),
                    Table(
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      border: TableBorder.symmetric(inside: BorderSide(width: 1, color: isDarkTheme? Colors.white12 : Colors.blue.withOpacity(0.3)),),
                      columnWidths: {
                        0: FixedColumnWidth(MediaQuery.of(context).size.width * 0.10),
                        1: FixedColumnWidth(MediaQuery.of(context).size.width * 0.45),
                        2: FixedColumnWidth(MediaQuery.of(context).size.width * 0.175),
                        3: FixedColumnWidth(MediaQuery.of(context).size.width * 0.175),
                      },
                      children: [
                        TableRow(
                            children: [
                              Container(
                                  height: 60.0,
                                  color: isDarkTheme ? tableColorLightForDark : tableColorLight,
                                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0, left: 5.0),
                                  child: const Center(
                                    child: Text('NO.',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.0,),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                              ),
                              Container(
                                  height: 60.0,
                                  color: isDarkTheme ? tableColorForDark : tableColor,
                                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0, left: 10.0),
                                  child: const Text('Student Name',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0,),
                                    overflow: TextOverflow.ellipsis,
                                  )
                              ),
                              Container(
                                  height: 60.0,
                                  color: isDarkTheme ? tableColorLightForDark : tableColorLight,
                                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                                  child: const Text('Total \nAttendees',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.0,),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  )
                              ),
                              Container(
                                  height: 60.0,
                                  color: isDarkTheme ? tableColorForDark : tableColor,
                                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                                  child: const Text('Total \nAbsentees',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.0,),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  )
                              ),
                            ]
                        ),

                        for (var i in _studentsReport.keys)
                          TableRow(
                              children: [
                                Container(
                                    color: isDarkTheme ? tableColorLightForDark : tableColorLight,
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text('${tableSrNoCount++}.', style: const TextStyle(fontSize: 12.0), textAlign: TextAlign.center,)
                                ),
                                Container(
                                    color: isDarkTheme ? tableColorForDark : tableColor,
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(i, style: const TextStyle(fontSize: 12.0), maxLines: 1, overflow: TextOverflow.ellipsis,)
                                ),
                                Container(
                                    color: isDarkTheme ? tableColorLightForDark : tableColorLight,
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text('${_studentsReport[i]}', overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 12.0,), textAlign: TextAlign.center,)
                                ),
                                Container(
                                    color: isDarkTheme ? tableColorForDark : tableColor,
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text('${daysInMonth - _studentsReport[i]!}', style: const TextStyle(fontSize: 12.0), overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.center,)
                                ),
                              ]
                          )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void pickDate(TextEditingController textController) async {

    await showMonthPicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1970),
        lastDate: DateTime(2050)
    ).then((value) {
      setState(() {

        _selectedMonth = value;
        _monthlyReport.clear();
      });
      return null;
    });

  }

  Widget dateTextContainer(TextEditingController textController, String label) {
    return GestureDetector(
      onTap: () => _dropDownValue == _items[0]? null : pickDate(textController),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.35,
        child: TextField(
          readOnly: true,
          enabled: false,
          controller: textController,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.dark? Colors.white.withOpacity(0.3) : myColor),
            disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: MediaQuery.of(context).platformBrightness == Brightness.dark? Colors.white.withOpacity(0.3) : myColor)
            ),
          ),
        ),
      ),
    );
  }
}
