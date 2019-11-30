class Empregado {
  String nome;
  String disponibilidade; // DISP_TOTAL , DISP_REDUZIDA , OCASIONAL
  int telemovel;

  Empregado(this.nome,this.disponibilidade,this.telemovel);


 @override
  String toString() => "nome ${this.nome} , telemovel ${this.telemovel} , disponibilidade ${this.disponibilidade}";



  // TODO falta pensar na disponibilidade
}