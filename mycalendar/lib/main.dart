import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mycalendar/models/cliente.dart';
import 'package:mycalendar/models/empregado.dart';
import 'package:mycalendar/models/evento.dart';
import 'package:dropdownfield/dropdownfield.dart';

import 'package:flutter_masked_text/flutter_masked_text.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'myCalendar',
      theme: ThemeData(
        primarySwatch: Colors.grey,
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
  bool refreshCardEventos = false;  // serve para dar refresh a uma card de evento , usado quando um funcionario quer ser adicionado a um evento




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
      //print(e.toString());
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
      //print(clientezito.toString());
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
  Guarda os valores de um evento inicial na base de dados
   */
  void _guardarEventoBD(String data , String nomeCliente , String farda, String local) async{
    try{
      await FirebaseDatabase.instance.reference().child('eventos').child(data).child('${this.eventosDia.length}').set({
        'cliente' : nomeCliente,
        'farda' : farda,
        'local' : local
      });
    }on Exception {
      print("excepcao em guardar eventos bd");
    }
  }
  
  
  /*
  Adiciona um horario a um evento previamente guardado na bd
   */
  void _addHorarioEventoBD(Evento evento, String horaEntrada, String horaSaida , int total) async {

    print("OLHA O EVENTO FRESQUINHO ${this.eventosDia.toString()}");
    int indiceEvento = this.eventosDia.indexOf(evento);
    try{
      await FirebaseDatabase.instance.reference().child('eventos').child(getData()).child('$indiceEvento').child('horario').child(horaEntrada).set({
        'fim' : horaSaida,
        'total' : total
      });
    }on Exception {
      print("excepcao em guardar eventos bd");
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
    mapa.forEach((data,numero) {
      int dia = int.parse(data.toString().substring(0,2));
      int mes = int.parse(data.toString().substring(3,5));
      int ano = int.parse(data.toString().substring(6,10));
      DateTime datinha = new DateTime(ano,mes,dia);

      //print(numero.toString());
      List eventosDia1 = numero;
      eventosDia1.forEach((zeca) {
        Map info = zeca;
        Cliente cliente = _buscarClientePorNome(info['cliente'].toString());
        Map<String,int> horario1 = new Map<String,int>();
        Map<String,String> horario2 = new Map<String,String>();
        Map<String,List<Empregado>> horario3 = new Map<String,List<Empregado>>();
        if(info['horario'] != null) {
          Map horarios = info['horario'];
          horarios.forEach((dataEntrada, infos) {
            horario1[dataEntrada] = infos['total'];
            horario2[dataEntrada] = infos['fim'];
            if(infos['empregados'] != null) {
              // ja tiver empregados naquele horario
              List<Empregado> listita = new List<Empregado>();
              Map emps = infos['empregados'];
              emps.forEach((nome , _) {
                listita.add(_procurarEmp(nome));
              });

              horario3[dataEntrada] = listita;
            }
          });
        }
        if( cliente != null) {
          // Damos um double check que o cliente nao e null
          Evento evento = new Evento(cliente,local: info['local'].toString(),farda: info['farda'].toString(),data: datinha,horarioEntradaComFuncionariosTotais: horario1,horarioFuncionarios: horario3,horarios: horario2);
          //print(evento.toString());
          eventosAux.add(evento);
        } else {
          // nao encontrou cliente
          print("nao encontrei o cliente");
        }
      });


    });
    this.eventos = eventosAux;
    return eventosAux;
  }


/*
Procura um empregado pelo nome
 */
  Empregado _procurarEmp(String nome) {
    for( int i = 0 ; i < this.empregados.length ; i++) {
      if(this.empregados[i].nome == nome) return this.empregados[i];
    }
    return null;
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
          data: empregado.nome,
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
  Devolve uma lista de widgets com os nomes dos funcionarios para
  um determinado horario de um evento

   */

  List<Widget>_listaEmpregadosPorHorario(Evento ev , String horarioEntrada ) {
    List<Widget> listita = new List<Widget>();
    List<Empregado> empregaditos = ev.horarioFuncionarios[horarioEntrada];  //vamos buscar a lista de funcionarios referente ao horario de entrada deste evento
    if(empregaditos != null)
      empregaditos.forEach((empregado){
        listita.add(Text(empregado.nome , style: TextStyle(color: Colors.grey),));
      });
    else listita.add(Text(""));
    return listita;
  }


  /*
  Cria 1 widget droppable por evento
   */
  List<Widget> _buscarEventosWidget() {
    List<Widget> eventosAux = new List<Widget>();
    this.eventosDia.forEach((evento){
        eventosAux.add(Container(
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
                    Text(evento.totalEmpregados.toString()),
                    IconButton(
                      icon: Icon(Icons.alarm_add,),
                      onPressed: () {
                        _mostrarAddHorario(evento);
                      },
                    )
                  ],
                ),
                evento.local != 'sem'?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.location_on, color: Colors.grey),
                    Text(evento.local)
                  ],
                ) : Text(""),
                Expanded(
                  child: evento.horarios == null || evento.horarios.length == 0? Center(child: Text("Sem horarios adicionados"),) : ListView(
                    shrinkWrap: true,
                    children: evento.horariosOdernados().entries.map((entrada) => DragTarget(
                      builder: (context , List<String> CandidateData, rejectedData){
                        return Container(
                          decoration: new BoxDecoration(
                              border: Border.all(color: Colors.grey[300],width: 2),
                              color: Colors.grey[800],
                              borderRadius: new BorderRadius.only(
                                  topLeft: const Radius.circular(20.0,),
                                  topRight: const Radius.circular(20.0),
                                  bottomLeft: const Radius.circular(20.0),
                                  bottomRight: const Radius.circular(20.0))),
                          child: Center(
                            child: Column(
                              children: <Widget>[
                                Text("${entrada.key}",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20,color: Colors.grey[300])),
                                //Text("-",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 8,color: Colors.grey[300])),
                                Text("até ${entrada.value}",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 10,color: Colors.grey[300])),
                                //SizedBox(height: 10,),
                                Column(children: _listaEmpregadosPorHorario(evento, entrada.key)),
                                Row(
                                mainAxisAlignment: MainAxisAlignment.center
                                ,children: <Widget>[
                                  evento.horarioFuncionarios[entrada.key] != null?
                                  Text("${evento.horarioFuncionarios[entrada.key].length}",style: TextStyle(color: Colors.white),) :
                                      Text("0",style: TextStyle(color: Colors.white),),
                                  Icon(Icons.account_circle,color: Colors.grey,),
                                  Text("${evento.horarioEntradaComFuncionariosTotais[entrada.key]}",style: TextStyle(color: Colors.grey),)]),
                                SizedBox(height: 10,)
                              ],
                            ),
                          ),
                        );
                      },
                      onAccept: (nomeFuncionario) async{
                        Empregado escolhido = _procurarEmp(nomeFuncionario);
                        if(evento.horarioFuncionarios[entrada.key] == null){
                          // Se nao exister uma lista de funcionarios para este horario de entrada
                          // Vamos criar
                          List<Empregado> aux = new List<Empregado>();
                          aux.add(escolhido);
                          evento.horarioFuncionarios[entrada.key] = aux;
                          evento.empregados.add(escolhido);
                          evento.totalEmpregados++;
                          setState(() {
                            // altera o numero total de empregados
                          });
                        }else {
                          // ja existe pelos menos 1 funcionario neste horario , vamos adicionar outro
                          if(!evento.horarioFuncionarios[entrada.key].contains(escolhido)) {
                            // se ainda nao tiver posto esse utilizador
                            evento.horarioFuncionarios[entrada.key].add(escolhido);
                            evento.empregados.add(escolhido);
                            evento.totalEmpregados++;
                            setState(() {
                              // altera o numero total de empregados
                            });
                          }
                        }
                      },
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ));



    });
    return eventosAux;
  }


/*
Atualiza a lista de eventos do dia
 */
void _atualizarEventosDia() {
  eventosDia.clear();
  this.eventos.forEach((evento) {
    if(evento.data.day == _selectedDay.day && evento.data.month == _selectedDay.month && evento.data.year == _selectedDay.year) {
      print(evento.data.toString());
      eventosDia.add(evento);
    }
  });
  mudeiDeDia=false;
}


/*
Retorna o total de empregados associados a um horario e entrada no presente dia
 */
int _totalEmpregadosTrabalhando(){
  int total = 0;
  this.eventosDia.forEach((evento){
    total += evento.totalEmpregados;
  });
  return total;

}



  /*
  Transforma o objeto _selectedDay numa data em String
   */
  String getData() {
    String title = _selectedDay.day.toString();
    if(title.length == 1) title = "0" + title;
    title += "-";
    if(_selectedDay.month.toString().length == 1) title+= "0";
    title += _selectedDay.month.toString();
    title += "-";
    title += _selectedDay.year.toString();
    return title;
  }

  @override
  Widget build(BuildContext context) {
    String title = getData();



    if(refreshCardEventos){
      // um funcionario foi adicionado , vamos refrescar a card de eventos

    }



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


    if(!precisoEventos)
      if(mudeiDeDia) _atualizarEventosDia();

    print("TAMANHO EVENTOS DO DIA ${this.eventosDia.length}");


    return new Scaffold(
        resizeToAvoidBottomPadding: false,
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
              Text(_totalEmpregadosTrabalhando().toString(), style: TextStyle(color: Colors.white),),
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
          backgroundColor: Colors.grey[300],
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
                      child:  eventosDia.length != 0 ?
                      GridView.count(
                        scrollDirection: Axis.horizontal,
                        physics: ScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        children: _buscarEventosWidget(),
                      ) : Center(
                        child:precisoTudo || precisoEventos ? Text("A buscar informacoes ..."): Text("Sem eventos neste dia , adicione um."),
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
                        return null;
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
                        return null;
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
    String data = getData();
    String local = "sem";

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SingleChildScrollView(
            child: AlertDialog(
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
                                    precisoTudo = true;
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
            ),
          );
        }
    );
  }



  _mostrarAddHorario(Evento evento) {
    final _formKey = GlobalKey<FormState>();
    var controllerEntrada = new MaskedTextController(mask: '00:00');
    var controllerSaida = new MaskedTextController(mask: '00:00');
    String entrada;
    String saida;
    int numEmpregados;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            //contentPadding: EdgeInsets.all(0.0),
              title: Text("Adicionar horario a ${evento.cliente.nome}", textAlign: TextAlign.center,),
              content: SingleChildScrollView(
                child:
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TextFormField(
                        // hora entrada
                        keyboardType: TextInputType.number,
                        validator: (horaEntrada) {
                          if(horaEntrada.isEmpty) return "Insere uma hora de entrada";
                          if(horaEntrada.length != 5) return "Insere 4 numeros";
                          int hora = int.parse(horaEntrada.substring(0,2));
                          int minuto = int.parse(horaEntrada.substring(3,5));
                          if(hora > 24 || hora < 0 || minuto > 60 || minuto < 0) return "Insere uma hora valida (hh:mm)";
                          return null;
                        },
                        controller: controllerEntrada,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.green),
                              borderRadius: BorderRadius.all(Radius.circular(12.0))
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.all(Radius.circular(12.0)),
                          ),
                          icon: Icon(Icons.arrow_forward),
                          hintText: "Hora Entrada",
                          contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 30.0, 10.0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                        ),
                        onSaved: (value) {
                          entrada = value;
                        },
                      ),
                      SizedBox(height: 20,),
                      TextFormField(
                        // hora saida
                        keyboardType: TextInputType.number,
                        validator: (horaEntrada) {
                          if(horaEntrada.isEmpty) return "Insere uma hora de saida";
                          if(horaEntrada.length != 5) return "Insere 4 numeros";
                          int hora = int.parse(horaEntrada.substring(0,2));
                          int minuto = int.parse(horaEntrada.substring(3,5));
                          if(hora > 24 || hora < 0 || minuto > 60 || minuto < 0) return "Insere uma hora valida (hh:mm)";
                          return null;
                        },
                        controller: controllerSaida,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.green),
                              borderRadius: BorderRadius.all(Radius.circular(12.0))
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.all(Radius.circular(12.0)),
                          ),
                          icon: Icon(Icons.arrow_back),
                          hintText: "Hora Saida",
                          contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 30.0, 10.0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                        ),
                        onSaved: (value) {
                          saida = value;
                        },
                      ),
                      SizedBox(height: 20,),
                      TextFormField(
                        // numero funcionarios
                        keyboardType: TextInputType.number,
                        validator: (quantidade) {
                            if(quantidade.isEmpty) return "Insere a quantidade de funcionarios";
                            if(int.parse(quantidade) < 0) return "Numero nao valido";

                            return null;
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
                          icon: Icon(Icons.accessibility),
                          hintText: "Quantidade funcionarios",
                          contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 30.0, 10.0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                        ),
                        onSaved: (value) {
                          numEmpregados = int.parse(value);
                        },
                      ),
                      SizedBox(height: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          FlatButton(
                            child: Text("Guardar"),
                            onPressed: () async{
                              if(_formKey.currentState.validate()) {
                                _formKey.currentState.save();
                                if(evento.horarioEntradaComFuncionariosTotais.containsKey(entrada)){
                                  // ja existe este horario de entrada
                                  Navigator.pop(context);
                                  _mostrarAvisoHorarioExistente();
                                  return;
                                }
                                print("A guarda evento na bd");
                                _addHorarioEventoBD(evento, entrada, saida, numEmpregados);
                                setState(() {
                                  precisoTudo = true;
                                });
                                

                                Navigator.pop(context);


                              } 
                            },
                          ),
                          FlatButton(
                            child: Text("Cancelar"),
                            onPressed: () => Navigator.pop(context),
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

  /*
  Aviso que ja existe um horario com essa hora de entrada
   */
  _mostrarAvisoHorarioExistente() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Ups!"),
          content: Text("Horario de entrada ja existe no evento em contexto."),
          actions: <Widget>[
            FlatButton(
              child: Text("Entendi"),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        );
      }
    );

  }





}
