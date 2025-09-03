import 'package:flutter/material.dart';

import '../../../../../models/service_call/service_call_list_model.dart';
import '../../../service_call_detail/service_call_detail_screen.dart';

Widget buildServiceCallCard(
    BuildContext context, ServiceCallListModel item, String maintenanceBy) {
  bool isDone = item.closedDate.isNotEmpty;
  return InkWell(
    onTap: () {
      isDone ? (){} : Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceCallDetailScreen(
            transNo: item.transNo,
            maintenanceBy: maintenanceBy,
          ),
        ),
      );
    },
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      color: const Color(0xFFF7F9FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: isDone
                    ? Colors.green
                    : int.parse(item.ageComplaint) > 3
                        ? Colors.red
                        : Colors.orange,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isDone ? Icons.check_circle : Icons.access_time,
                              color: isDone
                                  ? Colors.green
                                  : int.parse(item.ageComplaint) > 3
                                      ? Colors.red
                                      : Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isDone
                                  ? 'Selesai'
                                  : 'Belum Selesai || ${item.ageComplaint} hari',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDone
                                    ? Colors.green
                                    : int.parse(item.ageComplaint) > 3
                                        ? Colors.red
                                        : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(item.postedDate,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.shipToName} (${item.shipTo})',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(item.branchName, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      item.complaintSubject,
                      style: const TextStyle(fontSize: 16),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
