class Empregado {
  String nome;
  String disponibilidade; // DISP_TOTAL , DISP_REDUZIDA , OCASIONAL
  int telemovel;
  Map<DateTime,List<String>> horariosEmUso = new Map<DateTime,List<String>>();

  Empregado(this.nome,this.disponibilidade,this.telemovel);


 @override
  String toString() => "Empregado: nome ${this.nome} , telemovel ${this.telemovel} , disponibilidade ${this.disponibilidade}";



  // TODO falta pensar na disponibilidade
}