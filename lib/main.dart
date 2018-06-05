import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:async/async.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> dataList = [];
  StreamController streamController;

  @override
  void initState() {
    streamController = StreamController.broadcast();
    setupData();
    super.initState();
  }

  setupData() async {
    Stream stream = await getData()
      ..asBroadcastStream();
    stream.listen((data) {
      setState(() {
        dataList.add(data[0]);
        dataList.add(data[1]);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    streamController?.close();
    streamController = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Multi-Item List'),
      ),
      body: ListView.builder(
        itemCount: dataList.length,
        itemBuilder: (context, index) {
          final item = dataList[index];

          if (item is Photo) {
            return ListTile(
              title: Text(item.title),
              subtitle: Image.network(
                item.url,
                scale: 0.5,
              ),
            );
          }
          if (item is Post) {
            return ListTile(
              title: Text("Title:  ${item.title}"),
              subtitle: Text("Body:  ${item.body}"),
              leading: Text(index.toString()),
            );
          }
        },
      ),
    );
  }
}

class Photo {
  final String url;
  final String title;

  Photo({this.url, this.title});

  Photo.fromJson(Map json)
      : url = json["url"],
        title = json["title"];
}

class Post {
  final String title;
  final String body;

  Post({this.title, this.body});

  Post.fromJson(Map json)
      : title = json['title'],
        body = json['body'];
}

Future<Stream> getData() async {
  final client = http.Client();

  Stream streamOne = await getPhotos(client);
  Stream streamTwo = await getPosts(client);

  return StreamZip([streamOne, streamTwo]).asBroadcastStream();
}

Future<Stream> getPhotos(http.Client client) async {
  final url = "https://jsonplaceholder.typicode.com/photos";
  final req = http.Request('get', Uri.parse(url));

  http.StreamedResponse streamedRes = await client.send(req);

  return streamedRes.stream
      .transform(utf8.decoder)
      .transform(json.decoder)
      .expand((e) => e)
      .map((map) => Photo.fromJson(map));
}

Future<Stream> getPosts(http.Client client) async {
  final url = "https://jsonplaceholder.typicode.com/posts";
  final req = http.Request('get', Uri.parse(url));

  http.StreamedResponse streamedRes = await client.send(req);

  return streamedRes.stream
      .transform(utf8.decoder)
      .transform(json.decoder)
      .expand((e) => e)
      .map((map) => Post.fromJson(map));
}
