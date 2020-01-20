
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:mycalendar/models/evento.dart';
import 'package:test/test.dart';



void main(){
  test("_getData , dia , mes e ano teem que ter 2 algarismos",(){
    DateTime _selectedDay = DateTime.now();
    String title = _selectedDay.day.toString();
    if(title.length == 1) title = "0" + title;
    expect(title.length, 2);  // dia tem 2 algarismos
    title += "-";
    if(_selectedDay.month.toString().length == 1) title+= "0";
    title += _selectedDay.month.toString();
    expect(title.length, 5);
    title += "-";
    title += _selectedDay.year.toString();
    print(title);
  });

  test("_atualizarEventosDia dar os eventos do dia direitos",() {
    DateTime _selectedDay = DateTime.now();
    List<Evento> eventosDia = List<Evento>();
    List<Evento> eventos = List<Evento>();




    eventosDia.clear();
    eventos.forEach((evento) {

      int diasDeDiferenca = evento.data.difference(_selectedDay).inDays;  //calcula os dias de diferenca
      if(diasDeDiferenca == 0) {
        print(evento.data == _selectedDay);
        print(evento.data.toString());
        eventosDia.add(evento);
      }
    });
  });



}