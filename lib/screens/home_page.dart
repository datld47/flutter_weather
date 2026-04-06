import 'package:flutter/material.dart';
import 'package:weather/components/reusable_card.dart';
import 'package:weather/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int count = 0;
  String strPosition = '...';
  int _secondsElapsed = 0;
  //Timer? _timer;
  bool _isLoading = false;

  late UpTimer tim1;

  void tim1Handler(UpTimer tim)
  {
    setStateSafe(() {
      _secondsElapsed=tim.getSecond();
    });
  }

  Future<Position> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ định vị đang tắt. Vui lòng bật GPS.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Bạn đã từ chối quyền truy cập vị trí.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyền vị trí bị khóa vĩnh viễn');
    }

    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.low,
      distanceFilter: 100,
      timeLimit: Duration(seconds: 120),
    );

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    } on TimeoutException {
      throw Exception("quá thời gian");
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  Future<void> handleGetLocation() async {
    // 1. Khóa nút và chuẩn bị trạng thái
    setState(() {
      _isLoading = true;
      strPosition = "Đang tìm tín hiệu vệ tinh...";
    });

    //_startTimer();
    tim1.startTimer();
    setStateSafe((){
      _secondsElapsed=tim1.getSecond();
    });

    try {
      // 2. Gọi hàm logic và chờ kết quả
      Position position = await getLocation();

      // 3. Cập nhật kết quả thành công
      setStateSafe(() {
        strPosition =
            "Thành công trong $_secondsElapsed giây!\n"
            "Vĩ độ: ${position.latitude}\n"
            "Kinh độ: ${position.longitude}";
      });
    } catch (e) {
      // 4. Hứng mọi lỗi (throw) từ hàm getLocation
      setStateSafe(() {
        strPosition = "Thất bại ($_secondsElapsed s):\n$e";
      });
    } finally {
      //_stopTimer();
      tim1.stopTimer();
      setStateSafe(() {
        _isLoading = false;
      });
    }
  }

  Future<void> getData()async
  {
    String apiKey= 'b5f3ea96b782f2520e492ae584654089';
    String lat='12.6682405';
    String long='108.0406043';
    String url="https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$long&appid=$apiKey";
    try{
      http.Response response=await http.get(Uri.parse(url));
      if (response.statusCode==200)
        {
          String data=response.body;
          var longtitude=jsonDecode(data)['coord']['lon'];
          var weatherDescription=jsonDecode(data)['weather'][0]['description'];
          print(longtitude);
          print(weatherDescription);
        }
      else
        {
          print(response.statusCode);
        }
    }
    catch(e)
    {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tim1=UpTimer(timerElapse:tim1Handler);
  }

  @override
  void dispose() {
    // Gọi hàm dừng timer mà bạn đã viết trong class UpTimer
    tim1.stopTimer();
    // Rất quan trọng: Luôn gọi super.dispose() ở cuối cùng
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Weather')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: ReusableCard(
              colour: kActiveCardColour,
              cardChild: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      strPosition,
                      style: kLabelTextStyle,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  IndicateButton(
                      label: 'Get location',
                      isLoading: _isLoading,
                      onPress: handleGetLocation,
                      secondsElapsed:_secondsElapsed
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ReusableCard(
              colour: kActiveCardColour,
              cardChild: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                      onPressed: ()async{
                        await getData();
                      },
                      child: Text('get weather')
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UpTimer{
  int _secondsElapsed = 0;
  Timer? _timer;
  UpTimer({this.timerElapse});
  final void Function(UpTimer)? timerElapse;
  void startTimer() {
    _secondsElapsed = 0; // Reset về 0
    _timer?.cancel(); // Hủy timer cũ nếu có

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _secondsElapsed++;
        timerElapse?.call(this);
    });
  }
  void stopTimer() {
    _timer?.cancel();
    _secondsElapsed=0;
  }
  int getSecond()
  {
    return _secondsElapsed;
  }
}

class IndicateButton extends StatelessWidget {
  IndicateButton({required this.label, required this.isLoading,required this.onPress, required this.secondsElapsed });
  final bool isLoading;
  final VoidCallback onPress;
  final int secondsElapsed;
  final String label;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPress,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      child: isLoading ? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 15),
          Text("wait ($secondsElapsed s)..."),
        ],
      ) : Text(label),);
  }
}

extension SafeSetState on State {
  void setStateSafe(VoidCallback fn) {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(fn);
    }
  }
}