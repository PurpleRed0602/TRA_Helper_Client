import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

import '/config/user.dart';
import '/config/ticket.dart';
import '/widgets/components.dart';
import '/widgets/loading_block.dart';

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({Key? key}) : super(key: key);

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  bool isLoading = true; // true時顯示載入畫面，false時根據ticket變數決定
  Ticket? ticket; // 若為空顯示無車票畫面，不為空顯示車票qrcode等資訊

  @override
  void initState() {
    super.initState();
    checkTicket(Provider.of<User>(context, listen: false));
  }

  @override
  Widget build(BuildContext context) {
    final double vw = MediaQuery.of(context).size.width;
    final double vh = MediaQuery.of(context).size.height;

    if (isLoading) {
      return const LoadingBlock();
    } else {
      if (ticket == null) {
        return noTicketUI();
      } else {
        return hasTicketUI(vw, vh, ticket!);
      }
    }
  }

  /* INFO: 無車票畫面 */
  Widget noTicketUI() {
    return const Center(
      child: Text('目前沒有車票', style: TextStyle(fontSize: 24)),
    );
  }

  /* INFO: 有車票畫面 */
  Widget hasTicketUI(double vw, double vh, Ticket? ticket) {
    String formateStartTime1 = "";
    String formateStartTime2 = "";
    String formateEndTime1 = "";
    String formateEndTime2 = "";
    if (ticket != null) {
      DateTime startTime = DateTime.parse(ticket.startTime);
      DateTime endTime = DateTime.parse(ticket.endTime);
      formateStartTime1 = DateFormat('yyyy-MM-dd').format(startTime);
      formateStartTime2 = DateFormat('kk:mm').format(startTime);
      formateEndTime1 = DateFormat('yyyy-MM-dd').format(endTime);
      formateEndTime2 = DateFormat('kk:mm').format(endTime);
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: vw * 0.8,
            height: vw * 0.8,
            padding: const EdgeInsets.all(20.0),
            color: Colors.white,
            child: QrImage(
              data: ticket!.urlQR,
              version: QrVersions.auto,
              size: vw * 0.7,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(ticket.startStation, style: const TextStyle(height: 1.5, fontSize: 20)),
                    Text(formateStartTime1, style: const TextStyle(height: 1.5, fontSize: 20)),
                    Text(formateStartTime2, style: const TextStyle(height: 1.5, fontSize: 20)),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.arrow_right,
                      color: Colors.white70,
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(ticket.endStation, style: const TextStyle(height: 1.5, fontSize: 20)),
                    Text(formateEndTime1, style: const TextStyle(height: 1.5, fontSize: 20)),
                    Text(formateEndTime2, style: const TextStyle(height: 1.5, fontSize: 20)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* INFO: 獲取車票資料函式 */
  Future<void> checkTicket(User user) async {
    Response response;

    try {
      response = await Dio().get(
        'https://tra-helper-backend.herokuapp.com/accounts/${user.id}/tickets/',
        options: Options(headers: {'Authorization': 'Token ${user.key}'}),
      );
    } on DioError {
      Components.dialog(context, '無法連線', 'App無法連線至伺服器，請檢查您的網路連線');
      setState(() {
        isLoading = false; // 只要有變數改變就要用setstate包起來，UI就會更新了
      });
      return;
    }

    String url = response.data[0]['url'];
    String id = response.data[0]['id'].toString();
    String users = response.data[0]['user'].toString();
    String date = response.data[0]['date'];
    String startStation = response.data[0]['start_station'].toString();
    String endStation = response.data[0]['end_station'].toString();
    String startTime = response.data[0]['start_time'].toString();
    String endTime = response.data[0]['end_time'].toString();
    String train = response.data[0]['train'].toString();
    String seat = response.data[0]['seat'];
    String urlQR = response.data[0]['QR_url'];
    try {
      response = await Dio().get(
        'https://tra-helper-backend.herokuapp.com/stations/$startStation/',
      );
    } on DioError {
      Components.dialog(context, '無法連線', 'App無法連線至伺服器，請檢查您的網路連線');
      setState(() {
        isLoading = false;
      });
      return;
    }
    startStation = response.data['station_name'];
    try {
      response = await Dio().get(
        'https://tra-helper-backend.herokuapp.com/stations/$endStation/',
      );
    } on DioError {
      Components.dialog(context, '無法連線', 'App無法連線至伺服器，請檢查您的網路連線');
      setState(() {
        isLoading = false;
      });
      return;
    }
    endStation = response.data['station_name'];
    // 建立ticket物件
    setState(() {
      if (url == null) {
        return;
      } else {
        ticket = Ticket(
          url: url,
          id: id,
          user: users,
          date: date,
          startStation: startStation,
          endStation: endStation,
          startTime: startTime,
          endTime: endTime,
          train: train,
          seat: seat,
          urlQR: urlQR,
        );
        isLoading = false;
      }
    });
  }
}
