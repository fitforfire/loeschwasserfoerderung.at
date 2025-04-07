import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loeschwasserfoerderung/crypto.dart';
import 'add_user_dialog.dart';
import 'reply_message_dialog.dart';
import 'support_email.dart';
import 'support_user.dart';
import 'error_dialog.dart';

// Root Widget for LoadingScreen-Page
class DashboardPage extends StatefulWidget {
  //Constructor
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  //User Variables
  final List<TextEditingController> usernameControllers = [];
  final List<TextEditingController> passwordControllers = [];
  final List<FocusNode> usernameFocusNodes = [];
  final List<FocusNode> passwordFocusNodes = [];
  List<User> users = [];
  Timer? periodicReload;
  double reloadTurn = 0.0;

  //EMail Variables
  List<SupportEmail> emails = [];

  //Initializer
  @override
  void initState() {
    super.initState();
    loadAllUsers();
    loadAllEMails();
    periodicReload =
        Timer.periodic(const Duration(minutes: 5), (Timer t) async {
      loadAllUsers();
      loadAllEMails();
    });
  }

  //Disposer
  @override
  void dispose() {
    for (var controller in usernameControllers) {
      controller.dispose();
    }
    for (var controller in passwordControllers) {
      controller.dispose();
    }
    for (var focusNode in usernameFocusNodes) {
      focusNode.dispose();
    }
    for (var focusNode in passwordFocusNodes) {
      focusNode.dispose();
    }
    periodicReload?.cancel();
    super.dispose();
  }

  //Build the Widget
  @override
  Widget build(BuildContext context) {
    ScrollController globalScrollController = ScrollController();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        title: const Text("Support Dashboard"),
        actions: [
          //Reload
          AnimatedRotation(
            turns: reloadTurn,
            duration: const Duration(seconds: 1),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                reloadTurn += 1.0;
                loadAllUsers();
                loadAllEMails();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AddUserDialog(onUserAdded: (User newUser) async {
                      await createUser(newUser);
                    });
                  });
            },
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is OverscrollNotification) {
            globalScrollController.jumpTo(
              globalScrollController.offset + scrollNotification.overscroll,
            );
          }
          return false;
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Benutzer",
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 24,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    ScrollController itemController = ScrollController();
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification &&
                            itemController.position.pixels ==
                                itemController.position.maxScrollExtent) {
                          globalScrollController.animateTo(
                            globalScrollController.position.pixels + 50,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                        return false;
                      },
                      child: GestureDetector(
                        onTap: () => toggleExpand(user, null),
                        child: Card(
                          color: Colors.grey[800],
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.newUsername ?? user.username,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      user.expanded
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: user.expanded
                                    ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller:
                                        usernameControllers[index],
                                        focusNode: usernameFocusNodes[index],
                                        decoration: InputDecoration(
                                          labelText: "Benutzername",
                                          labelStyle: const TextStyle(
                                              color: Colors.white),
                                          enabledBorder:
                                          const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.white),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.blue[300]!),
                                          ),
                                        ),
                                        style: const TextStyle(
                                            color: Colors.white),
                                        onSubmitted: (value) {
                                          if (user.newUsername !=
                                              usernameControllers[index]
                                                  .text) {
                                            setState(() {
                                              user.newUsername =
                                                  usernameControllers[index]
                                                      .text;
                                            });
                                          }
                                          FocusScope.of(context).requestFocus(
                                              passwordFocusNodes[index]);
                                          Future.delayed(
                                              Duration(milliseconds: 50), () {
                                            passwordControllers[index]
                                                .selection = TextSelection(
                                              baseOffset: 0,
                                              extentOffset:
                                              passwordControllers[index]
                                                  .text
                                                  .length,
                                            );
                                          });
                                        },
                                        onEditingComplete: () {
                                          if (user.newUsername !=
                                              usernameControllers[index]
                                                  .text) {
                                            setState(() {
                                              user.newUsername =
                                                  usernameControllers[index]
                                                      .text;
                                            });
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller:
                                        passwordControllers[index],
                                        focusNode: passwordFocusNodes[index],
                                        decoration: InputDecoration(
                                          labelText: "Passwort",
                                          labelStyle: const TextStyle(
                                              color: Colors.white),
                                          enabledBorder:
                                          const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.white),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.blue[300]!),
                                          ),
                                        ),
                                        style: const TextStyle(
                                            color: Colors.white),
                                        obscureText: true,
                                        onTap: () {
                                          passwordControllers[index]
                                              .selection = TextSelection(
                                            baseOffset: 0,
                                            extentOffset:
                                            passwordControllers[index]
                                                .text
                                                .length,
                                          );
                                        },
                                        onSubmitted: (value) {
                                          String encryptedNewPassword =
                                          user.encryptPassword(value);
                                          if (user.newPassword !=
                                              encryptedNewPassword) {
                                            setState(() {
                                              encryptedNewPassword =
                                                  user.newPassword =
                                                  encryptedNewPassword;
                                            });
                                          }
                                          FocusScope.of(context).unfocus();
                                        },
                                        onEditingComplete: () {
                                          String encryptedNewPassword =
                                          user.encryptPassword(
                                              passwordControllers[index]
                                                  .text);
                                          if (user.newPassword !=
                                              encryptedNewPassword) {
                                            setState(() {
                                              encryptedNewPassword =
                                                  user.newPassword =
                                                  encryptedNewPassword;
                                            });
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Checkbox(
                                            value: user.isAdmin,
                                            onChanged: (bool? newValue) {
                                              setState(() {
                                                user.isAdmin =
                                                    newValue ?? false;
                                              });
                                            },
                                            side: BorderSide(
                                              color: Colors.white,
                                              width: 1.0,
                                            ),
                                            checkColor: Colors.black,
                                          ),
                                          const Text("Admin-Rechte",
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Column(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              if (await user
                                                  .deleteUser(context)) {
                                                setState(() {
                                                  users.removeAt(index);
                                                });
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                Colors.blueGrey[400]),
                                            child: const Text("Löschen",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                          const SizedBox(height: 10),
                                          ElevatedButton(
                                            onPressed: () {
                                              user.generateNewPassword(
                                                  context);
                                            },
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                Colors.blueGrey[400]),
                                            child: const Text(
                                                "Passwort generieren",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                          const SizedBox(height: 10),
                                          ElevatedButton(
                                            onPressed: () async {
                                              await user.updateUser(context);
                                            },
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                Colors.blueGrey[400]),
                                            child: const Text("Speichern",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      )
                    );
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "Supportnachrichten",
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 24,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                  itemCount: emails.length,
                  itemBuilder: (context, index) {
                    final email = emails[index];
                    ScrollController emailController = ScrollController();
                    return NotificationListener<ScrollNotification> (
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification &&
                            emailController.position.pixels ==
                                emailController.position.maxScrollExtent) {
                          globalScrollController.animateTo(
                            globalScrollController.position.pixels + 50,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                        return false;
                      },
                      child: GestureDetector(
                        onTap: () => toggleExpand(null, email),
                        child: Card(
                          color: Colors.grey[800],
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            email.subject,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      email.expanded
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: email.expanded
                                    ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Text(
                                          email.date,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Text(
                                          email.message,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return ReplyMessageDialog(
                                                      email: email,
                                                      possibleSupportAgents: users
                                                        .where((user) => user.isAdmin)
                                                        .map((user) => user.username)
                                                        .toList()
                                                    );
                                                  });
                                            },
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                Colors.blueGrey[400]),
                                            child: const Text("Antworten",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                          const SizedBox(width: 10),
                                          ElevatedButton(
                                            onPressed: () async {
                                              if (await email
                                                  .deleteEmail(context)) {
                                                setState(() {
                                                  emails.removeAt(index);
                                                });
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                Colors.blueGrey[400]),
                                            child: const Text("Löschen",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

  // Get All The Users from the API (Database)
  Future<void> loadAllUsers() async {
    final url = "https://xn--lschwasserfrderung-d3bk.at/api/getAllUsers.php";
    try {
      final response = await http.post(Uri.parse(url));
      final data = json.decode(await Crypto.decrypt(response.body) ?? "");
      if (response.statusCode == 200) {
        if (data.isNotEmpty && data["users"] != null) {
          users.clear();
          for (var userJson in data["users"]) {
            setState(() {
              User user = User.fromJson(userJson);
              users.add(user);
              usernameControllers
                  .add(TextEditingController(text: user.username));
              passwordControllers
                  .add(TextEditingController(text: user.password));
              usernameFocusNodes.add(FocusNode());
              passwordFocusNodes.add(FocusNode());
            });
          }
        }
      } else {
        ErrorDialog.show(context, data["error"]);
      }
    } catch (ex) {
      ErrorDialog.show(context, ex.toString());
    }
  }

  // Get All The EMails from the API (Webmail)
  Future<void> loadAllEMails() async {
    final url = "https://xn--lschwasserfrderung-d3bk.at/api/getAllEMails.php";
    try {
      final response = await http.post(Uri.parse(url));
      final data = json.decode(await Crypto.decrypt(response.body) ?? "");

      if (response.statusCode == 200) {
        if (data.isNotEmpty && data["emails"] != null) {
          emails.clear();
          for (var emailJson in data["emails"]) {
            setState(() {
              SupportEmail supportEmail = SupportEmail.fromJson(emailJson);
              emails.add(supportEmail);
            });
          }
        }
      } else {
        ErrorDialog.show(context, data["error"]);
      }
    } catch (ex) {
      ErrorDialog.show(context, ex.toString());
    }
  }

  // Toggle the Expanding
  void toggleExpand(User? selectedUser, SupportEmail? selectedSupportEmail) {
    setState(() {
      if (selectedUser != null) {
        for (User user in users) {
          if (user != selectedUser) {
            user.expanded = false;
          }
        }
        selectedUser.expanded = !selectedUser.expanded;
      } else if (selectedSupportEmail != null) {
        for (SupportEmail supportEmail in emails) {
          if (supportEmail != selectedSupportEmail) {
            supportEmail.expanded = false;
          }
        }
        selectedSupportEmail.expanded = !selectedSupportEmail.expanded;
      }
    });
  }

  // Create User via API
  Future<void> createUser(User newUser) async {
    final url = "https://xn--lschwasserfrderung-d3bk.at/api/addUser.php";
    try {
      final response = await http.post(
        Uri.parse(url),
        body: await Crypto.encrypt(json.encode({
          'username': newUser.username,
          'password': newUser.password,
          'isAdmin': newUser.isAdmin.toString()
        })),
      );

      final data = json.decode(await Crypto.decrypt(response.body) ?? "");
      if (response.statusCode == 200) {
        setState(() {
          users.add(newUser);
          usernameControllers
              .add(TextEditingController(text: newUser.username));
          passwordControllers
              .add(TextEditingController(text: newUser.password));
          usernameFocusNodes.add(FocusNode());
          passwordFocusNodes.add(FocusNode());
        });
      } else {
        ErrorDialog.show(context, data["error"]);
      }
    } catch (ex) {
      ErrorDialog.show(context, ex.toString());
    }
  }
}
