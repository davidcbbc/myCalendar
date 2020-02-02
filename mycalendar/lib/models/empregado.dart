import 'package:mycalendar/models/evento.dart';

class Empregado {
  String nome;
  String disponibilidade; // DISP_TOTAL , DISP_REDUZIDA , OCASIONAL
  int telemovel;
  Map<DateTime,List<String>> horariosEmUso = new Map<DateTime,List<String>>();

  Empregado(this.nome,this.disponibilidade,this.telemovel);

/// checka se um um funcionaro pode trabalhar naquela data dentro do horario passados
  bool podeTrabalhar(DateTime data , String horario){
    if(this.horariosEmUso[data] ==null) return true;
    if(this.horariosEmUso[data].contains(horario)) return false;
    return true;
  }
  /// funcao que retorna se o empregado esta a trabalhar durante essas horas
  /// para ele trabalhar nessa hora tem que ter 6 horas + hora de entrada
  bool jaTrabalha(String horario , DateTime data, List<Evento> eventos){
    int hora = int.parse(horario.substring(0,2));
    int minuto = int.parse(horario.substring(3,5));
    List<String> entradasDoFuncionario = List<String>();
    eventos.forEach((evento){
      evento.horarioFuncionarios.forEach((entrada, funcionarios){
        if(funcionarios.contains(this)) entradasDoFuncionario.add(entrada);
      });
    });
    if(entradasDoFuncionario.length == 0) return false;
    for(int i = 0 ; i < entradasDoFuncionario.length; i++){
      int hora2 = int.parse(entradasDoFuncionario[i].substring(0,2));
      int minuto2 = int.parse(entradasDoFuncionario[i].substring(3,5));
      DateTime datinha2 = DateTime(2000,10,10,hora2,minuto2);
      DateTime datinha = DateTime(2000,10,10,hora,minuto);
      if(datinha.difference(datinha2).inHours < 6 && datinha.difference(datinha2).inHours > -6) return true;
    }
    return false;
  }

 @override
  String toString() => "Empregado: nome ${this.nome} , telemovel ${this.telemovel} , disponibilidade ${this.disponibilidade}";



  // TODO falta pensar na disponibilidade
}