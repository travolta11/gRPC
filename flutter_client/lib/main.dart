import 'package:clientgrpc/GrpcClient.dart';
import 'package:flutter/material.dart';
import 'generated/compte.pb.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter gRPC Demo',
      home: ComptesPage(),
    );
  }
}

class ComptesPage extends StatefulWidget {
  final grpcClient = GrpcClient();
  ComptesPage({super.key});

  @override
  State<ComptesPage> createState() => _ComptePaState();
}

class _ComptePaState extends State<ComptesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Liste des comptes"),
      ),
      body: FutureBuilder(
          future: widget.grpcClient.fetchAllComptes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No comptes found.'));
            } else {
              final comptes = snapshot.data;
              return ListView.builder(
                itemCount: comptes!.length,
                itemBuilder: (context, index) {
                  final compte = comptes[index];
                  return ListTile(
                      title: Text('Type: ${compte.type}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Solde: ${compte.solde}'),
                          Text('Additional Info: ${compte.dateCreation}'),
                        ],
                      ),
                      trailing: IconButton(onPressed:  () => setState(() {
                        widget.grpcClient.deleteCompte(compte.id);
                      }), icon: Icon(Icons.delete, color: Colors.red)),
                      );
                },
              );
            }
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addCompteDialog(widget.grpcClient);
        },
        tooltip: 'Ajouter un compte',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addCompteDialog(GrpcClient grpcClient) {
    return showDialog(context: context, builder: (context) {
      String type = 'COURANT';
      String dateCreation = '';
      double solde = 0.0;
      return AlertDialog(
        title: Text('Ajouter un compte'),
        content:Column(
          children: [
              DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Type'),
              value: type,
              items: [
                DropdownMenuItem(value: 'COURANT', child: Text('COURANT')),
                DropdownMenuItem(value: 'EPARGNE', child: Text('EPARGNE')),
              ],
              onChanged: (value) {
                type = value!;
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Solde'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                solde = double.tryParse(value) ?? 0.0;
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Date de Création'),
              onChanged: (value) {
              dateCreation = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close dialog
            child: Text('Annuler'),
          ),
          TextButton(onPressed: ()async{
              if(type == null || dateCreation.isEmpty || solde <= 0){
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Veuillez remplir tous les champs correctement!')),
                );
                return;
              }
              try{
                final newCompte = await grpcClient.saveCompte(
                  type,
                  solde,
                  dateCreation,
                );
                setState(() {
                  grpcClient.fetchAllComptes();
                });
                Navigator.of(context).pop();
              }catch(e){
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
              
          },
           child: Text('Ajouter'))
        ],
      );
    });
  }
}
