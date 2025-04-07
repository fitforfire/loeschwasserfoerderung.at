import 'package:flutter/material.dart';
import 'package:loeschwasserfoerderung/custom_autocompletion_field.dart';
import 'support_email.dart';
import 'error_dialog.dart';

// Root Widget for ReplyMessageDialog
class ReplyMessageDialog extends StatelessWidget {
  // Variables
  final SupportEmail email;
  final List<String> possibleSupportAgents;

  // Constructor
  const ReplyMessageDialog({
    super.key,
    required this.email,
    required this.possibleSupportAgents
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController messageController = TextEditingController();
    TextEditingController agentController = TextEditingController();

    return AlertDialog(
      title: const Text("Antwort auf die Supportanfrage"),
      contentPadding: const EdgeInsets.all(16.0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Autocomplete field for the support agent's name
            CustomAutocompletionField(
              controller: agentController,
              suggestions: possibleSupportAgents,
              label: 'Supportmitarbeiter',
              noItemFound: 'Keinen Supportmitarbeiter gefunden!',
              selectAll: true,
            ),
            const SizedBox(height: 10),
            // Multi-line text field for the message
            TextField(
              controller: messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Nachricht eingeben",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actionsPadding:
      const EdgeInsets.only(bottom: 20.0, left: 16.0, right: 16.0),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  email.responseMessage = messageController.text;
                  email.supportAgentName = agentController.text;

                  if (email.responseMessage.isNotEmpty && email.supportAgentName.isNotEmpty) {
                    email.sendEmail(context);
                    Navigator.of(context).pop();
                  } else {
                    ErrorDialog.show(
                        context, "Bitte sowohl eine Nachricht als auch einen Support-Agenten eingeben");
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: const Text("Senden", overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
