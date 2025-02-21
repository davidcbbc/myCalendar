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
import 'package:mycalendar/screens/evento.dart';

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
  List<Empregado> empregadosEscolhidos = List<Empregado>(); // Lista de empregados com certo tip ( de manha , etc...)
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
  bool mudeiEmpregados = false; // quando se muda o tipo de empregados q se quer , manha , tarde , noite , etc..
  String tipoDeHorario = "Todos"; // string que mudar de acordo com os horarios dos funcionarios escolhidos MANHA / TARDE / NOITE / TODOS

  @protected
  @mustCallSuper
  void initState() {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  }



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
    this.empregadosEscolhidos = this.empregados;
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




  /// Guarda um cliente na BD
  void _guardarClienteBD(String nome , String email) async{
    print("A guardar cliente $nome na BD");
    try{
      await FirebaseDatabase.instance.reference().child('clientes').child(nome).set({
        'email' : email
      });
    }on Exception {
      print("exception");
    }
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


      List eventosDia1 = numero;
      eventosDia1.forEach((zeca) {
        int totalEmpregados = 0;
        Map info = zeca;
        Cliente cliente = _buscarClientePorNome(info['cliente'].toString());
        Map<String,int> horario1 = new Map<String,int>();
        Map<String,String> horario2 = new Map<String,String>();
        //Map<String,String> funcionarios = new Map<String,String>();
        Map<String,List<Empregado>> horario3 = new Map<String,List<Empregado>>();
        if(info['horario'] != null) {
          Map horarios = info['horario'];
          horarios.forEach((dataEntrada, infos) {
            horario1[dataEntrada] = infos['total'];
            horario2[dataEntrada] = infos['fim'];
            if(infos['funcionarios'] != null){


              // buscar os funcionarios para os horários correspondetes
              List<Empregado> listaAux = new List<Empregado>();
              //print(infos['funcionarios']);
              List list = infos['funcionarios'];
              list.forEach((nomeEmpregado) {
                if(nomeEmpregado != null){
                  totalEmpregados++;
                  Empregado emp = _procurarEmp(nomeEmpregado);
                  _adicionarHorarioFuncionario(emp, infos['fim'].toString(),datinha);
                  listaAux.add(emp);
                } else print("encontrei um a null");

              });
              horario3[dataEntrada] = listaAux;
            }

          });
        }
        if( cliente != null) {
          // Damos um double check que o cliente nao e null
          Evento evento = new Evento(cliente,local: info['local'].toString(),farda: info['farda'].toString(),data: datinha,horarioEntradaComFuncionariosTotais: horario1,horarioFuncionarios: horario3,horarios: horario2,totalEmpregados: totalEmpregados);
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
    if(empregadosEscolhidos.length == 0) listaDeCards.add(Center(child: Text("Lista vazia"),));
    else this.empregadosEscolhidos.forEach((empregado) {
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

    listaDeCards.add(Text("$tipoDeHorario Disp.",style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),textAlign: TextAlign.center));
    listaDeCards.add(SizedBox(height: 5.0,));
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


  /// Adiciona um funcionário a um dado horário na BD
  Future<void> _adicionarFuncionarioHorario(Empregado empregado, Evento evento, String horaEntrada) async{
    print("A adicionar horário a um funcionário ...");
    int indiceEvento = this.eventosDia.indexOf(evento);
    int index;
    try {
      FirebaseDatabase.instance.reference().child('eventos').child(
          getData()).child('$indiceEvento').child('horario').child(horaEntrada)
          .child('funcionarios').once().then((lista){
        if(lista.value != null){
          List list = lista.value;
          for(int i = 0 ; i < list.length ; i++){
            //ocupar valores que foram removidos
            if(list[i] == null) {
              index = i;
              break;  //para de procurar pq ja encontrou uma
            }
          }
          if(index == null) index = list.length; // caso nao hajam valores removidos , ocupa o index da ultima posicao
          print("index encontrado para este jovem > $index");

        } else index =0;
        FirebaseDatabase.instance.reference().child('eventos').child(
            getData()).child('$indiceEvento').child('horario').child(horaEntrada)
            .child('funcionarios')
            .update({
          index.toString() : empregado.nome
        });
      });
      return;
    } on Exception {
      print("escexao");
    }
  }



  /*
  Devolve uma lista de widgets com os nomes dos funcionarios para
  um determinado horario de um evento
  data devolve uma string com id do evento + "UPDATE" + horarioEntrada antigo ex: 0001UPDATE150:30Joao Carlos
   */
  List<Widget>listaEmpregadosPorHorario(Evento ev , String horarioEntrada ) {
    List<Widget> listita = new List<Widget>();
    List<Empregado> empregaditos = ev.horarioFuncionarios[horarioEntrada];  //vamos buscar a lista de funcionarios referente ao horario de entrada deste evento
    String indiceEvento = this.eventosDia.indexOf(ev).toString();
    if(empregaditos != null)
      empregaditos.forEach((empregado){
        //listita.add(Text(empregado.nome , style: TextStyle(color: Colors.grey),));
        listita.add(Draggable<String>(
            data:  indiceEvento.padLeft(4,'0')+ "UPDATE" + horarioEntrada+ empregado.nome,
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
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
            )));
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
      ScrollController scrollController = new ScrollController();
      int posicaoAntiga;
      int posicaoAntesDaAntiga;
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
                    ),
                    IconButton(icon:Icon(Icons.pageview, color: Colors.grey[600],),
                        onPressed: () {
                        // ver o evento full screen
                          //_mostrarEventoFullScreen(evento);
                          Navigator.of(context).push(new MaterialPageRoute(builder: (BuildContext context) => new VerEvento(evento,this.empregados,this.eventosDia,this.eventos,this.clientes)));
                        })
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
                evento.horarios.isNotEmpty ? DragTarget(
                  builder: (context , List<String> CandidateData, rejectedData){
                    return Container(
                      padding: EdgeInsets.only(left: 50,right: 50),
                      color: Colors.grey[400],
                      child: Icon(Icons.keyboard_arrow_up,size: 15,),

                    );
                  },
                  onWillAccept: (value){
                    double posicao = scrollController.offset;
                    print("OLHA O FILHO");

                      scrollController.animateTo(posicao - 10.0, curve: Curves.easeOut,
                        duration: const Duration(milliseconds: 300));
                    return true;
                  },

                ) : Text(""),
                Expanded(
                  child: evento.horarios == null || evento.horarios.length == 0? Center(child: Text("Sem horarios adicionados"),) : ListView(
                    controller: scrollController,
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
                                Text("${entrada.value}",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 10,color: Colors.grey[300])),
                                //SizedBox(height: 10,),
                                Column(children: listaEmpregadosPorHorario(evento, entrada.key)),
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
                      onWillAccept: (value){
                        // anda para cima e para baixo com o draggable
                        // sempre que um horario tiver um index maior que o antigo , aumenta 30 no offset
                        // se tiver um index menor , diminui 30 no offset
                        //print(scrollController.position.viewportDimension);
                       // print(scrollController.position.toString());
                        List<String> entradas =  evento.horariosOdernados().keys.toList();
                        if(value.contains("UPDATE")){
                          String entradaAntiga = value.substring(10,15); // entrada
                          if(posicaoAntiga == null) {
                            posicaoAntiga = entradas.indexOf(entradaAntiga);
                            posicaoAntesDaAntiga = entradas.indexOf(entradaAntiga);
                          }
                        } else {
                          if(posicaoAntiga == null){
                            posicaoAntiga = entradas.indexOf(entrada.key);
                            posicaoAntesDaAntiga = entradas.indexOf(entrada.key);
                          }
                        }
                        int posicaoAtual = entradas.indexOf(entrada.key);
                        double posicao = scrollController.offset;
                        if(posicaoAtual > posicaoAntiga){
                          print("posicao atual maior que a antiga");
                          posicao += 80.0;
                        } else if(posicaoAtual < posicaoAntiga){
                          print("posicao atual menor que a antiga");
                          posicao -= 80.0;
                        }
                        scrollController.animateTo(posicao, curve: Curves.easeOut,
                            duration: const Duration(milliseconds: 300));
                        posicaoAntesDaAntiga = posicaoAntiga;
                        posicaoAntiga = entradas.indexOf(entrada.key);
                        return true;
                      },
                      onAccept: (funcionario) async{
                        bool update = false;            // serve para saber se a transacao foi um update ou um insert
                        String entradaAntiga;           // vai buscar a entrada antiga caso seja um update
                        if(funcionario.contains("UPDATE")){
                          // quando o funcionario arrastado foi um update
                          // retiramos o update do nome e o id do evento
                          // ex: 0001UPDATE15:30Joao Carlos
                          update = true;
                          int idEventoEmpregado = int.parse(funcionario.substring(0,4));
                          if(idEventoEmpregado != this.eventosDia.indexOf(evento)) {
                            // nao esta a dar update a um empregado do mesmo evento
                            _mostrarAviso("Ups!", "Um empregado so pode comutar de horarios no mesmo evento");
                            return;
                          }
                          entradaAntiga = funcionario.substring(10,15);
                          funcionario = funcionario.substring(15);
                          print("Recebi um update de $funcionario");
                        }
                        Empregado escolhido = _procurarEmp(funcionario);
                        if(evento.podeAdicionarMaisFuncionarios(entrada.key)) {
                          if(escolhido.podeTrabalhar(DateTime(_selectedDay.year,_selectedDay.month,_selectedDay.day), entrada.value) || update){
                            if(escolhido.jaTrabalha(entrada.key, DateTime(_selectedDay.year,_selectedDay.month,_selectedDay.day), this.eventosDia) && !update){
                            _mostrarAviso("A trabalhar...", "Este funcinario ja se encontra a trabalhar dentro deste horario neste dia");
                            }else{
                              if(evento.horarioFuncionarios[entrada.key] == null){
                                // Se nao exister uma lista de funcionarios para este horario de entrada
                                // Vamos criar
                                List<Empregado> aux = new List<Empregado>();
                                aux.add(escolhido);
                                evento.horarioFuncionarios[entrada.key] = aux;
                                evento.empregados.add(escolhido);
                                _adicionarHorarioFuncionario(escolhido,entrada.value,_selectedDay);
                                evento.totalEmpregados++;
                                if(update) {
                                  //eleminar da lista na bd
                                  _eleminarFuncionarioHorario(escolhido,entradaAntiga,evento);
                                  // eleminar horario a funcionario
                                  _eleminarHorarioFuncionario(escolhido, entradaAntiga , evento);
                                  //eleminar da lista em memoria
                                  evento.horarioFuncionarios[entradaAntiga].remove(escolhido);
                                  evento.totalEmpregados--;
                                }
                                _adicionarFuncionarioHorario(escolhido, evento, entrada.key);
                                setState(() {
                                  // altera o numero total de empregados
                                });

                              }else {
                                // ja existe pelos menos 1 funcionario neste horario , vamos adicionar outro
                                if(!evento.horarioFuncionarios[entrada.key].contains(escolhido)) {
                                  // se ainda nao tiver posto esse utilizador
                                  evento.horarioFuncionarios[entrada.key].add(escolhido);
                                  evento.empregados.add(escolhido);
                                  _adicionarHorarioFuncionario(escolhido,entrada.value,_selectedDay);
                                  evento.totalEmpregados++;
                                  if(update) {
                                    //eleminar da lista na bd
                                    _eleminarFuncionarioHorario(escolhido,entradaAntiga,evento);
                                    // eleminar horario a funcionario
                                    _eleminarHorarioFuncionario(escolhido, entradaAntiga,evento);
                                    //eleminar da lista em memoria
                                    evento.horarioFuncionarios[entradaAntiga].remove(escolhido);
                                    evento.totalEmpregados--;
                                  }
                                  _adicionarFuncionarioHorario(escolhido, evento, entrada.key);
                                  setState(() {
                                    // altera o numero total de empregados
                                  });

                                }
                              }
                            }

                          } else {
                            // nao pode trabaljar nesta data pq esta ocupado
                            _mostrarAviso("Ocupado", "Este funcionario ja trabalha no horario da ${entrada.value}");
                          }

                        } else {
                          // aviso que ja tem o max funcionarios
                          if(!evento.horarioFuncionarios[entrada.key].contains(escolhido))
                            _mostrarAvisoHorarioCheio();
                        }
                      },
                    )).toList(),
                  ),
                ),
                evento.horarios.isNotEmpty ?  DragTarget(
                  builder: (context , List<String> CandidateData, rejectedData){
                    return Container(
                      padding: EdgeInsets.only(left: 50,right: 50),
                      color: Colors.grey[400],
                      child: Icon(Icons.keyboard_arrow_down,size: 15,),

                    );
                  },
                  onWillAccept: (value){
                    double posicao = scrollController.offset;
                    print("OLHA O FILHO");
                    scrollController.animateTo(posicao + 10.0, curve: Curves.easeOut,
                        duration: const Duration(milliseconds: 300));
                    return true;
                  },

                ) : Text(""),
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
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[

              IconButton(
                icon: Icon(Icons.access_time,color: Colors.white,),
                onPressed: () {
                  _mostrarTemposDoDia();
                },
              ),
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
                _mostrarAddCliente();
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
                        for(int i = 0 ; i < this.empregados.length ; i++) {
                          // check se já existe esse nome
                          if(this.empregados[i].nome == val) return "Esse nome já existe";
                        }
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
                          if(disponibilidade == "Total") disp = "DISP_TOTAL";
                          if(disponibilidade == "Reduzida") disp = "DISP_REDUZIDA";
                          if(disponibilidade == "Ocasional") disp = "DISP_OCASIONAL";
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
    String entrada;
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
                                String tipo;
                                int hora = int.parse(entrada.substring(0,2));
                                if(hora >= 5 && hora <=11) tipo = "manha";
                                else if(hora > 11 && hora <=17) tipo = "tarde";
                                else tipo = "noite";
                                  _addHorarioEventoBD(evento, entrada, tipo, numEmpregados);
                                setState(() {
                                  evento.horarios[entrada] = tipo;
                                  evento.horarioEntradaComFuncionariosTotais[entrada] = numEmpregados;
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



/// adicionar um cliente
  _mostrarAddCliente() {
    final _formKey = GlobalKey<FormState>();
    String nome;
    String email;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            //contentPadding: EdgeInsets.all(0.0),
              title: Text("Adicionar cliente", textAlign: TextAlign.center,),
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
                        keyboardType: TextInputType.text,
                        validator: (nome) {
                          if(nome.isEmpty) return "Insere um nome";
                          for(int i = 0 ; i < this.clientes.length ; i++) {
                            if(clientes[i].nome == nome) return "Nome já existente";
                          }
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
                          icon: Icon(Icons.account_box),
                          hintText: "Nome",
                          contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 30.0, 10.0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                        ),
                        onSaved: (value) {
                          nome = value;
                        },
                      ),
                      SizedBox(height: 20,),
                      TextFormField(
                        // email
                        keyboardType: TextInputType.emailAddress,
                        validator: (email) {
                          if(email.isEmpty) return "Insere um email";
                          for(int i = 0 ; i < this.clientes.length ; i++) {
                            if(clientes[i].email == email) return "Email já existente";
                          }
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
                          icon: Icon(Icons.email),
                          hintText: "Email",
                          contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 30.0, 10.0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                        ),
                        onSaved: (value) {
                          email = value;
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
                                _guardarClienteBD(nome, email);
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
  _mostrarAviso(String titulo, String content) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(titulo),
            content: Text(content),
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

  /*
  Aviso que o horario esta cheio para esta hora
   */
  _mostrarAvisoHorarioCheio() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Horário Cheio!"),
            content: Text("O horário que pretende adicionar o funcionário já se encontra cheio."),
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
   /// Mostra a opção de escolher os empregados com determinados horários
  _mostrarTemposDoDia(){
    showDialog(
        context:context,
    builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Horários"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FlatButton(
                child: Text("MANHÃ"),
                onPressed: (){
                  DateTime dataSemHoras = DateTime(_selectedDay.year,_selectedDay.month,_selectedDay.day);
                  List<Empregado> empregadosAux = new List<Empregado>();
                  this.empregados.forEach((empregado){
                    if(empregado.horariosEmUso[dataSemHoras] == null) {
                      empregadosAux.add(empregado);
                    } else {
                      if(!empregado.horariosEmUso[dataSemHoras].contains("manha")){
                        empregadosAux.add(empregado);
                      }
                    }

                  });
                  this.empregadosEscolhidos = empregadosAux;
                  setState(() {
                    tipoDeHorario = "Manha";
                  });
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text("TARDE"),
                onPressed: (){
                  DateTime dataSemHoras = DateTime(_selectedDay.year,_selectedDay.month,_selectedDay.day);
                  List<Empregado> empregadosAux = new List<Empregado>();
                  this.empregados.forEach((empregado){
                    if(empregado.horariosEmUso[dataSemHoras] == null) {
                      //print("${empregado.nome} - ${empregado.horariosEmUso}");
                      empregadosAux.add(empregado);
                    } else {
                      if(!empregado.horariosEmUso[dataSemHoras].contains("tarde")){
                        //print("${empregado.nome} - ${empregado.horariosEmUso}");
                        empregadosAux.add(empregado);
                      } else {
                        //print("${empregado.nome} não entrou");
                        //print(empregado.horariosEmUso);
                      }
                    }
                  });
                  this.empregadosEscolhidos = empregadosAux;
                  setState(() {
                    tipoDeHorario = "Tarde";
                  });
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text("NOITE"),
                onPressed: (){
                  DateTime dataSemHoras = DateTime(_selectedDay.year,_selectedDay.month,_selectedDay.day);
                  List<Empregado> empregadosAux = new List<Empregado>();
                  this.empregados.forEach((empregado){
                    if(empregado.horariosEmUso[dataSemHoras] == null) {
                      empregadosAux.add(empregado);
                    } else {
                      if(!empregado.horariosEmUso[dataSemHoras].contains("noite")){
                        empregadosAux.add(empregado);
                      }
                    }
                  });
                  this.empregadosEscolhidos = empregadosAux;
                  setState(() {
                    tipoDeHorario = "Noite";
                  });
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text("TODOS"),
                onPressed: (){
                  this.empregadosEscolhidos = this.empregados;
                  setState(() {
                    tipoDeHorario = "Todos";
                  });
                  Navigator.pop(context);
                },
              ),
              ],
            ),
            actions: <Widget>[
              FlatButton(
                child: Text("Sair"),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          );
    });
  }

  /// elemina um funcionario do horario antigo
  _eleminarFuncionarioHorario(Empregado empregado, String entradaAntiga, Evento evento) async{
    print("A eleminar ${empregado.nome} da entrada $entradaAntiga no evento ${evento.cliente.nome}");
    // elminar do firebase
    //print("Tamanho da lista de horarios ${evento.horarioFuncionarios[entradaAntiga]}");
    //print(evento.horarioFuncionarios[entradaAntiga]);
    int indiceEvento = this.eventosDia.indexOf(evento);
    int indiceFuncionario = evento.horarioFuncionarios[entradaAntiga].length -1;
    try {
      await FirebaseDatabase.instance.reference().child('eventos').child(
          getData()).child('$indiceEvento').child('horario').child(entradaAntiga)
          .child('funcionarios')
          .update({
        indiceFuncionario.toString() : null
      });
      return;
    } on Exception {
      print("escexao");
    }

  }

  // adicionar um horario ao funcionario
  void _adicionarHorarioFuncionario(Empregado escolhido, String tipo, DateTime dia) {
    DateTime dataSemHora = DateTime(dia.year,dia.month,dia.day);
    if(escolhido.horariosEmUso[dataSemHora] == null){
      // cria lista
      escolhido.horariosEmUso[dataSemHora] = new List<String>();
    }
    escolhido.horariosEmUso[dataSemHora].add(tipo);
  }

  // elemina horario a um funcionario
  void _eleminarHorarioFuncionario(Empregado escolhido, String tipo , Evento evento) {
    String tipoAux = evento.horarios[tipo];
    escolhido.horariosEmUso[DateTime(_selectedDay.year,_selectedDay.month,_selectedDay.day)].remove(tipoAux);
  }



}
