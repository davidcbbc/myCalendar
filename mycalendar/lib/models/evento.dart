import 'package:mycalendar/models/cliente.dart';
import 'package:mycalendar/models/empregado.dart';


//  o horário mínimo de cada funcionário para cada local é de 5 horas
// (mas colocaremos 6h a contar com o tempo de viagem de um 
// local ao outro), o que faz que a partir do momento que ele 
// é colocado num evento a uma determinada hora, não aparecerá
// disponível para outros horários/eventos nas próximas 6 horas.

class Evento {
  Cliente cliente;
  DateTime data;
  String local;
  String tipo;  // Ou 'HOTEL' ou 'EVENTO' . Sendo hotel, ao inserir o pedido (dos empregados, horarios, etc) já não me pede farda nem local; Sendo evento, ao inserir o pedido já vai pedir farda e morada
  String farda; // camisa preta , camisa branca e laco , camisa branca com colete e laco , camisa branca com colete e laco.
  int totalEmpregados = 0;
  List<Empregado> empregados;
  Map<String,int> horarioEntradaComFuncionariosTotais;  // Mapa que tem os horarios de entrada e o numero total de funcionarios para esse horario
  Map<String,String> horarios; //Mapa que sabe o horario de saida sabendo o horario de entrada
  Map<String,List<Empregado>> horarioFuncionarios = new Map<String,List<Empregado>>();// Mapa que tem os empregados naquele horario de entrada


  


  Evento(this.cliente, {this.local,this.tipo,this.farda,this.horarioEntradaComFuncionariosTotais,this.data , this.empregados,this.horarioFuncionarios,this.horarios}){
    this.empregados = new List<Empregado>();
  }

  @override
  String toString() => "Evento: nome_cliente ${this.cliente.nome} , farda $farda , local $local data ${data.toString()}";


}