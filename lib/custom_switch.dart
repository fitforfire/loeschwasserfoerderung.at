import 'package:flutter/material.dart';

//Root Widget for Custom Animated Switch
class CustomAnimatedSwitch extends StatefulWidget {
  //Variables
  final bool value;
  final ValueChanged<bool> onChanged;

  //Constructor
  const CustomAnimatedSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  //Create State
  @override
  CustomAnimatedSwitchState createState() => CustomAnimatedSwitchState();
}

//State for Switch-Widget
class CustomAnimatedSwitchState extends State<CustomAnimatedSwitch> {
  //Build the Page
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //Handle Switch Tap Event
      onTap: () {
        widget.onChanged(!widget.value);
      },
      //Animated Container for transitions
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: widget.value ? Colors.green : Colors.black,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: widget.value ? Colors.green : Colors.black,
          ),
        ),
        height: 40.0,
        width: 100.0,
        alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
        //Animated Alignment for the Switch "Circle"
        child: AnimatedAlign(
          alignment:
              widget.value ? Alignment.centerRight : Alignment.centerLeft,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          //Switch "Circle" with Text
          child: Container(
            width: 90.0,
            height: 30.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.value ? "Sichtbar" : "Versteckt",
              style: const TextStyle(color: Colors.black, fontSize: 16.0),
            ),
          ),
        ),
      ),
    );
  }
}
