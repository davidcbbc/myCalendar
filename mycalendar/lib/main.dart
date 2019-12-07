import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mycalendar/models/cliente.dart';
import 'package:mycalendar/models/empregado.dart';
import 'package:mycalendar/models/evento.dart';
import 'package:dropdownfield/dropdownfield.dart';

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
  List<Evento> eventosDia = List<Evento>(); // Lista de eventos do dia escolhido em _selectedDay
  bool precisoEmpregados = false; // Quando este bool esta a true , quer dizer que e necessario uma pesquisa a base de dados para atualizar a lista de empregados
  bool precisoClientes = false; // Quando este bool esta a true , quer dizer que e necessario uma pesquisa a base de dados para atualizar a lista de clientes
  bool precisoEventos = false; // Quando este bool esta a true , quer dizer que e necessario uma pesquisa a base de dados para atualizar a lista de eventos
  bool precisoTudo = true;  // Vai buscar os dados de empregados , clientes e eventos
  bool mudeiDeDia = true;
  int funcionariosTrabalhar = 0;  // numero de funcionarios a trabalhar no dia _selectedDay


  /*
  Vai buscar funcionarios a base de dados e atualiza a lista
  empregados.
   */
  Future<List<Empregado>> _buscarEmpregados() async {
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
    this.empregados = empregadosAux;
    return empregadosAux;
  }



  /*
  Vai buscar clientes a base de dados e atualiza a lista
  clientes.
   */
  Future<List<Cliente>> _buscarClientes() async {
    List<Cliente> clientesAux = new List<Cliente>();
    var bd = await FirebaseDatabase.instance.reference().child('clientes').once();
    Map mapa = bd.value;
    mapa.forEach((cliente,info) {
      Cliente clientezito = new Cliente(cliente.toString(),info['email'].toString());
      print(clientezito.toString());
      clientesAux.add(clientezito);
    });
    this.clientes = clientesAux;
    return clientesAux;
  }



  /*
  Procura um cliente pelo nome na lista clientes e devolve
  o cliente , se nao encontrar devolve null
  */
  Cliente _buscarClientePorNome(String nome){
    for( int i = 0 ; i < this.clientes.length ; i++)
      if(this.clientes[i].nome == nome) return this.clientes[i];
    return null;
  }


  /*
  Guarda os valores de um funcionario na base de dados
   */
  void _guardarFuncionarioBD(String nome , String disponibilidade , String telemovel) async{
    try{
      await FirebaseDatabase.instance.reference().child('funcionarios').child(nome).set({
        'disp' : disponibilidade,
        'telemovel' : telemovel
      });
    }on Exception {
      print("exception");
    }
  }


  /*
  Guarda os valores de um evento na base de dados
   */
  void _guardarEventoBD(String data , String nomeCliente , String farda, String local) async{
    try{
      await FirebaseDatabase.instance.reference().child('eventos').child(data).set({
        'cliente' : nomeCliente,
        'farda' : farda,
        'local' : local
      });
    }on Exception {
      print("exception");
    }
  }

  /*
  Vai buscar eventos a base de dados e atualiza a lista
  eventos.
  Nota: esta funcao so deve ser chamada depois da _buscarClientes()
  visto que necessita de um cliente para construir um objeto to tipo Evento.
   */
  Future<List<Evento>> _buscarEventos() async {
    List<Evento> eventosAux = new List<Evento>();
    var bd = await FirebaseDatabase.instance.reference().child('eventos').once();
    Map mapa = bd.value;
    mapa.forEach((data,info) {
      int dia = int.parse(data.toString().substring(0,2));
      int mes = int.parse(data.toString().substring(3,5));
      int ano = int.parse(data.toString().substring(6,10));
      DateTime datinha = new DateTime(ano,mes,dia);
      Cliente cliente = _buscarClientePorNome(info['cliente'].toString());
      if( cliente != null) {
        // Damos um double check que o cliente nao e null
        Evento evento = new Evento(cliente,local: info['local'].toString(),farda: info['farda'].toString(),data: datinha);
        print(evento.toString());
        eventosAux.add(evento);
      } else {
        // nao encontrou cliente
        print("nao encontrei o cliente");
      }
    });
    this.eventos = eventosAux;
    return eventosAux;
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
  Cria 1 widget droppable por evento
   */
  List<Widget> _buscarEventosWidget() {
    //_buscarEventos();
    List<Widget> eventosAux = new List<Widget>();
    //print("ESTA LITA TEM ${this.eventos.length}");
    this.eventos.forEach((evento){
      //print("EVENTO -> ${evento.data.toString()} DIA SELECIONADO ${_selectedDay}");
      int diasDeDiferenca = evento.data.difference(_selectedDay).inDays;  //calcula os dias de diferenca
      if(diasDeDiferenca == 0) { //se for 0 esta no mm dia
        eventosAux.add( DragTarget(
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
                      evento.cliente.nome,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.people,
                          color: Colors.grey[800],
                        ),
                        Text(evento.totalEmpregados.toString())
                      ],
                    ),
                    evento.local != 'sem'?
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.location_on, color: Colors.grey),
                        Text(evento.local)
                      ],
                    ) : Text("")
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
        ));

      }

    });
    return eventosAux;
  }


/*
  /*
  Vai buscar empregados , eventos e clientes a
  base de dados e atualiza todas as listas
   */
  Future _buscarDadosTodos() async {
    await _buscarEmpregados();
    await _buscarClientes();
    await _buscarEventos();
    setState(() {
      precisoTudo = false;
    });
  }
*/


/*
Atualiza a lista de eventos do dia
 */
void _atualizarEventosDia() {
  this.eventos.forEach((evento) {
    int diasDeDiferenca = evento.data.difference(_selectedDay).inDays;  //calcula os dias de diferenca
    if(diasDeDiferenca == 0) eventosDia.add(evento);
  });
  mudeiDeDia=false;
}



  /*
  Transforma o objeto _selectedDay numa data em String
   */
  String _mudarData() {
    String title = _selectedDay.day.toString();
    if(title.length == 1) title = "0" + title;
    title += "-";
    title += _selectedDay.month.toString();
    title += "-";
    title += _selectedDay.year.toString();
    return title;
  }

  @override
  Widget build(BuildContext context) {
    String title = _mudarData();




    if(precisoEmpregados){
      _buscarEmpregados().then((_){
        setState(() {
          precisoEmpregados = false;
        });
      });
    }


    if(precisoEventos){
      _buscarEventos().then((_){
        setState(() {
          precisoEventos = false;
        });
      });
    }


    if(precisoTudo) {
      _buscarEmpregados().then((_) {
        _buscarClientes().then((_){
          _buscarEventos().then((_) {
            _atualizarEventosDia();
            setState(() {
              precisoTudo = false;
            });
          });
        });
      });
    }


    if(mudeiDeDia) _atualizarEventosDia();





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
              Icon(
                Icons.group,
                color: Colors.grey,
              ),
              Text(funcionariosTrabalhar.toString(), style: TextStyle(color: Colors.white),),
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

            ],
          ),
          backgroundColor: Colors.grey[800],
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                // Adicionar evento
                _mostrarAddEvento("Adicionar evento");
              },
            ),
            IconButton(
              icon: Icon(Icons.person_add),
              onPressed: () {
                // Adicionar funcionario
                _mostrarAddFuncionario("Adicionar funcionario");
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
                child: precisoEmpregados || precisoTudo ?
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
                        eventosDia.clear(); //da clear a lista de eventos do dia
                        mudeiDeDia = true;
                        funcionariosTrabalhar = 0;
                      });
                    },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: precisoTudo? CircularProgressIndicator()
                          : eventosDia.length != 0 ?
                      GridView.count(
                        scrollDirection: Axis.horizontal,
                        physics: ScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        children: _buscarEventosWidget(),
                      ) : Center(
                        child: Text("Sem eventos neste dia , adicione um."),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ));
  }

  _mostrarAddFuncionario(String titulo) {
    final List<String> _disps = ['Total', 'Reduzida', 'Ocasional'].toList();  // serve para adicionar funcionarios
    String _disp = "";
    final _formKey = GlobalKey<FormState>();
    String nome;
    String disp;
    String telemovel;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          //contentPadding: EdgeInsets.all(0.0),
            title: Text(titulo),
          content: SingleChildScrollView(
            child:
              Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      // nome
                      validator: (val){
                        if(val.isEmpty) return "Escolhe um nome";
                      },
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                            borderRadius: BorderRadius.all(Radius.circular(12.0))
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                        icon: Icon(Icons.title,color: Colors.grey,),
                        hintText: "Nome",
                        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                      ),
                      onSaved: (value) {
                        nome = value;
                      },
                    ),
                    SizedBox(height: 20,),
                    TextFormField(
                      // telemovel
                      keyboardType: TextInputType.phone,
                      maxLength: 9,
                      validator: (val){
                        if(val.isEmpty) return "Escolhe um nr telemovel";
                        if(val.length != 9) return "Insire 9 numeros";

                      },
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                            borderRadius: BorderRadius.all(Radius.circular(12.0))
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                        icon: Icon(Icons.phone_android,color: Colors.grey,),
                        hintText: "Telemovel",
                        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                      ),
                      onSaved: (valor) {
                        telemovel = valor;
                      },
                    ),
                    SizedBox(height: 20,),
                    DropDownField(
                        value: _disp,
                        required: true,
                        strict: true,
                        labelText: 'Disponibilidade',
                        items: _disps,
                        setter: (dynamic newValue) {
                          print("OLHA $newValue");
                        },
                      onValueChanged: (disponibilidade) {
                          if(disponibilidade == "Total") disp = "DIS_TOTAL";
                          if(disponibilidade == "Reduzida") disp = "DIS_REDUZIDA";
                          if(disponibilidade == "Ocasional") disp = "DIS_OCASIONAL";
                      },
                    ),
                    SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        FlatButton(
                          child: Text("Guardar"),
                          onPressed: () {
                            // Guardar os valores e enviar para a base de dados
                            if(_formKey.currentState.validate()) {
                              _formKey.currentState.save();
                              print("aaa");
                              print("a guardar funcionario $nome $disp $telemovel");
                              _guardarFuncionarioBD(nome,disp,telemovel);
                              setState(() {
                                precisoEmpregados = true;
                              });
                              Navigator.pop(context);
                            }

                          },

                        ),
                        FlatButton(
                          child: Text("Cancelar"), onPressed: () {
                            Navigator.pop(context);
                        },
                        ),

                      ],
                    )
                  ],
                ),

              )
            ,
          )
        );
      }
    );
  }


  _mostrarAddEvento(String titulo) {
    final _formKey = GlobalKey<FormState>();
    List<String> clientesAux = new List<String>();
    List<String> fardas = ['Camisa preta' , 'Camisa branca e laco' , 'Camisa branca, colete e laco'];
    String farda = "";
    clientes.forEach((cliente){
      clientesAux.add(cliente.nome);
    });
    String _cliente ;
    String data = _mudarData();
    String local = "sem";

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            //contentPadding: EdgeInsets.all(0.0),
              title: Text(titulo),
              content: SingleChildScrollView(
                child:
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TextFormField(
                        // nome
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.green),
                              borderRadius: BorderRadius.all(Radius.circular(12.0))
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.all(Radius.circular(12.0)),
                          ),
                          icon: Icon(Icons.location_on,color: Colors.grey,),
                          hintText: "Local",
                          contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                        ),
                        onSaved: (value) {
                          if(value.isEmpty) local = "sem";
                          else local = value;
                        },
                      ),
                      SizedBox(height: 20,),
                      DropDownField(
                        value: _cliente,
                        required: true,
                        strict: true,
                        labelText: 'Cliente',
                        items: clientesAux,
                        setter: (dynamic newValue) {
                          print("OLHA $newValue");
                        },
                        onValueChanged: (cliente1) {
                          _cliente = cliente1;
                        },
                      ),
                      SizedBox(height: 20,),
                      DropDownField(
                        value: farda,
                        required: false,
                        strict: true,
                        labelText: 'Farda',
                        items: fardas,
                        setter: (dynamic newValue) {
                          print("OLHA $newValue");
                        },
                        onValueChanged: (farda1) {
                          farda = farda1;
                        },
                      ),
                      SizedBox(height: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          FlatButton(
                            child: Text("Guardar"),
                            onPressed: () async {
                              // Guardar os valores e enviar para a base de dados
                              if(_formKey.currentState.validate()) {
                                _formKey.currentState.save();
                                if(farda.isEmpty) farda = 'sem';
                                print("a guardar evento $_cliente $data farda $farda local $local");
                                _guardarEventoBD(data, _cliente, farda, local);
                                await _buscarEventos();
                                setState(() {
                                  precisoEventos = true;
                                });
                                Navigator.pop(context);
                              }

                            },

                          ),
                          FlatButton(
                            child: Text("Cancelar"), onPressed: () {
                            Navigator.pop(context);
                          },
                          ),

                        ],
                      )
                    ],
                  ),

                )
                ,
              )
          );
        }
    );
  }


}
