import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(ReceiverApp());
}

class ReceiverApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Order Receiver',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: OrderReceiverPage(),
    );
  }
}

class OrderReceiverPage extends StatefulWidget {
  @override
  _OrderReceiverPageState createState() => _OrderReceiverPageState();
}

class _OrderReceiverPageState extends State<OrderReceiverPage> {
  String _status = 'Waiting for orders...';
  List<Map<String, dynamic>> _orderItems = [];
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  void _startServer() async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, 4040);
    print('Server is listening on port 4040');

    await for (final socket in server) {
      socket.listen(
        (data) {
          final message = String.fromCharCodes(data);
          print('Received: $message');

          try {
            // Parse the JSON message
            final orderDetails = jsonDecode(message) as Map<String, dynamic>;

            // Update the UI with the received order details
            setState(() {
              _orderItems = List.from(orderDetails['items']);
              _totalAmount = orderDetails['totalAmount'];
              _status = 'Order received!';
            });
          } catch (e) {
            setState(() {
              _status = 'Error parsing order: $e';
            });
          }
        },
        onDone: () => print('Client disconnected'),
        onError: (error) => print('Error: $error'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Receiver'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _status,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            if (_orderItems.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _orderItems.length,
                  itemBuilder: (context, index) {
                    final item = _orderItems[index];
                    final price = (item['Price'] as num? ?? 0).toDouble();
                    final quantity = item['quantity'] as int? ?? 0;
                    final totalPrice = price * quantity;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['ProductName'] ?? 'Unnamed Item',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            if (item['selectedVariant'] != null)
                              Text(
                                item['variantDetails']?['CombiName'] ?? 'No Size Selected',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            if (item['modifiers'] != null && item['modifiers'].isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  Text(
                                    'Modifiers:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  ...item['modifiers'].map<Widget>((modifier) {
                                    return Text(
                                      '- ${modifier['Name']} (₱${modifier['Price']})',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            if (item['notes'] != null && item['notes'].isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  Text(
                                    'Notes: ${item['notes']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Quantity: $quantity',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '₱${totalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_orderItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Total Amount: ₱${_totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
