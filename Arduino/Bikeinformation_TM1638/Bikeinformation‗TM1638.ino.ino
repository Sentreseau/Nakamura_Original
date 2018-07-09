
#include <TM1638.h>
#include <TinyGPS++.h>
#include <SoftwareSerial.h>

// TM1638設定定義
// D2にDIO
// D3にCLK
// D4にSTB
TM1638 module(2, 3, 4);

// GPS側設定
// D10にTXD
// D11にRXD
TinyGPSPlus gps;
SoftwareSerial mySerial(10, 11);

// 各種変数定義
String TM;
int tmz;
double LAT, LONG, ALT, SPD, SAT;

// 初期設定
void setup() {
    //Debug用 Serial情報取得宣言
    Serial.begin(57600);
    Serial.println("Goodnight moon!");

    // GPSモジュールとの通信は9600bpsで設定する
    mySerial.begin(9600);
    mySerial.println("Hello, world?");
}

//実処理（繰り返し処理）
void loop() {
    while (mySerial.available() > 0) {
        char c = mySerial.read();
        gps.encode(c);
        if (gps.location.isUpdated()) {
            //時刻 HH-MM-SS形式
            tmz = (gps.time.hour());
            tmz = tmz + 9;  //日本標準時に合わせるため＋９時間加算
            TM = String(tmz);
            TM += String("-");
            TM += String(gps.time.minute());
            TM += String("-");
            TM += String(gps.time.second());
            //緯度 小数点第4位まで
            LAT = (gps.location.lat(), 4);
            //経度 小数点第4位まで
            LONG = (gps.location.lng(), 4);
            //標高 単位：メートル
            ALT = (gps.altitude.meters());
            //速度 単位：km/h
            SPD = (gps.speed.kmph());
            //衛星の数
            SAT = (gps.satellites.value());
            //Debug Stream
            //日付 DDMMYY形式　それぞれ出す場合はyear month day で出すといい
            Serial.print("DATE=");Serial.println(gps.date.value());
            //時刻 HHMMSSCC形式　それぞれ出す場合はhour minute second centisecond と指定する
            Serial.print("TIME=");Serial.println(gps.time.value());
            //緯度　最終引数で小数点何位まで表示する
            Serial.print("LAT=");Serial.print(gps.location.rawLat().negative ? "W" : "E");Serial.println(gps.location.lat(), 3);
            //経度　最終引数で小数点何位まで表示する
            Serial.print("LONG=");Serial.print(gps.location.rawLng().negative ? "S" : "N");Serial.println(gps.location.lng(), 3);
            //標高 ほかにも miles kilometers feetがある valueだとセンチメートル
            Serial.print("ALT=");Serial.println(gps.altitude.meters());
            //速度　ほかにもknot mph mpsがある
            Serial.print("SPD=");Serial.println(gps.speed.kmph());
            //衛星の数
            Serial.print("SAT=");Serial.println(gps.satellites.value());
        }
    }
    byte keys = module.getButtons(); 
    if (keys == 0b00000001) {
        module.setLEDs(1);
        module.setDisplayToString(TM);
    }
    if (keys == 0b00000010) {      
        module.setLEDs(2); 
        module.setDisplayDigit(LAT, 0, true);
    }
    if (keys == 0b00000100) {
        module.setLEDs(4); 
        module.setDisplayDigit(LONG, 0, true);
    }
    if (keys == 0b00001000) {
        module.setLEDs(8); 
        module.setDisplayDigit(ALT, 0, true);
    }
    if (keys == 0b00010000) {
        module.setLEDs(16); 
        module.setDisplayDigit(SPD, 0, true);
    }
    if (keys == 0b00100000) {
        module.setLEDs(32); 
        module.setDisplayDigit(SAT, 0, true);
    }
}


