import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../utils/consts.dart';
import '../../models/Student.dart';
import 'package:attendance_system/models/user.dart' as model;
import '../../services/firestore.dart';
import '../../services/send_sms.dart';

class ScanPage extends StatefulWidget {
  final model.User user;
  const ScanPage({Key? key, required this.user,}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with SingleTickerProviderStateMixin {
  final _globalKey = GlobalKey();
  QRViewController? _controller;
  Barcode? _result;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final _informationalController = TextEditingController();

  final _items = [ // we will add teachers subject with it but first element will 'Select a Subject'
    'Select a Subject',
  ]; String _dropDownValue = 'Select a Subject';

  int _toggleLabelIndex = 0; // For toggle switch, 0 index (In), 1 index (Out)

  List<Student> _todayReport = [];
  int _totalMales = 0, _totalFemales = 0;
  int _attendeesMale = 0, _attendeesFemale = 0, _absenteesMale = 0, _absenteesFemale = 0;

List<String>? getDataFromString(String result) {
  // Staff QR format: FirstName,,MiddleName,,Lastname,,CellphoneNumber,,Staff
  // Student QR format: Geraldine Ramos,,09100000905,,F

  // Determine if QR is for staff or student
  if (result.split(",,").length == 6) {
    // Staff QR format
    List<String> parts = result.split(",,");
    return parts;
  } else {
    // Student QR format (previously defined)
    int count = result.split(",,").length - 1;
    if (count != 2 && count != 4) {
      _controller?.pauseCamera();
      return null;
    }
    List<String> parts = result.split(",,");
    return parts;
  }
}


  void checkSmsPermission() async {
    var status = await Permission.sms.status;
    if (status.isDenied) {
      await Permission.sms.request().then((value) {
        _controller?.pauseCamera();
        _controller?.resumeCamera();
      });
    }
  }

  void message(Student student) async {
    checkSmsPermission();

    final defaultMsg = widget.user.role != 'Guard'?
    'Your child ${student.name} is ${student.isIn? 'now attending' : 'now out in'} ${student.subject} class.'
        : 'Your child ${student.name} is ${student.isIn? 'now inside school premises.' : 'now outside school premises.'}';

    // if text-field text is not empty, send that text as message else send default message
    var messageText = _informationalController.text.trim().toString().isNotEmpty
      ? _informationalController.text.trim().toString()
      : defaultMsg;

    var result = await SmsService.message([student.phoneNo], messageText, context);
    if (result) {

      // Now we have to save this report to teacher's report list
      FirestoreService().saveReport(
          student,
            () {
              // Fluttertoast.showToast(msg: 'Saved to your report');
          }
      );

      setState(() {
        _animationController.forward();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
          content: ScaleTransition(
            scale: _animation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 5.0,),
                const Icon(Icons.done, color: Colors.green, size: 150.0,),
                const SizedBox(height: 5.0,),
                Text(student.name, style: const TextStyle(fontSize: 18.0,), textAlign: TextAlign.center,),
                const SizedBox(height: 5.0,),
                const Text('Message Sent', style: TextStyle(fontSize: 18.0,),),
                const SizedBox(height: 5.0,),
              ],
            ),
          ),
        ),).then((value) {
          _controller?.resumeCamera();
        });

        Future.delayed(const Duration(milliseconds: 1200), () {
          Navigator.of(context).pop();
          _controller?.resumeCamera();
        });
      });
    }
  }

void sendMessage() {
  if (_dropDownValue == _items[0] && widget.user.role != 'Guard') {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Select any Subject'),
        icon: Icon(Icons.error, color: myColor,),
      ),).then((value) {
        if (!FocusScope.of(context).hasPrimaryFocus) {
          FocusScope.of(context).unfocus();
        }
        _controller?.resumeCamera();
    });

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop();
      _controller?.resumeCamera();
    });

    return;
  }

  List<String>? parts = getDataFromString(_result!.code.toString());

  if (parts != null) {
    if (parts.length == 6) {
      // Staff QR
      var staffName = '${parts[0]} ${parts[1]} ${parts[2]}';
      final student = Student(
        name: staffName,
        phoneNo: parts[3],
        gender: 'M', // Gender is not applicable here
        subject: 'Staff', // Subject for staff
        date: DateTime.now(),
        isIn: (_toggleLabelIndex == 0) ? true : false, role: '',
      );

      message(student);
    } else {
      // Student QR
      var gender = (parts.length == 3) ? parts[2] : 'Unknown';

      final student = Student(
        name: parts[0],
        phoneNo: parts[1],
        gender: gender,
        subject: widget.user.role == 'Guard' ? '' : _dropDownValue,
        date: DateTime.now(),
        isIn: (_toggleLabelIndex == 0) ? true : false, role: '',
      );

      if (widget.user.studentsReport.isNotEmpty && _informationalController.text.trim().toString().isEmpty) {
        for (var report in widget.user.studentsReport) {
          if (student.name == report.name
              && student.date.day == report.date.day && student.date.month == report.date.month && student.date.year == report.date.year
              && student.subject == report.subject && student.isIn == report.isIn) {

            _controller?.pauseCamera();

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
              const AlertDialog(
                title: Text('Student Already Scanned!'),
                content: Text('Please scan next QR code'),
                icon: Icon(Icons.error, color: myColor,),
              ),).then((value) {
              _controller?.resumeCamera();
            });

            Future.delayed(const Duration(seconds: 2), () {
              Navigator.of(context).pop();
              _controller?.resumeCamera();
            });

            return;
          }
        }
      }

      if (!FocusScope.of(context).hasPrimaryFocus) {
        FocusScope.of(context).unfocus();
      }

      message(student);
    }
  } else {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Seems the format of QR code isn\'t correct', style: TextStyle(fontSize: 14,), textAlign: TextAlign.start,),
            SizedBox(height: 5.0,),
            Text('Please contact School Administrator for Assistance', style: TextStyle(fontSize: 14), textAlign: TextAlign.start,),
            SizedBox(height: 5.0,),
          ],
        ),
      ),
      icon: const Icon(Icons.error, color: myColor,),
    ),).then((value) {
      _controller?.resumeCamera();
    });
  }
}


  void checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      await Permission.camera.request();
    }
  }

  void qr(QRViewController controller) async {
    checkCameraPermission();

    _controller = controller;
    try {
      await controller.resumeCamera();
      controller.scannedDataStream.listen((event) {
        setState(() {
          _result = event;
          controller.pauseCamera(); // show that scanner stop scanning in background, we will resume after message sent
          sendMessage();
        });
      });
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    _items.addAll(widget.user.subjects.map((subject) => subject.name).toList());

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animationController.reset();
        });
      }
    });
  }

  void getTodayReport() {
    _todayReport.clear();
    _attendeesMale = _attendeesFemale = _absenteesMale = _absenteesFemale = 0;

    if (_dropDownValue == _items[0] && widget.user.role != 'Guard') {
      return;
    }

    if (widget.user.role == 'Guard') {
      _dropDownValue = '';
    }

    final todayDate = DateTime.now();

    for (var i in widget.user.studentsReport) {
      if (i.date.day == todayDate.day && i.date.month == todayDate.month && i.date.year == todayDate.year && i.isIn && i.subject == _dropDownValue) {

        _todayReport.add(i);
      }
    }

    // we have to now filter out (distinct) those student how are scanned multiply using informational text
    List<Student> todayReportDistinct = _todayReport.toSet().toList();

    for (var i in todayReportDistinct) {
      if (i.gender == 'M') {
        _attendeesMale += 1;
      } else if (i.gender == 'F') {
        _attendeesFemale += 1;
      }
    }

    var currentSubject = widget.user.subjects.where((subject) => subject.name == (widget.user.role == 'Guard'? '' : _dropDownValue)).toList().first;

    _absenteesMale = int.parse(currentSubject.noOfMale) - _attendeesMale; // total - present
    _absenteesFemale = int.parse(currentSubject.noOfFemale) - _attendeesFemale;

    _totalMales = int.parse(currentSubject.noOfMale);
    _totalFemales = int.parse(currentSubject.noOfFemale);

  }

  @override
  Widget build(BuildContext context) {
    getTodayReport();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10.0,),
                Row(
                  mainAxisAlignment: (widget.user.role == 'Guard')? MainAxisAlignment.center : MainAxisAlignment.spaceAround,
                  children: [
                    // if is guard, we don't need to show him subject dropdown...
                    widget.user.role == 'Guard'
                    ? const SizedBox()
                    : DropdownButton(
                      value: _dropDownValue,
                      icon: const Icon(Icons.arrow_downward_rounded, color: myColor,),
                      items: _items.map((String items) {
                        return DropdownMenuItem(
                          value: items,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.45,
                          child: Text(items, style: const TextStyle(color: myColor), maxLines: 1, overflow: TextOverflow.ellipsis,),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _dropDownValue = newValue!;
                        });
                      },
                    ),
                    ToggleSwitch(
                      activeBgColor: MediaQuery.of(context).platformBrightness == Brightness.dark? [myColor] : [myLightColor!],
                      initialLabelIndex: _toggleLabelIndex,
                      labels: const ['In', 'Out'],
                      radiusStyle: true,
                      cornerRadius: 20.0,
                      inactiveBgColor: (MediaQuery.of(context).platformBrightness == Brightness.light)? Colors.grey[300] : Colors.grey[900],
                      totalSwitches: 2,
                      onToggle: (index) {
                        setState(() {
                          _toggleLabelIndex = index!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15.0,),
                (_dropDownValue == _items[0] && widget.user.role != 'Guard')
                ? const SizedBox()
                : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5.0,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.4,
                                    child: Text('Total Males: $_totalMales',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5.0,),
                              const Text('Attendees:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),),
                              Text('Male: $_attendeesMale | Female: $_attendeesFemale', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),),
                            ],
                          ),
                          Container(
                            width: 1.0,
                            height: 60.0,
                            color: Colors.grey,
                          ),// divider
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.4,
                                    child: Text('Total Females: $_totalFemales',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                                      textAlign: TextAlign.start,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5.0,),
                              const Text('Absentees:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0,),),
                              Text('Male: $_absenteesMale | Female: $_absenteesFemale', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15.0,),
                Stack(
                  children: [
                    _buildQRView(context),
                    Positioned(
                      bottom: 10.0,
                      right: 10.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: myColor,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: IconButton(
                          onPressed: () async {
                            await _controller?.flipCamera();
                          },
                          icon: const Icon(
                            Icons.cameraswitch_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 15.0,),
                TextField(
                  controller: _informationalController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: InputDecoration(
                    label: const Text('Informational Text'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    )
                  ),
                ),
                const SizedBox(height: 10.0,),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQRView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? (MediaQuery.of(context).size.width < 300 ||
            MediaQuery.of(context).size.height < 300)
            ? 200.0 : 300.0
        : 350.0;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        border: Border.all(color: myColor, width: 2.0,),
      ),
      child: QRView(
        key: _globalKey,
        onQRViewCreated: qr,
        overlay: QrScannerOverlayShape(
          borderColor: myColor,
          borderWidth: 5,
          cutOutSize: scanArea,
        ),
      ),
    );
  }
}
