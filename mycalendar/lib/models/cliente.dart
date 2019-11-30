class Cliente {
  String nome;
  String email;
  String tipo; // HOTEL ou EVENTO

  Cliente(this.nome,this.email,{this.tipo});


  @override
  String toString() => "Cliente: nome ${this.nome} , email ${this.email}";

}