import 'dart:io'; // for exit();
import 'dart:async';
import 'dart:isolate';

import 'package:sounds_common/sounds_common.dart';

/// Provides a library to stream data to and from an isolate.
/// 
/// [IsolateStream] lets you setup a processing pipe line using an
/// [Isolate] without having to deal with the low level details of
/// setting up an [Isolate].
/// 
/// The three main methods are:
/// 
/// [IsolateSteam.send()] - sends a data packet to the isolate
/// [IsolateStream.process()] - process data in the isolate
/// [IsolateStream.receive()] - recieves processed data back from the isolate.
/// 
/// You will normally set the above methods up in you code in reverse order
/// [recieve]
/// [process]
/// [send]
/// 
/// This is because you need to have you processing pipeline setup before you 
/// start sending data into it.
///
/// Calling [send] before configuring [recieve] and [process] may cause
/// [send] to hang.
/// 
/// When stoppig a stream you will often want to ensure that you have recieved
/// all of the data back from the isolate. To do this call
/// [IsolateStream.stop()]
/// and then use [IsolateStream.onStopped] to be notified when
/// the Isolate has processed last packet has been processed.
/// 
/// [IsolateStream] guaentees that you will [recieve] the last data packet.
/// before [IsolateStream.onStopped] is called.
/// 
///
/// ```dart
///
/// void convert(Track from, Track to)
/// {
///   var isoStream = IsolateStream();
/// 
///  var toPath = to.path;
///   var toFile = File(toPath);
///
///   /// Handle the converted data coming back.
///   isoStream.recieve((converted) {
///     toFile.append(converted);
///   });
///
///
///   // set up the handler to recieve the stream data
///   // process it and return.
///   isoStream.process((data, responseStream) {
///     // this code is called in the isolate.
///     var converted = convert(data, to);
///     /// send the data back using the response stream.
///     responseStream.add(converted);
///
///   });
///
///  
///
///   var pathFrom = from.path;
///   var file = File(pathFrom);
///   for (var data : file.readNextBlock())
///   {
///     isoStream.send(data);
///   }
/// }
/// ```

// Example of bi-directional communication between a main thread and isolate.

/// [S] is the type of data we send to the isolate.
/// Standard [Stream] rules apply for the type of objects we can send to 
/// an isolate. If you want to send a complex object then you need
/// to do something like jsonise the data.
/// [R] is the type of data we recieve back from the isolate.
/// Standard [Stream] rules apply to to the type of objects the
/// isolate can return.
class IsolateStream<S, R> {

  Stream isolate;

  /// The isolate we spawn.
  Isolate _isolate;

  SendPort sendToIsolatePort;

  ReceivePort receiveFromIsolatePort = ReceivePort();

  /// Completes once the isolate is set up
  /// and we have its sendPort.
  Completer initialised = Completer<bool>();

  ///
  IsolateStream() {
    initIsolate();
  }

  ///
  void initIsolate() async {
    /// listen to data coming back from the isolate.
    receiveFromIsolatePort.listen((data) {
      if (data is SendPort) {
        /// we recieved the isolates sendport so we can communicate with
        /// it now.
        sendToIsolatePort = data;
        initialised.complete(sendToIsolatePort);
      } else {
        print('[receivePort] $data');
      }
    });

    _isolate =
        await Isolate.spawn(isolateEntryPoint, receiveFromIsolatePort.sendPort);
  }

  /// Isolates entry point.
  static void isolateEntryPoint(SendPort sendToMainPort) {
    var recieveFromMainPort = ReceivePort();

    /// Immediately Send our send port to the main thread so
    /// it can send us data.
    sendToMainPort.send(recieveFromMainPort.sendPort);

    /// Process messages from the main isolate.
    recieveFromMainPort.listen((data) {
      print('[sendPort] $data');
      exit(0);
    });

    /// Send some data to the main isolate.
    sendToMainPort.send('This is from myIsolate()');
  }

  /// recieves data from the isolate.
  Stream<R> get isolateReciever async*
  {

  }

}

  void main() async {

    var fromTrack = Track.fromFile('/path/to/test/file', mediaFormat: Mp3MediaFormat());

  }
  
  void convert(Track from, Track to)
 {
   var isoStream = IsolateStream();

   // set up the handler to recieve the stream data
   // process it and return.
   isoStream.isolateReciever.listen((data, responseStream) {
     // this code is called in the isolate.
     var converted = convert(data, to);
      //send the data back using the response stream.
     responseStream.add(converted);

   });

   var toPath = to.path;
   var toFile = File(toPath);

    //Handle the converted data coming back.
   isoStream.listen((converted) {
     toFile.append(converted);
   });


   var pathFrom = from.path;
   var file = File(pathFrom);
   for (var data : file.readNextBlock())
   {
     isoStream.add(data);
   }
 }
   
   
class Mp3MediaFormat extends MediaFormat
{
  @override
  String get extension => 'mp3';

  @override
  Future<Duration> getDuration(String path) {
    throw UnimplementedError();
  }

  @override
  Future<bool> get isNativeDecoder => Future.value(false);

  @override
  Future<bool> get isNativeEncoder => Future.value(false);
  
}

