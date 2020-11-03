import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

List<RetrieveData> dataList = new List.generate(24, (index) => null);

List<RetrieveData> dataListRetrieval(DataSnapshot snapshot, List<RetrieveData> dataList, DateTime currentTime){
  var data = snapshot.value;
  dataList.clear();
  String date = DateFormat('yyyy-MM-dd').format(currentTime);
  
  RetrieveData collectData = new RetrieveData(
    int.parse(data['ID']),
    data['MoistureState'],
    int.parse(data['Moisture']),
    data['color'],
    date
  );
  dataList.add(collectData);
  
  dataList.sort((RetrieveData a, RetrieveData b){
    return a.id.compareTo(b.id);
  });
  //print(dataList);
  return dataList;
}

class RetrieveData{
  int id;
  String moistState;
  int moistVal;
  String colorVal;
  String date;
  RetrieveData(this.id, this.moistState, this.moistVal,this.colorVal, this.date);
}
