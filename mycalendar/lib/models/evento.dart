import 'package:mycalendar/models/cliente.dart';


//  o horário mínimo de cada funcionário para cada local é de 5 horas
// (mas colocaremos 6h a contar com o tempo de viagem de um 
// local ao outro), o que faz que a partir do momento que ele 
// é colocado num evento a uma determinada hora, não aparecerá
// disponível para outros horários/eventos nas próximas 6 horas.

class Evento {
  Cliente cliente;
  String local;
  String tipo;  // Ou 'HOTEL' ou 'EVENTO' . Sendo hotel, ao inserir o pedido (dos empregados, horarios, etc) já não me pede farda nem local; Sendo evento, ao inserir o pedido já vai pedir farda e morada
  String farda; // camisa preta , camisa branca e laco , camisa branca com colete e laco , camisa branca com colete e laco.
  Map<String,int> horariosEntrada;  // diferentes horarios de entrada e numero de funcionarios respetivos desse horario


  


  Evento(this.cliente, {this.local,this.tipo,this.farda,this.horariosEntrada});
}