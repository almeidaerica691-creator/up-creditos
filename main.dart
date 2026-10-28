import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // INICIALIZAÇÃO COM AS TUAS CHAVES DO FIREBASE
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAN3cW6-nGTwXBYH6jAlXOaQDAl5swZumw",
      authDomain: "upcreditos-41695.firebaseapp.com",
      projectId: "upcreditos-41695",
      storageBucket: "upcreditos-41695.appspot.com",
      messagingSenderId: "595644454769",
      appId: "1:595644454769:web:b6f0a669f989421e4b88d0",
    ),
  );

  runApp(const AppCreditosMaster());
}

class AppCreditosMaster extends StatelessWidget {
  const AppCreditosMaster({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Créditos - Nuvem',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}

// TELA DE LOGIN
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acesso ao Sistema', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.account_balance_wallet, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            const Text(
              'Gestão de Créditos na Nuvem',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ListaClientesCredorScreen()),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('ENTRAR COMO CREDOR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// PAINEL DO CREDOR (LIGADO AO FIRESTORE)
class ListaClientesCredorScreen extends StatelessWidget {
  const ListaClientesCredorScreen({super.key});

  void _adicionarClienteCloud(BuildContext context) {
    final nomeController = TextEditingController();
    final telefoneController = TextEditingController();
    final principalController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cadastrar Novo Cliente (Nuvem)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome do Cliente')),
              TextField(controller: telefoneController, decoration: const InputDecoration(labelText: 'Telefone / WhatsApp')),
              TextField(controller: principalController, decoration: const InputDecoration(labelText: 'Valor Principal do Crédito (R\$)'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () {
                String nome = nomeController.text.trim();
                String tel = telefoneController.text.trim();
                double principal = double.tryParse(principalController.text.replaceAll(',', '.')) ?? 100.0;

                if (nome.isNotEmpty) {
                  FirebaseFirestore.instance.collection('clientes').add({
                    "nome": nome,
                    "telefone": tel.isEmpty ? "5588999999999" : tel,
                    "aprovado": true,
                    "creditos": [
                      {
                        "principal": principal,
                        "data": "Hoje",
                        "diasAtraso": 0,
                        "jurosPct": 10.0,
                        "multaPct": 4.99,
                      }
                    ],
                    "criadoEm": FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Salvar na Nuvem'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes (Base Firebase)', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () => _adicionarClienteCloud(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('clientes').orderBy('criadoEm', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum cliente na nuvem ainda.', style: TextStyle(color: Colors.grey)));
          }

          var documentos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              var dados = documentos[index].data() as Map<String, dynamic>;
              String docId = documentos[index].id;
              List creditos = dados["creditos"] ?? [];
              double totalPrincipal = creditos.fold(0.0, (sum, c) => sum + (c["principal"] as double));

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(dados["nome"] ?? 'Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Total Principal Devido: R\$ ${totalPrincipal.toStringAsFixed(2)}'),
                      Text('Contratos Ativos: ${creditos.length}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      FirebaseFirestore.instance.collection('clientes').doc(docId).delete();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

