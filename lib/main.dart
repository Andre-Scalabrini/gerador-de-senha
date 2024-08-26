import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:math';

void main() {
  runApp(PasswordManagerApp());
}

class PasswordManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Password Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PasswordManagerScreen(),
    );
  }
}

class PasswordManagerScreen extends StatefulWidget {
  @override
  _PasswordManagerScreenState createState() => _PasswordManagerScreenState();
}

class _PasswordManagerScreenState extends State<PasswordManagerScreen> {
  String _password = '';
  int _length = 12;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  final List<Map<String, String>> _savedPasswords = [];
  final TextEditingController _siteController = TextEditingController();
  String _searchQuery = '';
  final LocalAuthentication auth = LocalAuthentication();

  void _generatePassword() {
    const String uppercaseLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowercaseLetters = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String symbols = '!@#\$%^&*(),.<>?;:[]{}-=_+';

    String chars = '';
    if (_includeUppercase) chars += uppercaseLetters;
    if (_includeLowercase) chars += lowercaseLetters;
    if (_includeNumbers) chars += numbers;
    if (_includeSymbols) chars += symbols;

    if (chars.isEmpty) {
      setState(() {
        _password = 'Selecione pelo menos uma opção!';
      });
      return;
    }

    Random random = Random.secure();
    String password = List.generate(_length, (index) {
      return chars[random.nextInt(chars.length)];
    }).join();

    setState(() {
      _password = password;
    });
  }

  void _savePassword() {
    String site = _siteController.text.trim();
    if (site.isEmpty || _password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Informe o site/aplicativo e gere uma senha primeiro!'),
      ));
      return;
    }

    setState(() {
      _savedPasswords.add({'site': site, 'password': _password});
      _siteController.clear();
      _password = '';
    });
  }

  Future<void> _authenticateAndShowPassword(int index) async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Autentique-se para visualizar a senha',
        options: const AuthenticationOptions(
          biometricOnly: false, // Permite PIN ou biometria
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Senha para ${_savedPasswords[index]['site']}'),
              content: SelectableText(_savedPasswords[index]['password']!),
              actions: <Widget>[
                TextButton(
                  child: Text('Fechar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao autenticar: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Gerenciador de Senhas'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Gerar Senha'),
              Tab(text: 'Senhas Salvas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Aba de Gerar Senha
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: _siteController,
                    decoration: InputDecoration(labelText: 'Site/Aplicativo'),
                  ),
                  SizedBox(height: 20),
                  Text('Comprimento da Senha: $_length'),
                  Slider(
                    value: _length.toDouble(),
                    min: 6,
                    max: 20,
                    divisions: 14,
                    label: _length.toString(),
                    onChanged: (double value) {
                      setState(() {
                        _length = value.toInt();
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text('Incluir Letras Maiúsculas'),
                    value: _includeUppercase,
                    onChanged: (bool? value) {
                      setState(() {
                        _includeUppercase = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text('Incluir Letras Minúsculas'),
                    value: _includeLowercase,
                    onChanged: (bool? value) {
                      setState(() {
                        _includeLowercase = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text('Incluir Números'),
                    value: _includeNumbers,
                    onChanged: (bool? value) {
                      setState(() {
                        _includeNumbers = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text('Incluir Símbolos'),
                    value: _includeSymbols,
                    onChanged: (bool? value) {
                      setState(() {
                        _includeSymbols = value ?? false;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _generatePassword,
                      child: Text('Gerar Senha'),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: SelectableText(
                      _password,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _savePassword,
                      child: Text('Salvar Senha'),
                    ),
                  ),
                ],
              ),
            ),
            // Aba de Senhas Salvas
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar por Aplicativo',
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _savedPasswords.length,
                    itemBuilder: (context, index) {
                      final passwordEntry = _savedPasswords[index];
                      if (_searchQuery.isNotEmpty &&
                          !passwordEntry['site']!
                              .toLowerCase()
                              .contains(_searchQuery)) {
                        return SizedBox.shrink();
                      }
                      return ListTile(
                        title: Text(passwordEntry['site']!),
                        trailing: IconButton(
                          icon: Icon(Icons.visibility),
                          onPressed: () => _authenticateAndShowPassword(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
