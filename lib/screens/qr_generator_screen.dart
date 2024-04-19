import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../helpers/date_helper.dart';
import '../helpers/space_helper.dart';
import '../widgets/custom_container.dart';
import '../widgets/heading_text.dart';
import '../widgets/sub_heading_text.dart';
import './qr_code_screen.dart';

class QRGeneratorScreen extends StatefulWidget {
  static const routeName = "generate-qr";
  const QRGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  bool onPressed = false;
  String currentAddress = "";
  Position? currentPosition;
  User? user = FirebaseAuth.instance.currentUser;
  final GlobalKey<FormState> _formKey = GlobalKey();
  Future<DocumentSnapshot<Map<String, dynamic>>>? teacher;
  Map<String, String> sendData = {
    "name": "",
    "subject": "",
    "batch": "",
  };

  @override
  void initState() {
    super.initState();
    teacher = getTeacherData();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "Please Enable your device location service");
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location Permission is denied");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(msg: "Location Permission is denied forever");
    }
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    try {
      print(position);
      List<Placemark> placemark = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      print(placemark);
      Placemark place = placemark[0];
      setState(() {
        currentPosition = position;
        currentAddress = "${place.postalCode}";
      });
    } catch (error) {
      print(error.toString());
      Fluttertoast.showToast(msg: "Failed to get current location");
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getTeacherData() async {
    return await FirebaseFirestore.instance
        .collection("teachers")
        .doc(user!.uid)
        .get();
  }

  void generateQR() async {
    FocusScope.of(context).unfocus();
    bool validity = _formKey.currentState!.validate();
    if (!validity) {
      return;
    }
    setState(() {
      onPressed = true;
    });
    _formKey.currentState!.save();
    sendData["subject"] = sendData["subject"]!.toUpperCase();
    sendData["batch"] = sendData["batch"]!.toUpperCase();

    String month = DateHelper().setMonth(DateTime.now().month.toString());
    await _determinePosition();
    await FirebaseFirestore.instance
        .collection(sendData["name"]!)
        .doc(sendData["batch"])
        .collection("${DateTime.now().day} $month, ${DateTime.now().year}")
        .doc(sendData["subject"])
        .set(
      {
        "Attendance Started at":
            "${DateTime.now().hour}:${DateTime.now().minute}",
        "location": currentAddress,
        "attendance": [],
      },
    ).then(
      (_) {
        setState(() {
          onPressed = false;
        });
        Navigator.of(context).pushNamed(
          QRCodeScreen.routeName,
          arguments: sendData,
        );
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    sendData["name"] = ModalRoute.of(context)!.settings.arguments as String;
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return FutureBuilder<DocumentSnapshot>(
      future: teacher,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return onPressed
            ? Scaffold(
                body: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator.adaptive(),
                      Text(
                        "Generating QR Code....",
                        textScaleFactor: 1,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : Scaffold(
                appBar: AppBar(
                  title: const Text(
                    "Generate QR Code to take attendance",
                    textScaleFactor: 1,
                  ),
                ),
                body: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.6,
                      child: Image.asset(
                        "assets/images/logo.png",
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SingleChildScrollView(
                      child: SizedBox(
                        height: height,
                        width: width,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const HeadingText(
                                  text: "Enter the details",
                                  textSize: 32,
                                ),
                                VerticalSizedBox(height: height * 0.02),
                                const SubHeadingText(
                                  text: "Subject Code",
                                  textSize: 24,
                                ),
                                const VerticalSizedBox(
                                  height: 10,
                                ),
                                CustomContainer(
                                  icon: Icons.book,
                                  child: TextFormField(
                                    autocorrect: true,
                                    enableSuggestions: true,
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return "Please Enter the Subject Code";
                                      } else if (value.trim().length != 6) {
                                        return "The Length of the code must be exactly 6 characters";
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      sendData["subject"] = value!.trim();
                                    },
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: const InputDecoration(
                                        hintText: "Eg: 21CS41",
                                        contentPadding: EdgeInsets.all(10),
                                        border: InputBorder.none),
                                  ),
                                ),
                                VerticalSizedBox(height: height * 0.02),
                                const SubHeadingText(
                                  text: "Branch",
                                  textSize: 24,
                                ),
                                const VerticalSizedBox(
                                  height: 10,
                                ),
                                CustomContainer(
                                  icon: Icons.school,
                                  child: TextFormField(
                                    autocorrect: true,
                                    enableSuggestions: true,
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return "Please Enter the Branch Name";
                                      } else if (value.trim().length != 5) {
                                        return "The Length of branch name must be exactly 5 characters";
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      sendData["batch"] = value!.trim();
                                    },
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(10),
                                      hintText: "Eg: 21ISE",
                                    ),
                                  ),
                                ),
                                VerticalSizedBox(height: height * 0.02),
                                ElevatedButton(
                                  onPressed: generateQR,
                                  child: const Text(
                                    "Generate QR Code",
                                    style: TextStyle(color: Colors.white),
                                    textScaleFactor: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
      },
    );
  }
}
