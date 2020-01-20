import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mycalendar/models/cliente.dart';
import 'package:mycalendar/models/empregado.dart';
import 'package:mycalendar/models/evento.dart';

import 'package:flutter_masked_text/flutter_masked_text.dart';




class VerEvento extends StatefulWidget {
  Evento evento ;
  List<Empregado> empregados;
  List<Evento> eventosDia;
  List<Evento> eventos;
  List<Cliente> clientes;

  VerEvento(this.evento,this.empregados,this.eventosDia,this.eventos,this.clientes);

  @override
  _VerEventoState createState() => _VerEventoState(this.evento,this.empregados,this.eventosDia,this.eventos,this.clientes);
}

class _VerEventoState extends State<VerEvento> {
  DateTime _selectedDay = DateTime.now();
  List<Empregado> empregados = List<Empregado>(); // Lista de empregados atualizados ou nao da base de dados
  List<Evento> eventos = List<Evento>();
  List<Cliente> clientes = List<Cliente>();
  List<Evento> eventosDia = List<Evento>(); // Lista de eventos do dia escolhido em _selectedDay
  int funcionariosTrabalhar = 0;  // numero de funcionarios a trabalhar no dia _selectedDay
  bool precisoTudo = false;
  int posicaoAntiga;
  int posicaoAntesDaAntiga;
  Evento evento;
  _VerEventoState(this.evento,this.empregados,this.eventosDia,this.eventos,this.clientes){

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
            )));
      });
    else listita.add(Text(""));
    return listita;
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
  Procura um cliente pelo nome na lista clientes e devolve
  o cliente , se nao encontrar devolve null
  */
  Cliente _buscarClientePorNome(String nome){
    for( int i = 0 ; i < this.clientes.length ; i++)
      if(this.clientes[i].nome == nome) return this.clientes[i];
    return null;
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
                totalEmpregados++;
                listaAux.add(_procurarEmp(nomeEmpregado));
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
    ScrollController scrollController = new ScrollController();

    evento.horarios.forEach((evento, resto ){
      print("$evento - $resto");
    });

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



    return new Scaffold(
        resizeToAvoidBottomPadding: false,
        bottomNavigationBar: Container(
          color: Colors.grey[800],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.group,
                color: Colors.grey,
              ),
              Text(evento.totalEmpregados.toString(), style: TextStyle(color: Colors.white),),
              IconButton(
                icon: Icon(
                  Icons.alarm_add,
                  color: Colors.white,
                ),
                onPressed: () {
                  _mostrarAddHorario(evento);
                },
              ),
              DragTarget(
                builder: (context , List<String> CandidateData, rejectedData){
                  return Icon(Icons.delete_forever,color: Colors.white70,);
                },
                onAccept: (funcionario){
                  //apaga o empregado da lista
                  if(funcionario.contains("UPDATE")){
                    // quando o funcionario arrastado foi um update
                    // retiramos o update do nome e o id do evento
                    // ex: 0001UPDATE15:30Joao Carlos
                    int idEventoEmpregado = int.parse(funcionario.substring(0,4));
                    String entrada = funcionario.substring(10,15);
                    funcionario = funcionario.substring(15);
                    print("A eleminar $funcionario do id_evento $idEventoEmpregado da entrada $entrada");
                    Empregado escolhido = _procurarEmp(funcionario);
                    _eleminarFuncionarioHorarioBD(escolhido, entrada, evento);
                    _eleminarEmpregadoHorario(escolhido,entrada);
                  }
                },
              )
            ],
          ),
        ),
        appBar: new AppBar(
          title: Row(
            children: <Widget>[
              Text(title + " ${evento.cliente.nome}"),
              SizedBox(
                width: 10,
              ),

            ],
          ),
          backgroundColor: Colors.grey[300],
        ),
        body: Row(
          children: <Widget>[
            Container(
                width: 150,
                color: Colors.grey[200],
                child:ListView(
                  children:  _buscarEmpregadosWidget(),
                )
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  evento.horarios.isNotEmpty ? DragTarget(
                    builder: (context , List<String> CandidateData, rejectedData){
                      return Container(
                        padding: EdgeInsets.only(left: 100,right: 100),
                        color: Colors.grey[400],
                        child: Icon(Icons.keyboard_arrow_up,size: 15,),

                      );
                    },
                    onWillAccept: (value){
                      double posicao = scrollController.offset;
                      scrollController.animateTo(posicao - 30.0, curve: Curves.easeOut,
                          duration: const Duration(milliseconds: 300));
                      return true;
                    },

                  ) : Text(""),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: evento.horarios == null || evento.horarios.length == 0? Center(child: Text("Sem horarios adicionados"),) : Column(
                        //shrinkWrap: true,
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
                              //print("posicao atual maior que a antiga");
                              posicao += 30.0;
                            } else if(posicaoAtual < posicaoAntiga){
                              //print("posicao atual menor que a antiga");
                              posicao -= 30.0;
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
                              if(evento.horarioFuncionarios[entrada.key] == null){
                                // Se nao exister uma lista de funcionarios para este horario de entrada
                                // Vamos criar
                                List<Empregado> aux = new List<Empregado>();
                                aux.add(escolhido);
                                evento.horarioFuncionarios[entrada.key] = aux;
                                evento.empregados.add(escolhido);
                                evento.totalEmpregados++;
                                if(update) {
                                  //eleminar da lista na bd
                                  _eleminarFuncionarioHorarioBD(escolhido,entradaAntiga,evento);
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
                                  evento.totalEmpregados++;
                                  if(update) {
                                    //eleminar da lista na bd
                                    _eleminarFuncionarioHorarioBD(escolhido,entradaAntiga,evento);
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
                            } else {
                              // aviso que ja tem o max funcionarios
                              if(!evento.horarioFuncionarios[entrada.key].contains(escolhido))
                                _mostrarAvisoHorarioCheio();
                            }
                          },
                        )).toList(),
                      ),
                    ),
                  ),evento.horarios.isNotEmpty ?  DragTarget(
                    builder: (context , List<String> CandidateData, rejectedData){
                      return Container(
                        padding: EdgeInsets.only(left: 100,right: 100),
                        color: Colors.grey[400],
                        child: Icon(Icons.keyboard_arrow_down,size: 15,),

                      );
                    },
                    onWillAccept: (value){
                      double posicao = scrollController.offset;
                      print("OLHA O FILHO");
                      scrollController.animateTo(posicao + 30.0, curve: Curves.easeOut,
                          duration: const Duration(milliseconds: 300));
                      return true;
                    },

                  ) : Text(""),
                ],
              ),
            )
          ],
        ));
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

  /// elemina um funcionario do horario antigo na BD
  _eleminarFuncionarioHorarioBD(Empregado empregado, String entradaAntiga, Evento evento) async{
    int indiceEvento = this.eventosDia.indexOf(evento);

    try {
        FirebaseDatabase.instance.reference().child('eventos').child(
          getData()).child('$indiceEvento').child('horario').child(entradaAntiga)
          .child('funcionarios')
          .once().then((info) {
         List hey = info.value;
         print(hey);
          FirebaseDatabase.instance.reference().child('eventos').child(
             getData()).child('$indiceEvento').child('horario').child(entradaAntiga)
             .child('funcionarios')
             .child('${hey.indexOf(empregado.nome)}').remove();
         //print(hey);
         return;
       });
    } on Exception {
      print("escexao");
    }

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
                                  evento.horarios[entrada] = saida;
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

  /// eleminar na lista em memoria um empregado para uma dada entrada
  _eleminarEmpregadoHorario(Empregado escolhido, String entrada){
    this.evento.horarioFuncionarios[entrada].remove(escolhido);
    setState(() {
        this.evento.totalEmpregados--;
    });
  }
}
