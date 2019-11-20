import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
    String title = _selectedDay.day.toString();
    title += " - ";
    title += _selectedDay.month.toString();
    title += " - ";
    title += _selectedDay.year.toString();


    final drag = Draggable<String>(
                  data: "A TUA PRIMA OH BELHOTE",
                  childWhenDragging: Container(
                    child: Icon(Icons.ac_unit,color: Colors.grey,),
                  ),
                  child: Container(
                    child: Icon(Icons.ac_unit),
                  ),
                  feedback: Container(
                    child: Icon(Icons.ac_unit),
                  ),

                );




    final card = DragTarget(
      builder: (context, List<String> candidateData, rejectedData) {
        return Container(
          padding: EdgeInsets.all(10),
          height: 80,
          width: 100,
          child: Card( 
            color: Colors.grey[400],
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.people,
                        color: Colors.grey[800],
                      ),
                      Text("0")
                    ],
                  ),
                  Text(
                    "Evento",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.group_add, color: Colors.grey[800]),
                    onPressed: () {
                      // Adicionar um funcionario
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      onWillAccept: (data) {
        print("onWillAccept: $data");
        return true;
      },
      onAccept: (data) {
        print("1");
        print("onAccept: $data");
      },

      onLeave: (data) {
        print("2");
        print("onLeaveL $data");
      },
    );

    return new Scaffold(
      bottomNavigationBar: Container(
        color: Colors.grey[800],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.email,
                color: Colors.white,
              ),
              onPressed: () {
                // email para clientes
                
              },
            ),
            IconButton(
              icon: Icon(Icons.sms, color: Colors.white),
              onPressed: () {
                // Sms para funcionarios
              },
            ),
            IconButton(
              icon: Icon(Icons.mail_outline, color: Colors.white),
              onPressed: () {
                // Email para multipessoal
              },
            ),
          ],
        ),
      ),
      appBar: new AppBar(
        title: Text(title),
        backgroundColor: Colors.grey[800],
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Adicionar evento
            },
          ),
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () {
              // Adicionar funcionario
            },
          ),
          IconButton(
            icon: Icon(Icons.business_center),
            onPressed: () {
              // Adicionar cliente
            },
          ),

          ],
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
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Container(
                  
                  width: 150,
                  color: Colors.grey[200],
                  child: ListView(
                    children: <Widget>[
                      drag,
                      drag,
                      drag,

                    ],
                  )
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: GridView.count(
                      scrollDirection: Axis.horizontal,
                      physics: ScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      children: <Widget>[
                        card,
                        card,
                        card,
                        card,
                        card
                        
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
