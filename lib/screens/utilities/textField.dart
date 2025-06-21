import 'package:flutter/material.dart';

class TextFields extends StatefulWidget {
  TextEditingController controller = TextEditingController();
  //TextEditingController controller = TextEditingController();
  final String hintText;
  final Color? hintColor;
  TextFields({super.key,required this.hintText,this.hintColor,required this.controller});

  @override
  State<TextFields> createState() => _TextFieldsState();
}

class _TextFieldsState extends State<TextFields> {
  @override
  Widget build(BuildContext context) {
    return  TextField(
      controller:widget.controller ,
      decoration: InputDecoration(
        hintStyle: TextStyle(color:widget.hintColor),
        hintText:widget.hintText,
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.all(Radius.circular(32)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide:BorderSide(color: Colors.grey),
          borderRadius:BorderRadius.all(Radius.circular(32))
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.all(Radius.circular(32))
        )
      ),
    );
  }
}