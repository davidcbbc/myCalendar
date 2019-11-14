import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myCalendar',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
//TEMPLATE APP
DateTime _selectedDay = DateTime.now();


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: Text("myCalendar by capella"),
      ),
      body: Column(
        children: <Widget>[
          DatePickerTimeline(
            _selectedDay,
            locale: "pt_BR",
            onDateChange: (date) {
              // New date selected
              setState(() {
                _selectedDay = date;
              });
            },
          )
        ],
      ),
    );
  }

}
