// import 'package:flutter/material.dart';

// class TextFields extends StatefulWidget {
//   TextEditingController controller = TextEditingController();
//   //TextEditingController controller = TextEditingController();
//   final String hintText;
//   final Color? hintColor;
//   TextFields({super.key,required this.hintText,this.hintColor,required this.controller});

//   @override
//   State<TextFields> createState() => _TextFieldsState();
// }

// class _TextFieldsState extends State<TextFields> {
//   @override
//   Widget build(BuildContext context) {
//     return  TextField(
//       controller:widget.controller ,
//       decoration: InputDecoration(
//         hintStyle: TextStyle(color:widget.hintColor),
//         hintText:widget.hintText,
//         border: const OutlineInputBorder(
//           borderSide: BorderSide(color: Colors.grey),
//           borderRadius: BorderRadius.all(Radius.circular(32)),
//         ),
//         enabledBorder: const OutlineInputBorder(
//           borderSide:BorderSide(color: Colors.grey),
//           borderRadius:BorderRadius.all(Radius.circular(32))
//         ),
//         focusedBorder: const OutlineInputBorder(
//           borderSide: BorderSide(color: Colors.grey),
//           borderRadius: BorderRadius.all(Radius.circular(32))
//         )
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class TextFields extends StatefulWidget {
  TextEditingController controller = TextEditingController();
  final String hintText;
  final Color? hintColor;
  
  TextFields({
    super.key,
    required this.hintText,
    this.hintColor,
    required this.controller,
  });

  @override
  State<TextFields> createState() => _TextFieldsState();
}

class _TextFieldsState extends State<TextFields> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        hintStyle: TextStyle(
          color: widget.hintColor ?? Colors.grey.shade600,
          fontSize: 16,
        ),
        hintText: widget.hintText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.5,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 2,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}