import 'package:flutter/material.dart';
// ...existing code...
import '../services/api_client.dart';

class PlanAheadWidget extends StatefulWidget {
  @override
  _PlanAheadWidgetState createState() => _PlanAheadWidgetState();
}

class _PlanAheadWidgetState extends State<PlanAheadWidget> {
  final TextEditingController latController = TextEditingController();
  final TextEditingController lonController = TextEditingController();
  DateTime? selectedDate;

  String resultMessage = "";
  bool isLoading = false;
  String? errorMessage;

  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 7)), // forecast up to 7 days
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> checkPlan() async {
    if (latController.text.isEmpty ||
        lonController.text.isEmpty ||
        selectedDate == null) {
      setState(() {
        resultMessage = "⚠ Please fill all fields.";
        errorMessage = null;
      });
      return;
    }

    double lat;
    double lon;
    try {
      lat = double.parse(latController.text);
      lon = double.parse(lonController.text);
    } catch (e) {
      setState(() {
        resultMessage = "";
        errorMessage = "⚠ Latitude and Longitude must be valid numbers.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      resultMessage = "";
    });

    try {
      final dateStr = selectedDate!.toIso8601String().split('T')[0];
      final path = '/predict?lat=$lat&lon=$lon&date=$dateStr';

      try {
        final data = await ApiClient.instance.getJson(path);
        if (data == null) {
          throw Exception('Empty response from server');
        }
        final reasoning = data['ai_insight'] != null
            ? data['ai_insight']['reasoning'] ?? "No reasoning available."
            : "No AI insight available.";

        setState(() {
          resultMessage = reasoning;
          errorMessage = null;
        });
      } catch (e) {
        setState(() {
          resultMessage = "";
          errorMessage = e.toString();
        });
      }
    } catch (e) {
      setState(() {
        resultMessage = "";
        errorMessage = "Error: Could not fetch data. Please try again.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("🌤 Plan Ahead",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: latController,
              decoration: InputDecoration(labelText: "Latitude"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: lonController,
              decoration: InputDecoration(labelText: "Longitude"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(selectedDate == null
                      ? "Pick a date"
                      : "Date: ${selectedDate!.toLocal()}".split(' ')[0]),
                ),
                ElevatedButton(
                  onPressed: () => pickDate(context),
                  child: Text("Choose Date"),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : checkPlan,
              child: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text("Check Plan"),
            ),
            SizedBox(height: 20),
            if (errorMessage != null)
              Text(errorMessage!,
                  style: TextStyle(fontSize: 16, color: Colors.red)),
            if (resultMessage.isNotEmpty)
              Text(resultMessage,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
