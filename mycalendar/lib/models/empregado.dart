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

 @override
  String toString() => "Empregado: nome ${this.nome} , telemovel ${this.telemovel} , disponibilidade ${this.disponibilidade}";



  // TODO falta pensar na disponibilidade
}