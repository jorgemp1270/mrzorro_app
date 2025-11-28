import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import '../utils/colors.dart';

class ContactsScreen extends StatefulWidget {
  final String userId;

  const ContactsScreen({super.key, required this.userId});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<dynamic> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getContacts(widget.userId);
      if (result['success']) {
        setState(() {
          _contacts = result['contacts'] ?? [];
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al cargar contactos'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddContactModal() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final themeService = ThemeService();
    final currentTheme = themeService.currentTheme;
    final currentFont = themeService.currentFont;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: currentTheme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agregar Contacto',
                  style: (currentFont.style ?? const TextStyle()).copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: currentTheme.textColor,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: (currentFont.style ?? const TextStyle())
                        .copyWith(color: currentTheme.textColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: currentTheme.backgroundColor,
                  ),
                  style: (currentFont.style ?? const TextStyle()).copyWith(
                    color: currentTheme.textColor,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    labelStyle: (currentFont.style ?? const TextStyle())
                        .copyWith(color: currentTheme.textColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: currentTheme.backgroundColor,
                    counterStyle: (currentFont.style ?? const TextStyle())
                        .copyWith(color: currentTheme.textColor),
                  ),
                  style: (currentFont.style ?? const TextStyle()).copyWith(
                    color: currentTheme.textColor,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty ||
                          phoneController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Por favor completa todos los campos',
                            ),
                          ),
                        );
                        return;
                      }

                      if (phoneController.text.length != 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('El teléfono debe tener 10 dígitos'),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);
                      await _addContact(
                        nameController.text,
                        phoneController.text,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Guardar',
                      style: (currentFont.style ?? const TextStyle()).copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _addContact(String name, String phone) async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.addContact(
        userId: widget.userId,
        name: name,
        phone: phone,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Operación completada')),
        );
        if (result['success']) {
          _loadContacts();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> contact) {
    final themeService = ThemeService();
    final currentTheme = themeService.currentTheme;
    final currentFont = themeService.currentFont;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: currentTheme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¿Eliminar contacto?',
                  style: (currentFont.style ?? const TextStyle()).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: currentTheme.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '¿Estás seguro de que deseas eliminar a ${contact['name']}?',
                  style: (currentFont.style ?? const TextStyle()).copyWith(
                    color: currentTheme.textColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancelar',
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(color: currentTheme.textColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _deleteContact(contact);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Eliminar',
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _deleteContact(Map<String, dynamic> contact) async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.deleteContact(
        userId: widget.userId,
        name: contact['name'],
        phone: contact['phone'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Operación completada')),
        );
        if (result['success']) {
          _loadContacts();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        final currentTheme = themeService.currentTheme;
        final currentFont = themeService.currentFont;

        return Scaffold(
          backgroundColor: currentTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: currentTheme.cardColor,
            title: Text(
              'Mis Contactos',
              style: (currentFont.style ?? const TextStyle()).copyWith(
                color: currentTheme.textColor,
              ),
            ),
            iconTheme: IconThemeData(color: currentTheme.textColor),
            elevation: 0,
          ),
          body:
              _isLoading
                  ? Center(
                    child: CircularProgressIndicator(
                      color: currentTheme.primaryColor,
                    ),
                  )
                  : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Card(
                          color: Colors.blue.withOpacity(0.1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    'Los contactos que guardes aquí serán notificados automáticamente vía SMS con tu ubicación cuando se detecte que estás en una situación de riesgo alto.',
                                    style: (currentFont.style ??
                                            const TextStyle())
                                        .copyWith(
                                          color: currentTheme.textColor,
                                          fontSize: 13,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            _contacts.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.contact_phone_outlined,
                                        size: 80,
                                        color: currentTheme.textColor
                                            .withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 15),
                                      Text(
                                        'No tienes contactos guardados',
                                        style: (currentFont.style ??
                                                const TextStyle())
                                            .copyWith(
                                              color: currentTheme.textColor
                                                  .withOpacity(0.5),
                                              fontSize: 16,
                                            ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                  ),
                                  itemCount: _contacts.length,
                                  itemBuilder: (context, index) {
                                    final contact = _contacts[index];
                                    return Card(
                                      color: currentTheme.cardColor,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: currentTheme
                                              .primaryColor
                                              .withOpacity(0.2),
                                          child: Text(
                                            contact['name']
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: (currentFont.style ??
                                                    const TextStyle())
                                                .copyWith(
                                                  color:
                                                      currentTheme.primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        title: Text(
                                          contact['name'],
                                          style: (currentFont.style ??
                                                  const TextStyle())
                                              .copyWith(
                                                color: currentTheme.textColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        subtitle: Text(
                                          contact['phone'],
                                          style: (currentFont.style ??
                                                  const TextStyle())
                                              .copyWith(
                                                color: currentTheme.textColor
                                                    .withOpacity(0.7),
                                              ),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed:
                                              () => _showDeleteConfirmation(
                                                contact,
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddContactModal,
            backgroundColor: currentTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}
