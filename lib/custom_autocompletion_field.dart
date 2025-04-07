import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

//Root Widget for Custom Autocompletion Widget
class CustomAutocompletionField extends StatefulWidget {
  //Variables
  final TextEditingController controller;
  final List<String> suggestions;
  final String label;
  final String noItemFound;
  final bool selectAll;
  final Function(String)? onChanged;
  final Function()? onFinishedInput;

  //Constructor
  const CustomAutocompletionField(
      {super.key,
      required this.controller,
      required this.suggestions,
      required this.label,
      required this.noItemFound,
      required this.selectAll,
      this.onChanged,
      this.onFinishedInput});

  //Create State
  @override
  CustomAutocompletionFieldState createState() =>
      CustomAutocompletionFieldState();
}

//State for Custom Autocompletion Widget
class CustomAutocompletionFieldState extends State<CustomAutocompletionField> {
  int selectedIndex = -1;
  List<String> filteredSuggestions = [];
  FocusNode focusNode = FocusNode();

  //Initializer
  @override
  void initState() {
    super.initState();
    widget.suggestions
        .sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    filteredSuggestions = widget.suggestions;

    focusNode.addListener(() {
      if (widget.selectAll && focusNode.hasFocus) {
        if (widget.controller.text.isNotEmpty) {
          widget.controller.selection = TextSelection(
              baseOffset: 0, extentOffset: widget.controller.text.length);
        }
      }

      if (!focusNode.hasFocus) {
        if (widget.suggestions.contains(widget.controller.text)) {
          widget.onFinishedInput?.call();
        }
      }
    });
  }

  //Disposer
  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  //Handle Arrow Key Presses
  void handleArrowKeys(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          selectedIndex = (selectedIndex + 1) % filteredSuggestions.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          selectedIndex = (selectedIndex - 1 + filteredSuggestions.length) %
              filteredSuggestions.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (selectedIndex != -1) {
          widget.controller.text = filteredSuggestions[selectedIndex];
        } else if (filteredSuggestions.length == 1) {
          widget.controller.text = filteredSuggestions[0];
        }
        selectedIndex = -1;
        FocusScope.of(context).unfocus();
        widget.onChanged?.call(widget.controller.text);
      }
    }
  }

  //Build the Widget
  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: focusNode,
      onKey: (event) => handleArrowKeys(event),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: TypeAheadField<String>(
          controller: widget.controller,
          suggestionsCallback: (pattern) {
            filteredSuggestions = widget.suggestions
                .where((suggestion) =>
                    suggestion.toLowerCase().contains(pattern.toLowerCase()))
                .toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
            return filteredSuggestions;
          },
          itemBuilder: (context, suggestion) {
            int index = filteredSuggestions.indexOf(suggestion);
            return ListTile(
              title: Text(suggestion),
              tileColor: selectedIndex == index ? Colors.blue.shade100 : null,
            );
          },
          emptyBuilder: (context) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.noItemFound,
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            );
          },
          onSelected: (suggestion) {
            widget.controller.text = suggestion;
            setState(() {
              selectedIndex = -1;
            });
            widget.onChanged?.call(suggestion);
            widget.onFinishedInput?.call();
          },
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.label,
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onTap: () {
                if (widget.selectAll) {
                  controller.selection = TextSelection(
                      baseOffset: 0, extentOffset: controller.text.length);
                }
              },
              onChanged: (value) {
                widget.onChanged?.call(value);
                setState(() {
                  filteredSuggestions = widget.suggestions
                      .where((suggestion) => suggestion
                          .toLowerCase()
                          .contains(value.toLowerCase()))
                      .toList()
                    ..sort(
                        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
                });

                if (value.isEmpty) {
                  focusNode.requestFocus();
                }
              },
              onSubmitted: (value) {
                if (selectedIndex != -1 && filteredSuggestions.isNotEmpty) {
                  widget.controller.text = filteredSuggestions[selectedIndex];
                } else if (filteredSuggestions.length == 1) {
                  widget.controller.text = filteredSuggestions[0];
                }
                FocusScope.of(context).unfocus();
                widget.onChanged?.call(widget.controller.text);
              },
            );
          },
        ),
      ),
    );
  }
}
