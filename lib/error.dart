import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget{
  final String error;

  ErrorScreen({Key ?key , required this.error}): super(key: key);

  @override
  Widget build(context){
    return Center(child: Text(error),);
  }

}