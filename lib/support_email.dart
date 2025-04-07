import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:loeschwasserfoerderung/crypto.dart';
import 'package:loeschwasserfoerderung/success_dialog.dart';
import 'error_dialog.dart';

class SupportEmail {
  final String subject;
  final String replyToEmail;
  final String message;
  final int id;
  final String date;
  String responseMessage;
  String supportAgentName;
  bool expanded;

  SupportEmail(
      {required this.subject,
      required this.replyToEmail,
      required this.message,
      required this.id,
      required this.date,
      required this.responseMessage,
      required this.supportAgentName,
      required this.expanded});

  // Factory method to create a Email from JSON
  factory SupportEmail.fromJson(Map<String, dynamic> json) {
    return SupportEmail(
      subject: json['subject'],
      replyToEmail: json['replyTo'],
      message: json['message'],
      id: json['id'],
      date: json['date'],
      responseMessage: "",
      supportAgentName: "",
      expanded: false,
    );
  }

  //Reply Email to the sender
  void sendEmail(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse(
            "https://xn--lschwasserfrderung-d3bk.at/api/sendReplyEMail.php"),
        body: await Crypto.encrypt(json.encode({
          "subject": subject,
          "message": responseMessage,
          "supportAgentName": supportAgentName,
          "to": replyToEmail
        })),
        headers: {"Content-Type": "application/json; charset=utf-8"},
      );

      final data = json.decode(await Crypto.decrypt(response.body) ?? "");

      if (response.statusCode == 200) {
        SuccessDialog.show(context, data["success"]);
      } else {
        ErrorDialog.show(context, data["error"]);
      }
    } catch (ex) {
      ErrorDialog.show(context, "Fehler: ${ex.toString()}");
    }
  }

  //Delete Email
  Future<bool> deleteEmail(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse("https://xn--lschwasserfrderung-d3bk.at/api/deleteEMail.php"),
        body: await Crypto.encrypt(json.encode({"id": id})),
        headers: {"Content-Type": "application/json; charset=utf-8"},
      );

      final data = json.decode(await Crypto.decrypt(response.body) ?? "");

      if (response.statusCode == 200) {
        return true;
      } else {
        ErrorDialog.show(context, data["error"]);
        return false;
      }
    } catch (ex) {
      ErrorDialog.show(context, "Fehler: ${ex.toString()}");
      return false;
    }
  }
}
