import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_blue_plus_example/globals.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter BLE App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Flutter BLE App'),
      );
}

// ignore: must_be_immutable
class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};

  // OWN
  late BluetoothCharacteristic connectedCharacteristic;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final _writeController = TextEditingController();
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _services = [];

  // bool isConnected = false;
  bool isNotifiy = false;

  List<dynamic> receivedMessages = [
    // {'message': 'Message1', 'time': '12:01'}, // EXAMPLE
  ];

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  void _toggleNotfiy(characteristic) async {
    setState(() {
      isNotifiy = !isNotifiy;
    });
    if (isNotifiy) {
      characteristic.value.listen((value) {
        print('notify: ');
        print(utf8.decode(value));
        String msg = utf8.decode(value);
        var dt = DateTime.now();
        String time = '${dt.hour}:${dt.minute}';

        setState(() {
          receivedMessages.add({'message': msg, 'time': time});
        });
      });
      await characteristic.setNotifyValue(true);
    } else {
      await characteristic.setNotifyValue(false);
    }
  }

  @override
  void initState() {
    super.initState();

    // print(_connectedDevice);
    // if (_connectedDevice != null) {
    //   _connectedDevice!.disconnect();
    //   print('device disconnected');
    // }

    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  //ListView _buildListViewOfDevices() {
  _buildListViewOfDevices() {
    List<Widget> foundDevices = <Widget>[];
    for (BluetoothDevice device in widget.devicesList) {
      /// FOUNDED DEVICE CARD
      foundDevices.add(Padding(
        padding: const EdgeInsets.only(bottom: 14.0),
        child: Container(
            decoration: BoxDecoration(
                color: brownDarker, borderRadius: BorderRadius.circular(8)),
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.16,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  // DEVICE NAME
                  Row(
                    children: [
                      const Text(
                        'Device Name:',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        device.name == '' ? '(unknown device)' : device.name,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: brownMain),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // CHARACTERISTIC
                  Row(
                    children: [
                      const Text(
                        'Device ID:',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 39),
                      Text(
                        device.id.toString(),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: brownMain),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 25,
                    child: ElevatedButton(
                      onPressed: () async {
                        widget.flutterBlue.stopScan();
                        try {
                          /// OPTION FOR AUTO CONNECT
                          await device.connect(autoConnect: false);
                        } on PlatformException catch (e) {
                          if (e.code != 'already_connected') {
                            rethrow;
                          }
                        } finally {
                          _services = await device.discoverServices();
                        }
                        setState(() {
                          _connectedDevice = device;
                          //isConnected = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brownMain,
                      ),
                      child:
                          const Text('Connect', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            )),
      ));
    }

    return Column(children: [
      // SEARCH BUTTON & STOP SEARCH BUTTON
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () async {
              await widget.flutterBlue.stopScan();
              widget.flutterBlue.startScan();
              setState(() {
                widget.devicesList.clear();
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: brownMain,
                fixedSize: Size(MediaQuery.of(context).size.width * 0.38,
                    MediaQuery.of(context).size.height * 0.06)),
            child: Text(
              'SEARCH DEVICES',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.flutterBlue.stopScan();
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: brownDarkest,
                fixedSize: Size(MediaQuery.of(context).size.width * 0.38,
                    MediaQuery.of(context).size.height * 0.06)),
            child: Text(
              'STOP SEARCH',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2),
            ),
          )
        ],
      ),
      const SizedBox(height: 25),
      Text('DEVICES FOUND:',
          textAlign: TextAlign.left,
          style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: brownDarkest,
              letterSpacing: 3)),

      const SizedBox(height: 20),
      Expanded(
        child: ListView(
          //padding: const EdgeInsets.all(8),
          children: <Widget>[
            ...foundDevices,
          ],
        ),
      )
    ]);
  }

  _buildConnectDeviceView() {
    for (BluetoothService service in _services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        /// CHECK IF READ AND WRITE PROPERTIES AVAILABLE
        /// THEN USE THIS CHARACTERISTIC
        if (characteristic.properties.write) {
          setState(() {
            widget.connectedCharacteristic = characteristic;
          });
        }
      }
    }

    /// RETURN THE ACTIVE CONNECTION SCREEN
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        /// ACTIVE CONNECTION CARD
        Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: Container(
              decoration: BoxDecoration(
                  color: brownDarker, borderRadius: BorderRadius.circular(8)),
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.17,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // DEVICE NAME
                    Row(
                      children: [
                        const Text(
                          'Device Name:',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          _connectedDevice!.name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: brownMain),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // DEVICE ID
                    Row(
                      children: [
                        const Text(
                          'Device ID:',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(left: 29.0),
                          child: Text(
                            _connectedDevice!.id.toString(),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: brownMain),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // CHARACTERISTIC
                    Row(
                      children: [
                        const Text(
                          'Characteristic:',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.connectedCharacteristic.uuid.toString(),
                          style: TextStyle(
                              fontSize: 10.2,
                              fontWeight: FontWeight.w600,
                              color: brownMain),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 25,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _connectedDevice?.removeBond();
                          setState(() {
                            _connectedDevice?.disconnect();
                            _connectedDevice = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brownMain,
                        ),
                        child: const Text('Disconnect',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              )),
        ),

        /// END ACTIVE CONNECTION CARD

        const SizedBox(height: 10),
        Text('SEND MESSAGE:',
            textAlign: TextAlign.left,
            style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: brownDarkest,
                letterSpacing: 3)),
        const SizedBox(height: 20),

        /// SEND MESSAGE CARD
        Row(
          children: [
            // SEND MESSAGE
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                height: MediaQuery.of(context).size.width * 0.12,
                child: TextField(
                  controller: _writeController,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: brownLighter),
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8))),

                    focusedBorder:
                        const OutlineInputBorder(borderSide: BorderSide.none),
                    // focusedBorder: OutlineInputBorder(
                    //     borderSide: BorderSide(color: brownDarkest),
                    //     borderRadius: const BorderRadius.only(
                    //         topLeft: Radius.circular(8),
                    //         bottomLeft: Radius.circular(8))),
                    hintText: 'Write message to send..',
                    hintStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white),
                    fillColor: brownLighter,
                    filled: true,
                  ),
                )),

            // SEND BUTTON
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  await widget.connectedCharacteristic.setNotifyValue(false);

                  /// SEND THE MESSAGE VIA BLUETOOTH
                  await widget.connectedCharacteristic
                      .write(utf8.encode('${_writeController.text}\n'));

                  await widget.connectedCharacteristic.setNotifyValue(true);

                  setState(() {
                    _writeController.clear();
                    FocusManager.instance.primaryFocus?.unfocus();
                  });

                  final snackBar = SnackBar(
                    backgroundColor: brownMain,
                    content: const Center(child: Text('Message send!')),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },
                child: Container(
                    decoration: BoxDecoration(
                        color: brownMain,
                        borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8))),
                    alignment: Alignment.center,
                    height: MediaQuery.of(context).size.width * 0.12,
                    child: const Icon(
                      Icons.send,
                      size: 24,
                      color: Colors.white,
                    )),
              ),
            ),
          ],
        ),

        /// END WRITE MESSAGE CARD

        const SizedBox(height: 25),
        Text('RECEIVED MESSAGES:',
            textAlign: TextAlign.left,
            style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: brownDarkest,
                letterSpacing: 3)),
        const SizedBox(height: 17),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// NOTIFY BUTTON
            SizedBox(
              width: 58,
              height: 18,
              child: ElevatedButton(
                onPressed: () {
                  _toggleNotfiy(widget.connectedCharacteristic);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: isNotifiy ? Colors.green : brownMain),
                child: const Text('Notify',
                    style: TextStyle(fontSize: 9, color: Colors.white)),
              ),
            ),

            const SizedBox(width: 100),

            /// END NOTIFY BUTTON

            /// CLEAR BUTTON
            SizedBox(
              width: 58,
              height: 18,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    receivedMessages.clear();
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: brownMain),
                child: const Text('Clear',
                    style: TextStyle(fontSize: 9, color: Colors.white)),
              ),
            ),

            /// END CLEAR BUTTON
          ],
        ),

        const SizedBox(height: 8),

        /// RECEIVE MESSAGES
        Container(
          decoration: BoxDecoration(
              color: brownGettedMessagesBG,
              borderRadius: BorderRadius.circular(8)),
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    height: MediaQuery.of(context).size.height * 0.27,
                    child: SingleChildScrollView(
                      child: ListView.builder(
                          shrinkWrap: true,
                          physics: const ScrollPhysics(),
                          itemCount: receivedMessages.length,
                          itemBuilder: (BuildContext context, int index) {
                            /// RECEIVED MESSAGE CARD
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: brownGettedMessages),
                                width: MediaQuery.of(context).size.width * 0.75,
                                child: Stack(children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      receivedMessages[index]['message']
                                          .toString(),
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.white),
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: Text(
                                      receivedMessages[index]['time']
                                          .toString(),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color.fromARGB(
                                              218, 255, 255, 255)),
                                    ),
                                  )
                                ]),
                              ),
                            );

                            /// END RECEIVED MESSAGE CARD
                          }),
                    )),

                /// END RECEIVED MESSAGES
              ],
            ),
          ),
        )
      ],
    );
  }

  //ListView _buildView() {
  _buildView() {
    if (_connectedDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  SvgPicture.asset(
                    'assets/mz_icon_brown.svg',
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                  Text(
                    'FLUTTER BLUETOOTH APP',
                    style: GoogleFonts.roboto(
                        fontSize: 12, letterSpacing: 2, color: whiteSubtitle),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.72,
                      child: _buildView()),
                ],
              ),
            ),
          ),
        ));
  }
}
