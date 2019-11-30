import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mycalendar/models/cliente.dart';
import 'package:mycalendar/models/empregado.dart';
import 'package:mycalendar/models/evento.dart';

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
  DateTime _selectedDay = DateTime.now();
  List<Empregado> empregados = List<Empregado>(); // Lista de empregados atualizados ou nao da base de dados
  List<Cliente> clientes = List<Cliente>(); // Lista de clientes atualizados ou nao da base de dados
  List<Evento> eventos = List<Evento>(); //Lista de eventos atualizados ou nao da base de dados
  bool precisoEmpregados = true; // Quando este bool esta a true , quer dizer que e necessario uma pesquisa a base de dados para atualizar a lista de empregados
  bool precisoClientes = true; // Quando este bool esta a true , quer dizer que e necessario uma pesquisa a base de dados para atualizar a lista de clientes
  bool precisoEventos = true; // Quando este bool esta a true , quer dizer que e necessario uma pesquisa a base de dados para atualizar a lista de eventos
  




  /*
  Vai buscar funcionarios a base de dados e atualiza a lista
  empregados.
   */
  Future<void> _buscarEmpregados() async {
    List<Empregado> empregadosAux = new List<Empregado>();
    var teste = await FirebaseDatabase.instance
        .reference()
        .child('funcionarios')
        .once();
    Map mapa = teste.value;
    mapa.forEach((nomeEmpregado, info) {
      // Serializar de json para classe Empregado
      Empregado e = new Empregado(nomeEmpregado.toString(),
          info['disp'].toString(), int.parse(info['telemovel'].toString()));
      print(e.toString());
      empregadosAux.add(e);
    });
    setState(() {
      this.empregados = empregadosAux;
      precisoEmpregados=false;
    });
  }


  /*
  Vai buscar clientes a base de dados e atualiza a lista
  clientes.
   */
  Future<void> _buscarClientes() async {
    List<Cliente> clientesAux = new List<Cliente>();
    var bd = await FirebaseDatabase.instance.reference().child('clientes').once();
    Map mapa = bd.value;
    mapa.forEach((cliente,info) {
      Cliente clientezito = new Cliente(cliente.toString(),info['email'].toString());
      print(clientezito.toString());
      clientesAux.add(clientezito);
    });
    setState(() {
      this.clientes = clientesAux;
      precisoClientes = false;
    });
  }

  
  
  /*
  Procura um cliente pelo nome na lista clientes e devolve
  o cliente , se nao encontrar devolve null
  */
  Cliente _buscarClientePorNome(String nome){
    this.clientes.forEach((cliente) {
      if(cliente.nome == nome) return cliente;
    });
    return null;
  }
  
  
  
  
  
  /*
  Vai buscar eventos a base de dados e atualiza a lista
  eventos. 
  Nota: esta funcao so deve ser chamada depois da _buscarClientes()
  visto que necessita de um cliente para construir um objeto to tipo Evento.
   */
  Future<void> _buscarEventos() async {
    List<Evento> eventosAux = new List<Evento>();
    var bd = await FirebaseDatabase.instance.reference().child('eventos').once();
    Map mapa = bd.value;
    mapa.forEach((data,info) {
      print(info['cliente'].toString());
      Cliente cliente = _buscarClientePorNome(info['cliente'].toString());
      if( cliente != null) {
        // Damos um double check que o cliente nao e null
        Evento evento = new Evento(cliente,local: info['local'].toString(),farda: info['farda'].toString());
        print(evento.toString());
        eventosAux.add(evento);
      } else {
        // nao encontrou cliente
        print("nao encontrei o cliente");
      }
    });
    setState(() {
      this.eventos = eventosAux;
      precisoEventos = false;
    });
  }





  /*
  Cria 1 widget card arrastavel por empregado e divide
  em 3 categorias dependendo da disponibilidade do empregado
  depois juntam-se essas 3 categorias numa lista so (listaDeCards)
   */
  List<Widget> _buscarEmpregadosWidget() {
    List<Widget> listaDeCards = new List<Widget>();
    List<Widget> dispTotal = new List<Widget>();
    List<Widget> dispReduzida = new List<Widget>();
    List<Widget> dispOcasional = new List<Widget>();

    empregados.forEach((empregado) {
      // Adiciona uma card arrastavel para cada empregado
      var card = Draggable<String>(
          data: "hey",
          childWhenDragging: Container(
            child: Text(
              empregado.nome,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          child: Container(
            child: Text(
              empregado.nome,
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          feedback: Material(
            child: Container(
              color: Colors.grey,
              child: Text(
                empregado.nome,
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ));
      // adiciona este card a lista que pertence dependendo da sua disponibilidade
      if (empregado.disponibilidade == "DISP_TOTAL") {
        dispTotal.add(card);
        dispTotal.add(SizedBox(
          height: 5,
        ));
      } else if (empregado.disponibilidade == "DISP_REDUZIDA") {
        dispReduzida.add(card);
        dispReduzida.add(SizedBox(
          height: 5,
        ));
      } else {
        dispOcasional.add(card);
        dispOcasional.add(SizedBox(
          height: 5,
        ));
      }
    });

    if (dispTotal.length > 0) {
      listaDeCards.add(
        Text(
          "Disponibilidade Total",
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
      listaDeCards.addAll(dispTotal);
    }

      if (dispReduzida.length > 0) {
        listaDeCards.add(
          Text(
            "Disponibilidade Reduzida ",
            style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        );
        listaDeCards.addAll(dispReduzida);
      }

      if (dispOcasional.length > 0) {
        listaDeCards.add(
          Text(
            "Disponibilidade Ocasional",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        );
        listaDeCards.addAll(dispOcasional);
      }

      return listaDeCards;

  }

  /*
  Muda a data do canto superior esquerdo
   */
  String _mudarData() {
    String title = _selectedDay.day.toString();
    title += "-";
    title += _selectedDay.month.toString();
    title += "-";
    title += _selectedDay.year.toString();
    return title;
  }

  @override
  Widget build(BuildContext context) {
    String title = _mudarData();

    final card = DragTarget(
      builder: (context, List<String> candidateData, rejectedData) {
        return Container(
          padding: EdgeInsets.all(10),
          height: 80,
          width: 100,
          child: Card(
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Evento",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.people,
                      color: Colors.grey[800],
                    ),
                    Text("0")
                  ],
                ),
              ],
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

    if (precisoEmpregados)
      _buscarEmpregados(); // Atualiza lista de empregados da bd

    if (precisoClientes)
      _buscarClientes();  // Atualiza lista de clientes da bd

    if (precisoEventos)
      _buscarEventos(); // Atualiza lista de eventos da bd

    return new Scaffold(
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              DrawerHeader(
                child: Center(
                  child: CircleAvatar(
                    child: Icon(
                      Icons.perm_contact_calendar,
                      size: 60,
                      color: Colors.white,
                    ),
                    radius: 50.0,
                    backgroundColor: Colors.grey[500],
                  ),
                ),
                decoration: BoxDecoration(color: Colors.grey[300]),
              ),
              ListTile(
                title: Text("Estatísticas"),
                leading: Icon(Icons.insert_chart),
                onTap: () {
                  // Abrir aba das estatisticas
                },
              ),
              ListTile(
                title: Text("Definições"),
                leading: Icon(Icons.settings),
                onTap: () {
                  // abrir aba das definicoes
                },
              ),
            ],
          ),
        ),
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
          title: Row(
            children: <Widget>[
              Text(title),
              SizedBox(
                width: 10,
              ),
              Icon(
                Icons.group,
                color: Colors.grey,
              ),
              Text("22")
            ],
          ),
          backgroundColor: Colors.grey[800],
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                // Adicionar evento
                setState(() {
                  precisoEmpregados = true;
                });
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
        body: Row(
          children: <Widget>[
            Container(
                width: 150,
                color: Colors.grey[200],
                child: precisoEmpregados?
                    Center(
                      child: CircularProgressIndicator(),
                    ): ListView(
                  children:  _buscarEmpregadosWidget(),
                )
            ),
            Expanded(
              child: Column(
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: GridView.count(
                        scrollDirection: Axis.horizontal,
                        physics: ScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        children: <Widget>[card, card, card, card, card],
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ));
  }
}
