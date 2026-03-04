import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  final String username;

  // Update contructor agar wajib memasukkan contructor
  const CounterView({super.key, required this.username});
  @override
  State<CounterView> createState() => _CounterViewState();
}

Color getHistoryColor(HistoryType type) {
  switch (type) {
    case HistoryType.increment:
      return Colors.green;
    case HistoryType.decrement:
      return Colors.red;
    case HistoryType.reset:
      return Colors.orange;
  }
}

String formatHistoryText(HistoryItem item) {
  final jam = item.time.hour.toString().padLeft(2, '0');
  final menit = item.time.minute.toString().padLeft(2, '0');

  switch (item.type) {
    case HistoryType.increment:
      return '${item.username} Menambahkan nilai sebesar ${item.value} pada jam $jam:$menit';
    case HistoryType.decrement:
      return '${item.username} Mengurangi nilai sebesar ${item.value} pada $jam:$menit';
    case HistoryType.reset:
      return '${item.username} Reset nilai pada jam $jam:$menit';
  }
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  final TextEditingController inputController = TextEditingController();
  final List<String> history = [];

  Future<void> _loadData() async {
    await _controller.loadCounter();
    await _controller.loadHistory();

    final lastInput = await _controller.loadLastInput();
    inputController.text = lastInput;

    setState(() {});
  }

  String getGreetings() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Selamat Pagi";
    } else if (hour >= 12 && hour < 15) {
      return "Selamat Siang";
    } else if (hour >= 15 && hour < 18) {
      return "Selamat Sore";
    } else {
      return "Selamat Malam";
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final displayedHistory = _controller.history.reversed.take(5).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text("${getGreetings()}, ${widget.username}"),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Konfirmasi logout'),
                    content: const Text(
                      'Yakin ingin keluar? Data yang disimpan mungkin akan hilang',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginView(),
                            ),
                            (routes) => false,
                          );
                        },
                        child: const Text(
                          'Ya, keluar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: inputController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _controller.saveLastInput(value);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Masukkan angka',
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text('Total Hitungan'),
            Text('${_controller.value}', style: const TextStyle(fontSize: 40)),
            const Text('Riwayat Step', style: TextStyle(fontSize: 24)),

            Expanded(
              child: ListView.builder(
                itemCount: displayedHistory.length,
                itemBuilder: (context, index) {
                  final item = displayedHistory[index];
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(
                      formatHistoryText(item),
                      style: TextStyle(color: getHistoryColor(item.type)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              final int step = int.tryParse(inputController.text) ?? 0;
              setState(() {
                _controller.incrementBy(widget.username, step);
              });
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            onPressed: () {
              final int step = int.tryParse(inputController.text) ?? 0;
              setState(() {
                _controller.decrementBy(widget.username, step);
              });
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.remove),
          ),
          FloatingActionButton(
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Konfirmasi'),
                    content: const Text(
                      'Apakah kamu yakin ingin reset hitungan?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text('Tidak'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text('Ya'),
                      ),
                    ],
                  );
                },
              );
              if (result == true) {
                setState(() {
                  _controller.reset(widget.username);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Counter Berhasil di-reset'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            backgroundColor: Colors.yellow,
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
