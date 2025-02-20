// import 'package:flutter/material.dart';
// // import '../utils/formatters.dart';

// class CallLogsScreen extends StatefulWidget {
//   @override
//   _CallLogsScreenState createState() => _CallLogsScreenState();
// }

// class _CallLogsScreenState extends State<CallLogsScreen> {
//   List<CallLogEntry> _callLogs = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _getCallLogs();
//   }

//   Future<void> _getCallLogs() async {
//     setState(() => isLoading = true);
//     try {
//       Iterable<CallLogEntry> entries = await CallLog.get();
//       setState(() {
//         _callLogs = entries.toList();
//         isLoading = false;
//       });
//     } catch (e) {
//       print("Error fetching call logs: $e");
//       setState(() => isLoading = false);
//     }
//   }

//   Icon _getCallTypeIcon(CallType? callType) {
//     switch (callType) {
//       case CallType.outgoing:
//         return Icon(Icons.call_made, color: Colors.green);
//       case CallType.incoming:
//         return Icon(Icons.call_received, color: Colors.blue);
//       case CallType.missed:
//         return Icon(Icons.call_missed, color: Colors.red);
//       default:
//         return Icon(Icons.call);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Call Logs'),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               itemCount: _callLogs.length,
//               itemBuilder: (context, index) {
//                 CallLogEntry log = _callLogs[index];
//                 return Card(
//                   margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   child: ListTile(
//                     leading: _getCallTypeIcon(log.callType),
//                     title: Text(log.name ?? log.number ?? 'Unknown'),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(log.number ?? 'No number'),
//                         // Text('Duration: ${Formatters.formatDuration(log.duration ?? 0)}'),
//                         // Text('Date: ${Formatters.formatDate(
//                         //   DateTime.fromMillisecondsSinceEpoch(log.timestamp ?? 0)
//                         // )}'),
//                       ],
//                     ),
//                     isThreeLine: true,
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }